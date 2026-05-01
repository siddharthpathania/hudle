-- Migration 001 added SELECT and INSERT policies on group_members but never
-- added UPDATE or DELETE, so role changes, banning, and removing members
-- were silently blocked by RLS. This migration adds those two policies.

ALTER TABLE public.group_members ENABLE ROW LEVEL SECURITY;

-- Admins can update role and is_banned for any non-super-admin member in
-- their groups. (Preventing self-demotion is enforced in the app layer.)
DROP POLICY IF EXISTS "Admins can update group members" ON public.group_members;
CREATE POLICY "Admins can update group members"
  ON public.group_members
  FOR UPDATE
  USING (group_id IN (SELECT public.get_my_admin_group_ids()));

-- Any member can leave (delete their own row); admins can remove anyone.
DROP POLICY IF EXISTS "Admins can remove group members" ON public.group_members;
CREATE POLICY "Admins can remove group members"
  ON public.group_members
  FOR DELETE
  USING (
    user_id = auth.uid()
    OR group_id IN (SELECT public.get_my_admin_group_ids())
  );
