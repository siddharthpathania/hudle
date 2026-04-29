-- Update poll_votes constraint so multi-choice polls can have multiple votes
-- per (poll, user). Single-choice still enforced in application code by
-- replace-on-vote.
ALTER TABLE public.poll_votes
  DROP CONSTRAINT IF EXISTS poll_votes_poll_id_user_id_key;

ALTER TABLE public.poll_votes
  DROP CONSTRAINT IF EXISTS poll_votes_poll_user_option_unique;

ALTER TABLE public.poll_votes
  ADD CONSTRAINT poll_votes_poll_user_option_unique
  UNIQUE (poll_id, user_id, option_id);

-- One reaction per user per announcement: collapse any duplicates first,
-- then swap the unique constraint.
DELETE FROM public.announcement_reactions a
USING public.announcement_reactions b
WHERE a.announcement_id = b.announcement_id
  AND a.user_id = b.user_id
  AND a.id > b.id;

ALTER TABLE public.announcement_reactions
  DROP CONSTRAINT IF EXISTS announcement_reactions_announcement_id_user_id_emoji_key;

ALTER TABLE public.announcement_reactions
  DROP CONSTRAINT IF EXISTS announcement_reactions_announcement_user_unique;

ALTER TABLE public.announcement_reactions
  ADD CONSTRAINT announcement_reactions_announcement_user_unique
  UNIQUE (announcement_id, user_id);
