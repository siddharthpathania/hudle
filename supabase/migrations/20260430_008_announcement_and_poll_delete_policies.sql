-- Migration 001 enabled RLS on `announcements` but never defined a FOR DELETE
-- policy, so every DELETE silently affected zero rows. Migration 004 only
-- added an admin-only delete policy on `polls`, locking authors out of
-- removing their own polls. This migration fixes both: authors can delete
-- their own announcements/polls, and group admins can also delete any
-- announcement or poll in groups they administer.

-- ── ANNOUNCEMENTS ──────────────────────────────────────────────────────
DROP POLICY IF EXISTS "Author or admin can delete announcements"
  ON public.announcements;
CREATE POLICY "Author or admin can delete announcements"
  ON public.announcements
  FOR DELETE
  USING (
    posted_by = auth.uid()
    OR group_id IN (SELECT public.get_my_admin_group_ids())
  );

-- ── POLLS ──────────────────────────────────────────────────────────────
-- Replace the admin-only delete policy from migration 004 with one that
-- also lets the announcement author remove their own poll.
DROP POLICY IF EXISTS "Admins can delete polls" ON public.polls;
DROP POLICY IF EXISTS "Author or admin can delete polls" ON public.polls;
CREATE POLICY "Author or admin can delete polls"
  ON public.polls
  FOR DELETE
  USING (
    announcement_id IN (
      SELECT id FROM public.announcements
      WHERE posted_by = auth.uid()
         OR group_id IN (SELECT public.get_my_admin_group_ids())
    )
  );
