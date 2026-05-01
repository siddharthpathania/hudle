# Hudle

> **Gather. Plan. Achieve.**

A cross-platform Flutter app for collaborative group management and task coordination. Built around **Groups** as the central unit, with first-class **Tasks**, an admin-curated **Announcement feed with polls**, full-text **Search**, and real-time **Push Notifications**.

---

## Features

### Authentication & Profile
- Email / password sign-up and login via Supabase Auth
- Auto-created profile via a PostgreSQL trigger on `auth.users`
- Onboarding screen to set display name before entering the app
- Profile screen: edit display name, username, bio, and upload a profile photo (Supabase Storage — `avatars` bucket)

### Groups
- Create public or private groups
- Invite members via shareable token links (optional expiry + usage cap)
- Four-tier roles: `super_admin`, `admin`, `member`, `guest`
- Admins can promote / demote, ban / unban, and remove members
- Group settings: rename, change description, toggle public/private, delete group

### Tasks
- Create tasks with title, description, priority (low / medium / high / urgent), due date/time, assignees, and visibility (`all` or tagged-only)
- Subtask checklist, custom per-group status columns (board view)
- Task detail screen: edit all fields, manage subtasks and assignees inline
- **Dashboard** personal task feed with three filter cards:
  - **Today** — tasks due today (device local timezone)
  - **Overdue** — past-due incomplete tasks
  - **Done this week** — tasks completed in the last 7 days

### Announcements & Polls
- Members submit announcements; admins / super-admins are auto-approved
- Admins have an **approval queue** to approve or reject pending posts with an optional note
- Announcements can include an attached poll (single-choice, 2–4 options)
- Voting replaces any previous vote atomically
- Emoji reactions (6 presets): one active reaction per user per announcement, toggle on/off

### Search
- Global search across tasks (full-text), announcements (full-text), and groups (name pattern)
- Results merged and sorted by recency; tapping navigates to the entity

### Notifications
- In-app notification centre with read / unread state and badge counter
- **Push notifications via FCM**: when a task is assigned to you, you receive both an in-app row and a device push (requires Edge Function setup — see below)

### Calendar
- Monthly calendar view showing task due dates; tap a day to list tasks due then

### Theme
- Light / Dark / System toggle, persisted across sessions
- **Ember & Ink** palette: Ember Orange `#E8612C` · Amber Gold `#F59E3A` · Hudle Teal `#0D9488` · Deep Ink Navy `#1A1A2E`

---

## Tech Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter (Dart) — Android + iOS |
| State management | Riverpod (`FutureProvider`, `FutureProvider.family`) |
| Routing | go_router with auth-guard redirect |
| Backend / Database | Supabase (PostgreSQL 15) |
| Authentication | Supabase Auth (email + password) |
| File storage | Supabase Storage (`avatars` bucket) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Edge Function | Supabase Edge Functions (Deno / TypeScript) |

---

## Getting Started

### Prerequisites
- Flutter SDK (stable channel)
- A [Supabase](https://supabase.com) project
- A [Firebase](https://console.firebase.google.com) project with Android + iOS apps registered

### 1. Clone and install dependencies

```bash
git clone <repo-url>
cd Dbms
flutter pub get
```

### 2. Configure environment

```bash
cp .env.example .env
```

Fill in `.env`:

```
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key>
```

Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from the Firebase console into their respective platform folders.

### 3. Apply database migrations

Run each file in order in **Supabase Dashboard → SQL Editor**:

```
supabase/migrations/20260419_000_initial_schema.sql
supabase/migrations/20260419_001_rls_policies.sql
supabase/migrations/20260419_002_add_approved_status.sql
supabase/migrations/20260429_003_group_invites_rls.sql
supabase/migrations/20260429_004_missing_tables_rls.sql
supabase/migrations/20260429_005_fix_task_rls_recursion.sql
supabase/migrations/20260429_006_polls_allow_multiple.sql
supabase/migrations/20260429_007_votes_and_reactions_constraints.sql
supabase/migrations/20260430_008_announcement_and_poll_delete_policies.sql
supabase/migrations/20260430_009_avatars_bucket.sql
supabase/migrations/20260501_010_fcm_tokens.sql
supabase/migrations/20260501_011_group_members_manage.sql
```

### 4. Run the app

```bash
flutter run
```

---

## Push Notifications Setup (optional)

In-app notifications work out of the box. To enable **FCM push delivery** when a task is assigned:

1. **Firebase Console → Project Settings → Service Accounts → Generate new private key** — download the JSON file.

2. **Supabase Dashboard → Edge Functions → Secrets** — add a secret named `FIREBASE_SERVICE_ACCOUNT_JSON` with the full contents of the downloaded JSON.

3. **Deploy the Edge Function:**

```bash
supabase functions deploy notify-task-assigned
```

The function is invoked automatically by the app after task creation; it inserts in-app notification rows and sends FCM pushes to every assignee except the creator.

---

## Project Structure

```
lib/
├── main.dart                    # Entry point — Supabase + Firebase init
├── app.dart                     # MaterialApp.router
├── core/
│   ├── constants/               # AppColors, UI spacing tokens, env vars
│   ├── theme/                   # Ember & Ink ThemeData + typography
│   ├── router/                  # go_router config + auth redirect guard
│   ├── services/                # SupabaseService, NotificationService (FCM)
│   └── widgets/                 # HudleButton, PriorityBadge, AvatarStack,
│                                #   StatusBadge, ShimmerLoader
└── features/
    ├── auth/                    # Login, signup, profile-setup screens
    ├── profile/                 # Profile edit + avatar upload
    ├── groups/                  # Groups list, detail, settings
    ├── tasks/                   # Board, detail, create/edit screens
    ├── announcements/           # Feed, approval queue, create screen
    ├── dashboard/               # Personal task overview + stat cards
    ├── calendar/                # Monthly calendar with task due dates
    ├── search/                  # Cross-entity full-text search
    ├── notifications/           # In-app notification centre
    └── shell/                   # MainShell (bottom nav), Splash, Onboarding

supabase/
├── migrations/                  # 12 ordered SQL migrations
└── functions/
    └── notify-task-assigned/    # Deno Edge Function — FCM push on assignment
```

---

## Database Schema (summary)

| Table | Purpose |
|---|---|
| `users` | User profiles; auto-created via trigger on `auth.users` |
| `groups` | Workspaces |
| `group_members` | Membership with roles (`super_admin`, `admin`, `member`, `guest`) |
| `group_invites` | Invite-link tokens |
| `join_requests` | Pending join requests for private groups |
| `task_statuses` | Per-group customisable workflow columns |
| `tasks` | Tasks with priority, due date, visibility, full-text `tsvector` |
| `task_assignees` | Many-to-many task ↔ user |
| `task_subtasks` | Checklist items per task |
| `task_attachments` | File references per task |
| `task_comments` | Threaded comments per task |
| `announcements` | Group posts with approval workflow + full-text `tsvector` |
| `polls` / `poll_options` / `poll_votes` | Single-choice polls on announcements |
| `announcement_reactions` | Emoji reactions (one active per user per announcement) |
| `notifications` | Per-user inbox with read/unread state |
| `activity_log` | Audit trail of group actions |

Row-Level Security is enabled on every table. Policies use three `SECURITY DEFINER` helper functions (`get_my_group_ids`, `get_my_admin_group_ids`, `get_my_member_group_ids`) to avoid infinite recursion on `group_members` self-joins.

---

## License

Private — all rights reserved.
