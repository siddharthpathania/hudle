-- Hudle — Initial schema
-- Covers: users, groups, members, invites, join requests, tasks,
-- task assignees/subtasks/attachments/comments, announcements,
-- polls, reactions, notifications, activity log.

-- ─── USERS ───────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.users (
  id            UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email         TEXT NOT NULL UNIQUE,
  display_name  TEXT NOT NULL,
  username      TEXT NOT NULL UNIQUE,
  avatar_url    TEXT,
  bio           TEXT,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  updated_at    TIMESTAMPTZ DEFAULT NOW()
);

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

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE PROCEDURE public.handle_new_user();

-- ─── GROUPS & MEMBERS ────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.groups (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name         TEXT NOT NULL,
  description  TEXT,
  avatar_url   TEXT,
  is_public    BOOLEAN DEFAULT FALSE,
  created_by   UUID REFERENCES public.users(id),
  created_at   TIMESTAMPTZ DEFAULT NOW(),
  updated_at   TIMESTAMPTZ DEFAULT NOW()
);

DO $$ BEGIN
  CREATE TYPE public.member_role AS ENUM ('super_admin', 'admin', 'member', 'guest');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.group_members (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.users(id) ON DELETE CASCADE,
  role       public.member_role DEFAULT 'member',
  is_banned  BOOLEAN DEFAULT FALSE,
  joined_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.group_invites (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  token       TEXT UNIQUE DEFAULT encode(gen_random_bytes(16), 'hex'),
  created_by  UUID REFERENCES public.users(id),
  expires_at  TIMESTAMPTZ,
  max_uses    INT,
  use_count   INT DEFAULT 0,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.join_requests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  user_id    UUID REFERENCES public.users(id) ON DELETE CASCADE,
  status     TEXT DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(group_id, user_id)
);

-- ─── TASKS ───────────────────────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE public.task_priority   AS ENUM ('low', 'medium', 'high', 'urgent');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

DO $$ BEGIN
  CREATE TYPE public.task_visibility AS ENUM ('all', 'tagged');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.task_statuses (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  label       TEXT NOT NULL,
  color       TEXT NOT NULL DEFAULT '#64748B',
  order_index INT DEFAULT 0,
  is_default  BOOLEAN DEFAULT FALSE
);

CREATE TABLE IF NOT EXISTS public.tasks (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id        UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  title           TEXT NOT NULL,
  description     TEXT,
  created_by      UUID REFERENCES public.users(id),
  status_id       UUID REFERENCES public.task_statuses(id),
  priority        public.task_priority DEFAULT 'medium',
  due_at          TIMESTAMPTZ,
  visibility      public.task_visibility DEFAULT 'all',
  is_recurring    BOOLEAN DEFAULT FALSE,
  recurrence_rule TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),
  search_vector   tsvector GENERATED ALWAYS AS
    (to_tsvector('english', coalesce(title,'') || ' ' || coalesce(description,''))) STORED
);

CREATE TABLE IF NOT EXISTS public.task_assignees (
  id       UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id  UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id  UUID REFERENCES public.users(id) ON DELETE CASCADE,
  UNIQUE(task_id, user_id)
);

CREATE TABLE IF NOT EXISTS public.task_subtasks (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id      UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  title        TEXT NOT NULL,
  is_completed BOOLEAN DEFAULT FALSE,
  order_index  INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.task_attachments (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id     UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  file_url    TEXT NOT NULL,
  file_name   TEXT NOT NULL,
  file_type   TEXT NOT NULL,
  file_size   BIGINT,
  uploaded_by UUID REFERENCES public.users(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.task_comments (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id           UUID REFERENCES public.tasks(id) ON DELETE CASCADE,
  user_id           UUID REFERENCES public.users(id),
  content           TEXT NOT NULL,
  parent_comment_id UUID REFERENCES public.task_comments(id),
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS tasks_search_idx       ON public.tasks USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_tasks_group_id     ON public.tasks(group_id);
CREATE INDEX IF NOT EXISTS idx_tasks_due_at       ON public.tasks(due_at);
CREATE INDEX IF NOT EXISTS idx_task_assignees_user ON public.task_assignees(user_id);

-- ─── ANNOUNCEMENTS & POLLS ───────────────────────────────────────
DO $$ BEGIN
  CREATE TYPE public.announcement_status AS ENUM ('draft', 'pending', 'approved', 'rejected', 'published');
EXCEPTION WHEN duplicate_object THEN NULL; END $$;

CREATE TABLE IF NOT EXISTS public.announcements (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id      UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  posted_by     UUID REFERENCES public.users(id),
  content       TEXT NOT NULL,
  status        public.announcement_status DEFAULT 'pending',
  reject_note   TEXT,
  approved_by   UUID REFERENCES public.users(id),
  approved_at   TIMESTAMPTZ,
  created_at    TIMESTAMPTZ DEFAULT NOW(),
  search_vector tsvector GENERATED ALWAYS AS
    (to_tsvector('english', coalesce(content,''))) STORED
);

CREATE TABLE IF NOT EXISTS public.announcement_attachments (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID REFERENCES public.announcements(id) ON DELETE CASCADE,
  file_url        TEXT NOT NULL,
  file_name       TEXT NOT NULL,
  file_type       TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS public.announcement_reactions (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID REFERENCES public.announcements(id) ON DELETE CASCADE,
  user_id         UUID REFERENCES public.users(id),
  emoji           TEXT NOT NULL,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(announcement_id, user_id, emoji)
);

CREATE TABLE IF NOT EXISTS public.polls (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  announcement_id UUID REFERENCES public.announcements(id) ON DELETE CASCADE,
  question        TEXT NOT NULL,
  is_closed       BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.poll_options (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id     UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  option_text TEXT NOT NULL,
  order_index INT DEFAULT 0
);

CREATE TABLE IF NOT EXISTS public.poll_votes (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  poll_id   UUID REFERENCES public.polls(id) ON DELETE CASCADE,
  option_id UUID REFERENCES public.poll_options(id) ON DELETE CASCADE,
  user_id   UUID REFERENCES public.users(id),
  voted_at  TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(poll_id, user_id)
);

CREATE INDEX IF NOT EXISTS announcements_search_idx     ON public.announcements USING GIN(search_vector);
CREATE INDEX IF NOT EXISTS idx_announcements_group_status ON public.announcements(group_id, status);

-- ─── NOTIFICATIONS & ACTIVITY ────────────────────────────────────
CREATE TABLE IF NOT EXISTS public.notifications (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES public.users(id) ON DELETE CASCADE,
  type        TEXT NOT NULL,
  title       TEXT NOT NULL,
  body        TEXT,
  entity_type TEXT,
  entity_id   UUID,
  group_id    UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  is_read     BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.activity_log (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id    UUID REFERENCES public.groups(id) ON DELETE CASCADE,
  actor_id    UUID REFERENCES public.users(id),
  action_type TEXT NOT NULL,
  entity_type TEXT,
  entity_id   UUID,
  meta        JSONB,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON public.notifications(user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread  ON public.notifications(user_id, is_read)
  WHERE is_read = false;
CREATE INDEX IF NOT EXISTS idx_activity_log_group    ON public.activity_log(group_id, created_at DESC);
