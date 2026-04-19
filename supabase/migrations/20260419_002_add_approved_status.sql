-- Add 'approved' to the announcement_status enum.
-- The Flutter app uses 'approved' as the post-moderation state;
-- the initial schema only had 'published' which is never used.
-- We keep 'published' for forward compatibility but add 'approved'.

ALTER TYPE public.announcement_status ADD VALUE IF NOT EXISTS 'approved';
