-- RLS policies for group_invites.
-- The initial RLS migration (001) never added policies for this table,
-- causing every INSERT/UPDATE/SELECT/DELETE to be rejected with code 42501.

ALTER TABLE public.group_invites ENABLE ROW LEVEL SECURITY;

-- SELECT ─────────────────────────────────────────────────────────────────────
-- (a) Admins of the group can list all invites for that group.
-- (b) ANY authenticated user can read a single invite row (needed by
--     joinViaInvite, which looks up the invite by token before the user is
--     even a member of the group).
DROP POLICY IF EXISTS "Admins can view group invites" ON public.group_invites;
CREATE POLICY "Admins can view group invites" ON public.group_invites
  FOR SELECT
  USING (
    group_id IN (SELECT public.get_my_admin_group_ids())
    OR auth.uid() IS NOT NULL   -- allow any authed user to resolve a token
  );

-- INSERT ──────────────────────────────────────────────────────────────────────
-- Only admins of the target group may create invite links.
DROP POLICY IF EXISTS "Admins can create group invites" ON public.group_invites;
CREATE POLICY "Admins can create group invites" ON public.group_invites
  FOR INSERT
  WITH CHECK (
    group_id IN (SELECT public.get_my_admin_group_ids())
  );

-- UPDATE ──────────────────────────────────────────────────────────────────────
-- Any authenticated user may increment use_count when joining via a token.
-- Admins may also update their own group's invites (e.g. editing max_uses).
DROP POLICY IF EXISTS "Authenticated users can update invite use_count" ON public.group_invites;
CREATE POLICY "Authenticated users can update invite use_count" ON public.group_invites
  FOR UPDATE
  USING (auth.uid() IS NOT NULL);

-- DELETE ──────────────────────────────────────────────────────────────────────
-- Only admins of the group may revoke (delete) an invite.
DROP POLICY IF EXISTS "Admins can revoke group invites" ON public.group_invites;
CREATE POLICY "Admins can revoke group invites" ON public.group_invites
  FOR DELETE
  USING (
    group_id IN (SELECT public.get_my_admin_group_ids())
  );
