// Supabase Edge Function: notify-task-assigned
//
// Triggered by the Flutter client after a task is created with assignees.
// For each assignee that isn't the creator:
//   1. Inserts an in-app notification row into public.notifications.
//   2. Sends an FCM push notification if the user has a stored device token.
//
// Required Supabase secrets (Dashboard → Edge Functions → Secrets):
//   FIREBASE_SERVICE_ACCOUNT_JSON  — full service account JSON downloaded from
//     Firebase Console → Project Settings → Service Accounts → Generate new key.

import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_ROLE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const SERVICE_ACCOUNT_JSON = Deno.env.get("FIREBASE_SERVICE_ACCOUNT_JSON");

// ── RSA-SHA256 JWT for Google OAuth2 service account ──────────────────────────

function pemToBytes(pem: string): Uint8Array {
  const body = pem
    .replace(/-----BEGIN PRIVATE KEY-----|-----END PRIVATE KEY-----|\s/g, "");
  const binary = atob(body);
  return Uint8Array.from(binary, (c) => c.charCodeAt(0));
}

function b64url(data: Uint8Array | string): string {
  const bytes =
    typeof data === "string"
      ? new TextEncoder().encode(data)
      : data;
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/, "");
}

async function getGoogleAccessToken(serviceAccount: {
  client_email: string;
  private_key: string;
  project_id: string;
}): Promise<string> {
  const key = await crypto.subtle.importKey(
    "pkcs8",
    pemToBytes(serviceAccount.private_key),
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const payload = b64url(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    }),
  );

  const unsigned = `${header}.${payload}`;
  const sig = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    key,
    new TextEncoder().encode(unsigned),
  );

  const jwt = `${unsigned}.${b64url(new Uint8Array(sig))}`;

  const res = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body:
      `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${jwt}`,
  });
  const json = await res.json();
  if (!json.access_token) throw new Error(`OAuth failed: ${JSON.stringify(json)}`);
  return json.access_token as string;
}

// ── Main handler ───────────────────────────────────────────────────────────────

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Headers": "authorization, content-type",
      },
    });
  }

  const authHeader = req.headers.get("Authorization");
  if (!authHeader) {
    return new Response(JSON.stringify({ error: "Unauthorized" }), {
      status: 401,
      headers: { "Content-Type": "application/json" },
    });
  }

  try {
    const {
      assigneeIds,
      taskId,
      taskTitle,
      groupId,
      createdByUserId,
    } = (await req.json()) as {
      assigneeIds: string[];
      taskId: string;
      taskTitle: string;
      groupId: string;
      createdByUserId: string;
    };

    const recipientIds = assigneeIds.filter((id) => id !== createdByUserId);
    if (recipientIds.length === 0) {
      return new Response(JSON.stringify({ ok: true, sent: 0 }), {
        headers: { "Content-Type": "application/json" },
      });
    }

    // Use service-role client so RLS doesn't block the inserts.
    const supabase = createClient(SUPABASE_URL, SERVICE_ROLE_KEY);

    // 1. Insert in-app notification rows for all recipients.
    await supabase.from("notifications").insert(
      recipientIds.map((userId) => ({
        user_id: userId,
        type: "task_assigned",
        title: "New task assigned to you",
        body: taskTitle,
        entity_type: "task",
        entity_id: taskId,
        group_id: groupId,
      })),
    );

    // 2. Send FCM push notifications if service account is configured.
    let fcmSent = 0;
    if (SERVICE_ACCOUNT_JSON) {
      const serviceAccount = JSON.parse(SERVICE_ACCOUNT_JSON);
      const { data: users } = await supabase
        .from("users")
        .select("id, fcm_token")
        .in("id", recipientIds)
        .not("fcm_token", "is", null);

      if (users && users.length > 0) {
        const accessToken = await getGoogleAccessToken(serviceAccount);
        const fcmUrl =
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`;

        await Promise.allSettled(
          users.map((user) =>
            fetch(fcmUrl, {
              method: "POST",
              headers: {
                Authorization: `Bearer ${accessToken}`,
                "Content-Type": "application/json",
              },
              body: JSON.stringify({
                message: {
                  token: user.fcm_token,
                  notification: {
                    title: "New task assigned to you",
                    body: taskTitle,
                  },
                  data: {
                    type: "task_assigned",
                    task_id: taskId,
                    group_id: groupId,
                  },
                  android: { priority: "high" },
                  apns: { payload: { aps: { sound: "default" } } },
                },
              }),
            })
          ),
        );
        fcmSent = users.length;
      }
    }

    return new Response(
      JSON.stringify({ ok: true, inApp: recipientIds.length, fcm: fcmSent }),
      { headers: { "Content-Type": "application/json" } },
    );
  } catch (err) {
    return new Response(JSON.stringify({ error: String(err) }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }
});
