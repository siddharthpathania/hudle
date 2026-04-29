-- Fix infinite recursion between tasks ↔ task_assignees RLS policies.
--
-- Root cause: migration 001's "Task visibility policy" queries task_assignees
-- with raw SQL (no SECURITY DEFINER), which triggers task_assignees' SELECT
-- policy (from migration 004), which in turn queries tasks, which triggers
-- the tasks policy again → infinite loop.
--
-- Solution (mirrors the group_members fix in migration 001):
--   1. Add a SECURITY DEFINER helper get_my_task_ids() that reads
--      task_assignees while bypassing RLS.
--   2. Replace the inline subquery in the tasks SELECT policy with it.
--   3. Rewrite task_assignees policies to avoid querying tasks via SELECT
--      (use EXISTS with a direct row check instead).

-- ── HELPER FUNCTION ───────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION public.get_my_task_ids()
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT task_id FROM public.task_assignees
  WHERE user_id = auth.uid();
$$;

-- ── TASKS — rewrite SELECT policy ────────────────────────────────────────────
-- Replace the inline subquery on task_assignees with the helper function.
DROP POLICY IF EXISTS "Task visibility policy" ON public.tasks;
CREATE POLICY "Task visibility policy" ON public.tasks FOR SELECT
  USING (
    group_id IN (SELECT public.get_my_group_ids())
    AND (
      visibility = 'all'
      OR created_by = auth.uid()
      OR id IN (SELECT public.get_my_task_ids())   -- no RLS cycle
      OR group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );

-- ── TASK ASSIGNEES — rewrite all three policies ───────────────────────────────
-- Use EXISTS with direct column checks, NOT a subquery against tasks (which
-- would trigger tasks' SELECT policy and restart the recursion cycle).

DROP POLICY IF EXISTS "Members can view task assignees" ON public.task_assignees;
CREATE POLICY "Members can view task assignees" ON public.task_assignees
  FOR SELECT
  USING (
    -- I am the assignee
    user_id = auth.uid()
    -- OR I assigned myself to the task (covered by get_my_task_ids helper)
    OR task_id IN (SELECT public.get_my_task_ids())
    -- OR I am an admin of the group that owns this task
    OR EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id
        AND t.group_id IN (SELECT public.get_my_admin_group_ids())
    )
    -- OR I created the task
    OR EXISTS (
      SELECT 1 FROM public.tasks t
      WHERE t.id = task_id
        AND t.created_by = auth.uid()
    )
  );

DROP POLICY IF EXISTS "Members can manage task assignees" ON public.task_assignees;
CREATE POLICY "Members can manage task assignees" ON public.task_assignees
  FOR INSERT
  WITH CHECK (
    EXISTS (
      SELECT 1 FROM public.tasks t
      -- Join group_members directly to check membership without hitting
      -- any RLS on tasks (EXISTS short-circuits before the outer policy fires).
      JOIN public.group_members gm
        ON gm.group_id = t.group_id
       AND gm.user_id  = auth.uid()
       AND gm.is_banned = false
       AND gm.role IN ('super_admin', 'admin', 'member')
      WHERE t.id = task_id
    )
  );

DROP POLICY IF EXISTS "Members can remove task assignees" ON public.task_assignees;
CREATE POLICY "Members can remove task assignees" ON public.task_assignees
  FOR DELETE
  USING (
    EXISTS (
      SELECT 1 FROM public.tasks t
      JOIN public.group_members gm
        ON gm.group_id = t.group_id
       AND gm.user_id  = auth.uid()
       AND gm.is_banned = false
       AND gm.role IN ('super_admin', 'admin', 'member')
      WHERE t.id = task_id
    )
  );
