-- Row-Level Security policies for Hudle.

-- ── USERS ────────────────────────────────────────────────────────
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view all profiles" ON public.users;
CREATE POLICY "Users can view all profiles" ON public.users FOR SELECT USING (true);
DROP POLICY IF EXISTS "Users can update own profile" ON public.users;
CREATE POLICY "Users can update own profile" ON public.users FOR UPDATE USING (auth.uid() = id);

-- ── GROUPS ───────────────────────────────────────────────────────
ALTER TABLE public.groups ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Members can view their groups" ON public.groups;
CREATE POLICY "Members can view their groups" ON public.groups FOR SELECT
  USING (
    id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND is_banned = false)
    OR is_public = true
  );
DROP POLICY IF EXISTS "Authenticated users can create groups" ON public.groups;
CREATE POLICY "Authenticated users can create groups" ON public.groups FOR INSERT
  WITH CHECK (auth.uid() IS NOT NULL);
DROP POLICY IF EXISTS "Admins can update group" ON public.groups;
CREATE POLICY "Admins can update group" ON public.groups FOR UPDATE
  USING (id IN (
    SELECT group_id FROM public.group_members
    WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin') AND is_banned = false
  ));

-- ── GROUP MEMBERS ────────────────────────────────────────────────
ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Members can view membership" ON public.group_members;
CREATE POLICY "Members can view membership" ON public.group_members FOR SELECT
  USING (group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()));
DROP POLICY IF EXISTS "Users can join groups" ON public.group_members;
CREATE POLICY "Users can join groups" ON public.group_members FOR INSERT
  WITH CHECK (user_id = auth.uid());

-- ── TASKS ────────────────────────────────────────────────────────
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Task visibility policy" ON public.tasks;
CREATE POLICY "Task visibility policy" ON public.tasks FOR SELECT
  USING (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND is_banned = false)
    AND (
      visibility = 'all'
      OR created_by = auth.uid()
      OR id IN (SELECT task_id FROM public.task_assignees WHERE user_id = auth.uid())
      OR group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin'))
    )
  );
DROP POLICY IF EXISTS "Members can create tasks" ON public.tasks;
CREATE POLICY "Members can create tasks" ON public.tasks FOR INSERT
  WITH CHECK (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin', 'member') AND is_banned = false)
  );
DROP POLICY IF EXISTS "Task edit policy" ON public.tasks;
CREATE POLICY "Task edit policy" ON public.tasks FOR UPDATE
  USING (
    created_by = auth.uid()
    OR group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin'))
  );
DROP POLICY IF EXISTS "Task delete policy" ON public.tasks;
CREATE POLICY "Task delete policy" ON public.tasks FOR DELETE
  USING (
    created_by = auth.uid()
    OR group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin'))
  );

-- ── ANNOUNCEMENTS ────────────────────────────────────────────────
ALTER TABLE public.announcements ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Members see published" ON public.announcements;
CREATE POLICY "Members see published" ON public.announcements FOR SELECT
  USING (
    (status = 'published' AND group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid()))
    OR posted_by = auth.uid()
    OR group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin'))
  );
DROP POLICY IF EXISTS "Members can submit" ON public.announcements;
CREATE POLICY "Members can submit" ON public.announcements FOR INSERT
  WITH CHECK (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin', 'member') AND is_banned = false)
  );
DROP POLICY IF EXISTS "Admins can approve/reject" ON public.announcements;
CREATE POLICY "Admins can approve/reject" ON public.announcements FOR UPDATE
  USING (
    group_id IN (SELECT group_id FROM public.group_members WHERE user_id = auth.uid() AND role IN ('super_admin', 'admin'))
  );

-- ── NOTIFICATIONS ────────────────────────────────────────────────
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users see own notifications" ON public.notifications;
CREATE POLICY "Users see own notifications" ON public.notifications FOR SELECT USING (user_id = auth.uid());
DROP POLICY IF EXISTS "Users can update own" ON public.notifications;
CREATE POLICY "Users can update own" ON public.notifications FOR UPDATE USING (user_id = auth.uid());
