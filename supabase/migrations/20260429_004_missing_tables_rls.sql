-- RLS policies for all tables not covered by migration 001.
--
-- Tables covered here:
--   join_requests, task_statuses, task_assignees, task_subtasks,
--   task_attachments, task_comments,
--   announcement_attachments, announcement_reactions,
--   polls, poll_options, poll_votes,
--   activity_log
--
-- Design rules (mirror the existing 001 conventions):
--   • "member"  = any non-banned member (get_my_group_ids)
--   • "full member" = role IN (super_admin, admin, member) (get_my_member_group_ids)
--   • "admin"   = role IN (super_admin, admin)              (get_my_admin_group_ids)
--   • Child rows (e.g. poll_options, task_subtasks) are resolved through
--     their parent's id so we avoid deep recursive subqueries.

-- ── JOIN REQUESTS ────────────────────────────────────────────────────────────
ALTER TABLE public.join_requests ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can submit join requests" ON public.join_requests;
CREATE POLICY "Users can submit join requests" ON public.join_requests
  FOR INSERT WITH CHECK (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can view own join requests" ON public.join_requests;
CREATE POLICY "Users can view own join requests" ON public.join_requests
  FOR SELECT USING (
    user_id = auth.uid()
    OR group_id IN (SELECT public.get_my_admin_group_ids())
  );

DROP POLICY IF EXISTS "Admins can manage join requests" ON public.join_requests;
CREATE POLICY "Admins can manage join requests" ON public.join_requests
  FOR UPDATE USING (group_id IN (SELECT public.get_my_admin_group_ids()));

DROP POLICY IF EXISTS "Admins can delete join requests" ON public.join_requests;
CREATE POLICY "Admins can delete join requests" ON public.join_requests
  FOR DELETE USING (
    user_id = auth.uid()
    OR group_id IN (SELECT public.get_my_admin_group_ids())
  );

-- ── TASK STATUSES ────────────────────────────────────────────────────────────
ALTER TABLE public.task_statuses ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view task statuses" ON public.task_statuses;
CREATE POLICY "Members can view task statuses" ON public.task_statuses
  FOR SELECT USING (group_id IN (SELECT public.get_my_group_ids()));

DROP POLICY IF EXISTS "Admins can manage task statuses" ON public.task_statuses;
CREATE POLICY "Admins can manage task statuses" ON public.task_statuses
  FOR ALL USING (group_id IN (SELECT public.get_my_admin_group_ids()));

-- ── TASK ASSIGNEES ───────────────────────────────────────────────────────────
ALTER TABLE public.task_assignees ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view task assignees" ON public.task_assignees;
CREATE POLICY "Members can view task assignees" ON public.task_assignees
  FOR SELECT USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can manage task assignees" ON public.task_assignees;
CREATE POLICY "Members can manage task assignees" ON public.task_assignees
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can remove task assignees" ON public.task_assignees;
CREATE POLICY "Members can remove task assignees" ON public.task_assignees
  FOR DELETE USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

-- ── TASK SUBTASKS ────────────────────────────────────────────────────────────
ALTER TABLE public.task_subtasks ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view subtasks" ON public.task_subtasks;
CREATE POLICY "Members can view subtasks" ON public.task_subtasks
  FOR SELECT USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can insert subtasks" ON public.task_subtasks;
CREATE POLICY "Members can insert subtasks" ON public.task_subtasks
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can update subtasks" ON public.task_subtasks;
CREATE POLICY "Members can update subtasks" ON public.task_subtasks
  FOR UPDATE USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can delete subtasks" ON public.task_subtasks;
CREATE POLICY "Members can delete subtasks" ON public.task_subtasks
  FOR DELETE USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

-- ── TASK ATTACHMENTS ─────────────────────────────────────────────────────────
ALTER TABLE public.task_attachments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view task attachments" ON public.task_attachments;
CREATE POLICY "Members can view task attachments" ON public.task_attachments
  FOR SELECT USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can add task attachments" ON public.task_attachments;
CREATE POLICY "Members can add task attachments" ON public.task_attachments
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can delete task attachments" ON public.task_attachments;
CREATE POLICY "Members can delete task attachments" ON public.task_attachments
  FOR DELETE USING (
    uploaded_by = auth.uid()
    OR task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

-- ── TASK COMMENTS ────────────────────────────────────────────────────────────
ALTER TABLE public.task_comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view task comments" ON public.task_comments;
CREATE POLICY "Members can view task comments" ON public.task_comments
  FOR SELECT USING (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can post task comments" ON public.task_comments;
CREATE POLICY "Members can post task comments" ON public.task_comments
  FOR INSERT WITH CHECK (
    task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Users can edit own task comments" ON public.task_comments;
CREATE POLICY "Users can edit own task comments" ON public.task_comments
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Users can delete own task comments" ON public.task_comments;
CREATE POLICY "Users can delete own task comments" ON public.task_comments
  FOR DELETE USING (
    user_id = auth.uid()
    OR task_id IN (
      SELECT id FROM public.tasks
      WHERE group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

-- ── ANNOUNCEMENT ATTACHMENTS ─────────────────────────────────────────────────
ALTER TABLE public.announcement_attachments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view announcement attachments" ON public.announcement_attachments;
CREATE POLICY "Members can view announcement attachments" ON public.announcement_attachments
  FOR SELECT USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can add announcement attachments" ON public.announcement_attachments;
CREATE POLICY "Members can add announcement attachments" ON public.announcement_attachments
  FOR INSERT WITH CHECK (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Admins can delete announcement attachments" ON public.announcement_attachments;
CREATE POLICY "Admins can delete announcement attachments" ON public.announcement_attachments
  FOR DELETE USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

-- ── ANNOUNCEMENT REACTIONS ───────────────────────────────────────────────────
ALTER TABLE public.announcement_reactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view reactions" ON public.announcement_reactions;
CREATE POLICY "Members can view reactions" ON public.announcement_reactions
  FOR SELECT USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can add reactions" ON public.announcement_reactions;
CREATE POLICY "Members can add reactions" ON public.announcement_reactions
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

DROP POLICY IF EXISTS "Users can remove own reactions" ON public.announcement_reactions;
CREATE POLICY "Users can remove own reactions" ON public.announcement_reactions
  FOR DELETE USING (user_id = auth.uid());

-- ── POLLS ────────────────────────────────────────────────────────────────────
-- polls belong to announcements; access is gated through the parent announcement's group.
ALTER TABLE public.polls ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view polls" ON public.polls;
CREATE POLICY "Members can view polls" ON public.polls
  FOR SELECT USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_group_ids())
    )
  );

-- Polls are created by members who are posting an announcement.
DROP POLICY IF EXISTS "Members can create polls" ON public.polls;
CREATE POLICY "Members can create polls" ON public.polls
  FOR INSERT WITH CHECK (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

-- Only admins can close/modify a poll after creation.
DROP POLICY IF EXISTS "Admins can update polls" ON public.polls;
CREATE POLICY "Admins can update polls" ON public.polls
  FOR UPDATE USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

DROP POLICY IF EXISTS "Admins can delete polls" ON public.polls;
CREATE POLICY "Admins can delete polls" ON public.polls
  FOR DELETE USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

-- ── POLL OPTIONS ─────────────────────────────────────────────────────────────
ALTER TABLE public.poll_options ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view poll options" ON public.poll_options;
CREATE POLICY "Members can view poll options" ON public.poll_options
  FOR SELECT USING (
    poll_id IN (
      SELECT p.id FROM public.polls p
      JOIN public.announcements a ON a.id = p.announcement_id
      WHERE a.group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can insert poll options" ON public.poll_options;
CREATE POLICY "Members can insert poll options" ON public.poll_options
  FOR INSERT WITH CHECK (
    poll_id IN (
      SELECT p.id FROM public.polls p
      JOIN public.announcements a ON a.id = p.announcement_id
      WHERE a.group_id IN (SELECT public.get_my_member_group_ids())
    )
  );

-- ── POLL VOTES ───────────────────────────────────────────────────────────────
ALTER TABLE public.poll_votes ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view poll votes" ON public.poll_votes;
CREATE POLICY "Members can view poll votes" ON public.poll_votes
  FOR SELECT USING (
    poll_id IN (
      SELECT p.id FROM public.polls p
      JOIN public.announcements a ON a.id = p.announcement_id
      WHERE a.group_id IN (SELECT public.get_my_group_ids())
    )
  );

DROP POLICY IF EXISTS "Members can cast votes" ON public.poll_votes;
CREATE POLICY "Members can cast votes" ON public.poll_votes
  FOR INSERT WITH CHECK (
    user_id = auth.uid()
    AND poll_id IN (
      SELECT p.id FROM public.polls p
      JOIN public.announcements a ON a.id = p.announcement_id
      WHERE a.group_id IN (SELECT public.get_my_member_group_ids())
        AND p.is_closed = false
    )
  );

-- upsert on poll_votes requires UPDATE permission too
DROP POLICY IF EXISTS "Members can change their vote" ON public.poll_votes;
CREATE POLICY "Members can change their vote" ON public.poll_votes
  FOR UPDATE USING (user_id = auth.uid());

DROP POLICY IF EXISTS "Members can retract their vote" ON public.poll_votes;
CREATE POLICY "Members can retract their vote" ON public.poll_votes
  FOR DELETE USING (user_id = auth.uid());

-- ── ACTIVITY LOG ─────────────────────────────────────────────────────────────
ALTER TABLE public.activity_log ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Members can view activity log" ON public.activity_log;
CREATE POLICY "Members can view activity log" ON public.activity_log
  FOR SELECT USING (group_id IN (SELECT public.get_my_group_ids()));

-- Activity log entries are written server-side (triggers/functions).
-- Allow authenticated users to insert so client-side events can be logged.
DROP POLICY IF EXISTS "Authenticated users can log activity" ON public.activity_log;
CREATE POLICY "Authenticated users can log activity" ON public.activity_log
  FOR INSERT WITH CHECK (
    auth.uid() IS NOT NULL
    AND group_id IN (SELECT public.get_my_group_ids())
  );
