# Hudle — Project Description

## 1. Idea & Motivation

Hudle is a collaborative group management and task-coordination mobile application. The core idea is to give teams, clubs, or any informal group a single place where they can:

- Organise members with fine-grained roles.
- Assign, track, and filter tasks with due dates and priority levels.
- Publish announcements that go through an approval workflow before the group sees them.
- Run lightweight polls attached to announcements.
- React to content with emoji reactions.
- Stay informed through an in-app notification centre.
- Search across tasks, announcements, and groups instantly.

The project was built as the DBMS course term project to demonstrate real-world relational database design, Row-Level Security (RLS), full-text search, storage, triggers, and complex multi-table queries — all on a live cloud database (Supabase / PostgreSQL).

---

## 2. Technology Stack

| Layer | Technology |
|---|---|
| Mobile frontend | Flutter (Dart), Riverpod state management |
| Backend / Database | Supabase (PostgreSQL 15) |
| Authentication | Supabase Auth (email + password) |
| File storage | Supabase Storage (avatars bucket) |
| Push notifications | Firebase Cloud Messaging (FCM) |
| Routing | go_router |
| Fonts | Google Fonts (Plus Jakarta Sans, DM Sans) |

---

## 3. Database Schema

### 3.1 Entity Relationship Overview

```
auth.users ──< public.users >──< group_members >──< groups
                                                      │
                                    ┌─────────────────┤
                              group_invites       join_requests
                                                      │
                              tasks ─── task_statuses │
                                │                     │
                    ┌───────────┼───────────┐    announcements
              task_assignees  task_subtasks │         │
              task_attachments task_comments│    ┌────┴────┐
                                            │  polls  announcement_reactions
                                       notifications  │
                                       activity_log poll_options
                                                    poll_votes
```

### 3.2 Tables

#### `public.users`
Mirrors `auth.users` with additional profile fields. Populated automatically via a `BEFORE INSERT` trigger on `auth.users`.

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | References `auth.users(id)` |
| email | TEXT UNIQUE | |
| display_name | TEXT | |
| username | TEXT UNIQUE | Auto-generated on signup |
| avatar_url | TEXT | Public Supabase Storage URL |
| bio | TEXT | Optional |
| created_at / updated_at | TIMESTAMPTZ | |

#### `public.groups`
A workspace that members collaborate inside.

| Column | Type | Notes |
|---|---|---|
| id | UUID PK | |
| name | TEXT | |
| description | TEXT | |
| avatar_url | TEXT | |
| is_public | BOOLEAN | Public groups are discoverable by search |
| created_by | UUID FK → users | |

#### `public.group_members`
Membership join table with role-based access control.

| Column | Type | Notes |
|---|---|---|
| group_id | UUID FK → groups | |
| user_id | UUID FK → users | |
| role | ENUM | `super_admin`, `admin`, `member`, `guest` |
| is_banned | BOOLEAN | Banned users cannot access group content |
| Unique constraint | (group_id, user_id) | |

#### `public.group_invites`
Invite-link tokens that admins share to let users join without a manual request.

| Column | Type | Notes |
|---|---|---|
| token | TEXT UNIQUE | Random 16-byte hex string |
| max_uses / use_count | INT | Optional usage cap |
| expires_at | TIMESTAMPTZ | Optional expiry |

#### `public.join_requests`
Pending join requests for non-public groups (status: `pending` → `approved` / `rejected`).

#### `public.task_statuses`
Per-group customisable workflow columns (e.g. "To Do", "In Progress", "Done").

| Column | Type | Notes |
|---|---|---|
| group_id | UUID FK → groups | |
| label | TEXT | |
| color | TEXT | Hex colour string |
| order_index | INT | Display order in board view |
| is_default | BOOLEAN | Assigned to new tasks automatically |

#### `public.tasks`
The central work-item entity.

| Column | Type | Notes |
|---|---|---|
| title / description | TEXT | |
| group_id | UUID FK → groups | |
| created_by | UUID FK → users | |
| status_id | UUID FK → task_statuses | |
| priority | ENUM | `low`, `medium`, `high`, `urgent` |
| due_at | TIMESTAMPTZ | |
| visibility | ENUM | `all` (all members) or `tagged` (assignees + admins only) |
| is_recurring / recurrence_rule | BOOLEAN / TEXT | Future recurring tasks support |
| search_vector | tsvector GENERATED | Full-text search over title + description |

#### `public.task_assignees`
Many-to-many: a task can be assigned to multiple members.

#### `public.task_subtasks`
Checklist items inside a task with `is_completed` and `order_index`.

#### `public.task_attachments`
File references (URL, name, MIME type, size) uploaded against a task.

#### `public.task_comments`
Threaded comments on tasks; supports `parent_comment_id` for replies.

#### `public.announcements`
Group-wide posts with an approval workflow.

| Column | Type | Notes |
|---|---|---|
| content | TEXT | |
| status | ENUM | `draft` → `pending` → `approved` / `rejected` |
| posted_by / approved_by | UUID FK → users | |
| reject_note | TEXT | Rejection reason from admin |
| search_vector | tsvector GENERATED | Full-text search |

Admins and super-admins bypass the approval queue — their posts are set to `approved` immediately on insert.

#### `public.polls`
A poll tied to an announcement (one per announcement).

| Column | Type | Notes |
|---|---|---|
| announcement_id | UUID FK → announcements | |
| question | TEXT | |
| is_closed | BOOLEAN | Prevents further voting |

#### `public.poll_options`
Options for a poll with `order_index`.

#### `public.poll_votes`
One vote per user per poll (enforced by `UNIQUE(poll_id, user_id)`). Voting replaces the previous vote atomically.

#### `public.announcement_reactions`
Emoji reactions on announcements. One reaction per user per announcement per emoji enforced by `UNIQUE(announcement_id, user_id, emoji)`. Toggling the same emoji removes the reaction; a different emoji replaces it.

#### `public.notifications`
Inbox items per user.

| Column | Type | Notes |
|---|---|---|
| type | TEXT | e.g. `task_assigned`, `announcement_posted` |
| title / body | TEXT | |
| entity_type / entity_id | TEXT / UUID | Deep-link target |
| group_id | UUID FK → groups | |
| is_read | BOOLEAN | |

#### `public.activity_log`
Audit trail of group actions (actor, action type, entity, metadata JSONB).

---

## 4. Indexes

| Index | Purpose |
|---|---|
| `tasks_search_idx` (GIN on `search_vector`) | Full-text task search |
| `announcements_search_idx` (GIN on `search_vector`) | Full-text announcement search |
| `idx_tasks_due_at` | Range queries for Today / Overdue / Upcoming filters |
| `idx_tasks_group_id` | Fetch all tasks in a group |
| `idx_task_assignees_user` | Fetch tasks assigned to a user |
| `idx_announcements_group_status` | Feed queries filtered by group + status |
| `idx_notifications_user_id` | Load inbox per user |
| `idx_notifications_unread` (partial) | Unread badge count — only scans unread rows |
| `idx_activity_log_group` | Activity feed sorted by time |

---

## 5. Row-Level Security (RLS)

RLS is enabled on every table. Policies enforce:

- **Users**: anyone can read all profiles (needed for member chips); only the owner can update their own row.
- **Groups**: visible to members and the public if `is_public = true`; only admins can update.
- **group_members**: members can view membership of groups they belong to.
- **Tasks**: visible based on `visibility` flag — `all` = all group members; `tagged` = only assignees and admins.
- **Announcements**: only `approved` posts are visible to regular members; authors see their own pending/rejected posts; admins see everything in their groups.
- **Polls, poll_votes, reactions**: scoped to members of the announcement's group.
- **Notifications**: strictly owner-only.

### Recursion-Breaking Helper Functions

A naive policy on `group_members` that checks `group_members` to decide who is a member causes infinite recursion. Three `SECURITY DEFINER` functions run with elevated privileges and bypass RLS:

```sql
-- Returns group_ids where the current user is any (non-banned) member
public.get_my_group_ids()

-- Returns group_ids where the current user is admin or super_admin
public.get_my_admin_group_ids()

-- Returns group_ids where the current user is admin/super_admin/member (not guest)
public.get_my_member_group_ids()
```

All data-access policies call these helpers instead of querying `group_members` directly.

---

## 6. Triggers & Automation

### Auto-create user profile on signup
```sql
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.users (id, email, display_name, username)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', split_part(NEW.email, '@', 1)),
    split_part(NEW.email, '@', 1) || '_' || substr(gen_random_uuid()::text, 1, 6)
  );
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();
```

This fires whenever Supabase Auth creates a new user and inserts a matching row in `public.users` with a unique auto-generated username.

---

## 7. Full-Text Search

Two tables carry a `tsvector` generated column (`GENERATED ALWAYS AS ... STORED`):

```sql
-- tasks
search_vector tsvector GENERATED ALWAYS AS
  (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,''))) STORED

-- announcements
search_vector tsvector GENERATED ALWAYS AS
  (to_tsvector('english', coalesce(content,''))) STORED
```

Search is run using PostgreSQL's `@@` operator via Supabase's `.textSearch()` helper:

```dart
.textSearch('search_vector', query, config: 'english')
```

Groups are searched separately with a `ILIKE '%query%'` pattern on the `name` column. All three result sets are merged, deduplicated, and sorted by `created_at` descending in Dart.

---

## 8. Major Queries

### 8.1 Dashboard Tasks (personal task feed)
Fetches tasks for the current user from two angles and merges them:

```sql
-- Query A: tasks where I am an explicit assignee
SELECT tasks.*, groups(name), task_statuses(id, label, color),
       task_subtasks(id, is_completed),
       task_assignees!inner(user_id)
FROM tasks
WHERE task_assignees.user_id = '<uid>'
  AND due_at >= '<todayStart UTC>'   -- when Today filter is active
  AND due_at <  '<todayEnd UTC>'
ORDER BY due_at ASC;

-- Query B: tasks I created
SELECT tasks.*, groups(name), task_statuses(id, label, color),
       task_subtasks(id, is_completed),
       task_assignees(user_id)
FROM tasks
WHERE created_by = '<uid>'
ORDER BY due_at ASC;
```

Results are merged in Dart with deduplication by task `id`, then re-sorted. Date boundaries use the device's local timezone converted to UTC before being sent over the wire.

### 8.2 Group Task Board
```sql
SELECT tasks.*,
       task_assignees(user_id, users(display_name, avatar_url)),
       task_statuses(id, label, color, order_index),
       task_subtasks(id, title, is_completed, order_index)
FROM tasks
WHERE group_id = '<groupId>'
ORDER BY due_at ASC;
```

Optional filters add `.eq('task_assignees.user_id', uid)` (mine only) or `.eq('created_by', uid)` (created by me).

### 8.3 Announcement Feed with Polls and Reactions
```sql
SELECT announcements.*,
       users!announcements_posted_by_fkey(id, display_name, avatar_url),
       announcement_attachments(id, file_url, file_name, file_type),
       announcement_reactions(emoji, user_id),
       polls(id, question, is_closed,
             poll_options(id, option_text, order_index),
             poll_votes(option_id, user_id)),
       groups(name)
FROM announcements
WHERE group_id = '<groupId>'
  AND status = 'approved'
ORDER BY created_at DESC;
```

This single query returns the full announcement card including nested poll options, all cast votes, and per-emoji reaction counts in one round-trip.

### 8.4 Cross-Entity Search
Three parallel queries, merged client-side:

```sql
-- Tasks (full-text)
SELECT id, title, description, group_id, created_at, groups(name)
FROM tasks
WHERE search_vector @@ to_tsquery('english', '<query>')
LIMIT 25;

-- Announcements (full-text, approved only)
SELECT id, content, group_id, created_at, groups(name)
FROM announcements
WHERE status = 'approved'
  AND search_vector @@ to_tsquery('english', '<query>')
LIMIT 25;

-- Groups (name pattern)
SELECT id, name, description, created_at
FROM groups
WHERE name ILIKE '%<query>%'
LIMIT 15;
```

### 8.5 Approval Queue
```sql
SELECT <full_announcement_select>
FROM announcements
WHERE group_id = '<groupId>'
  AND status = 'pending'
ORDER BY created_at ASC;
```

### 8.6 Unread Notification Count
Uses the partial index `idx_notifications_unread` (`WHERE is_read = false`):

```sql
SELECT count(*)
FROM notifications
WHERE user_id = auth.uid()
  AND is_read = false;
```

### 8.7 User Group List
```sql
SELECT groups.*, group_members(count)
FROM group_members
  JOIN groups ON groups.id = group_members.group_id
WHERE group_members.user_id = '<uid>'
  AND group_members.is_banned = false;
```

### 8.8 Cast Poll Vote (upsert pattern)
```sql
-- Delete old vote first (enforces single-choice without an UPSERT on a composite key)
DELETE FROM poll_votes WHERE poll_id = '<pollId>' AND user_id = '<uid>';

-- Insert new vote
INSERT INTO poll_votes (poll_id, option_id, user_id)
VALUES ('<pollId>', '<optionId>', '<uid>');
```

### 8.9 Toggle Emoji Reaction
```sql
-- Check for existing reaction
SELECT id, emoji FROM announcement_reactions
WHERE announcement_id = '<id>' AND user_id = '<uid>';

-- If none: INSERT new reaction
-- If same emoji: DELETE (toggle off)
-- If different emoji: UPDATE emoji column
```

---

## 9. Storage

The `avatars` Supabase Storage bucket is **public** (any authenticated user can read any avatar URL, which is required for member chips and lists). Write is restricted by RLS to the owner's folder only:

```sql
-- INSERT policy
WITH CHECK (
  bucket_id = 'avatars'
  AND auth.uid()::text = (storage.foldername(name))[1]
);
```

Files are stored at path `<uid>/avatar.<ext>`. Cache-busting is applied by appending `?v=<timestamp>` to the public URL after upload.

---

## 10. Application Features

### Authentication
- Email / password sign-up and login via Supabase Auth.
- Auto-created profile row with unique username via database trigger.
- Post-signup onboarding screen to set display name before entering the app.
- Session-based routing: unauthenticated users are redirected to `/auth/login`.

### Profile
- Edit display name, username, and bio.
- Upload a profile photo from gallery (compressed to 85% quality, max 800 px wide).
- Avatar stored in Supabase Storage; URL saved back to `users.avatar_url`.

### Groups
- Create public or private groups.
- Invite members via generated token links (optional expiry and usage cap).
- Four-tier roles: `super_admin`, `admin`, `member`, `guest`.
- Admins can promote/demote members, ban/unban, and remove members.
- Admins can regenerate or revoke invite links.
- Group settings: rename, change description, toggle public/private, delete group.

### Tasks
- Create tasks with title, description, priority (low / medium / high / urgent), due date, assignees, and visibility (`all` or `tagged`).
- Subtask checklist inside each task.
- Custom per-group status columns (board view).
- Filter group tasks: All / Mine / Created by me.
- Full task detail screen: edit fields inline, manage subtasks and assignees.
- Dashboard personal task feed with three summary stat cards:
  - **Today** — tasks due today (local timezone).
  - **Overdue** — tasks whose `due_at` is in the past and incomplete.
  - **Done this week** — tasks completed in the last 7 days.
- Tap a stat card to filter the task list below it.

### Announcements & Polls
- Members submit announcements (text content); admins and super-admins are auto-approved.
- Admins see a pending-approval queue; they can approve (with optional note) or reject.
- Announcements can optionally include a poll (one question, 2–4 options).
- Single-choice voting: casting a vote replaces any previous vote atomically.
- Emoji reactions (six preset emojis): toggle on/off; one reaction slot per user per announcement.
- Admin or author can delete an announcement or its poll.

### Search
- Global search bar queries tasks (full-text), announcements (full-text), and groups (name pattern) in parallel.
- Results merged and sorted by recency; tapping navigates to the relevant entity.

### Notifications
- In-app notification centre with read/unread state.
- Unread badge on the nav-bar bell icon.
- Mark individual or all notifications as read.

### Calendar
- Monthly calendar view showing task due dates.
- Tap a day to see tasks due on that date.

### Theme
- Light / Dark / System theme toggle, persisted via `SharedPreferences`.

---

## 11. Architecture

The app follows a feature-first layered architecture:

```
lib/
  core/
    constants/         # colours, spacing, env vars
    router/            # go_router configuration + auth redirect guard
    services/          # SupabaseService singleton, NotificationService
    theme/             # ThemeData, ThemeController (Riverpod Notifier)
    widgets/           # shared widgets (HudleButton, PriorityBadge, ShimmerLoader…)
  features/
    auth/              # login, signup, profile-setup screens + AuthRepository
    profile/           # ProfileScreen, ProfileRepository, ProfileProvider
    groups/            # group list, detail, settings screens + GroupsRepository
    tasks/             # board, detail, create/edit screens + TasksRepository
    announcements/     # feed, approval queue, create screen + AnnouncementsRepository
    calendar/          # CalendarScreen
    search/            # SearchScreen + SearchRepository
    notifications/     # NotificationsScreen + NotificationsRepository
    dashboard/         # DashboardScreen (personal task overview)
    shell/             # MainShell (bottom nav), SplashScreen, OnboardingScreen
```

Each feature contains:
- `data/` — repository class that talks directly to Supabase.
- `domain/` — model classes (plain Dart), Riverpod providers.
- `presentation/` — screens and widgets.

State management uses Riverpod `FutureProvider` and `FutureProvider.family` throughout; `ref.invalidate()` is the primary cache-invalidation mechanism after mutations.

---

## 12. Migrations

| File | Contents |
|---|---|
| `000_initial_schema.sql` | All tables, types, indexes, and the `handle_new_user` trigger |
| `001_rls_policies.sql` | All RLS policies and the three security-definer helper functions |
| `002_add_approved_status.sql` | Adds `approved` to `announcement_status` enum |
| `003_group_invites_rls.sql` | RLS on `group_invites` and `join_requests` |
| `004_missing_tables_rls.sql` | RLS on task sub-tables, reactions, polls, activity log |
| `005_fix_task_rls_recursion.sql` | Rewrites task policies to use helper functions (fixes infinite recursion) |
| `006_polls_allow_multiple.sql` | Adds `allow_multiple` column to `polls` (column kept, feature removed from UI) |
| `007_votes_and_reactions_constraints.sql` | Adds `UNIQUE` constraint on `poll_votes(poll_id, user_id)` and `announcement_reactions(announcement_id, user_id, emoji)` |
| `008_announcement_and_poll_delete_policies.sql` | Adds `DELETE` RLS policies for announcements and polls |
| `009_avatars_bucket.sql` | Creates public `avatars` storage bucket with per-user write RLS |

---

## 13. Key Design Decisions

| Decision | Rationale |
|---|---|
| `SECURITY DEFINER` helper functions for membership checks | Breaks the circular RLS dependency on `group_members` without disabling RLS |
| `tsvector GENERATED ALWAYS AS ... STORED` | Full-text search without maintaining a separate update trigger |
| Dual-query strategy for dashboard tasks | Catches tasks where the user is assignee OR creator without a complex OR on a join |
| Local-timezone date boundaries converted to UTC | Ensures "Today" respects the user's clock, not the server's UTC date |
| Avatar path `<uid>/avatar.<ext>` with upsert | Overwrites the previous avatar cleanly; cache-bust via query-string `?v=<ts>` |
| Single-choice poll enforced by `UNIQUE(poll_id, user_id)` + delete-then-insert | Atomic vote replacement without an UPSERT conflict strategy |
| Auto-approval for admin/super_admin announcements | Admins shouldn't need to approve their own posts; role is checked at insert time |
