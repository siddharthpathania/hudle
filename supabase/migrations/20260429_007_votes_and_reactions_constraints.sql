-- Update poll_votes constraint so multi-choice polls can have multiple votes
-- per (poll, user). Single-choice still enforced in application code by
-- replace-on-vote.
DO $$
DECLARE
  c TEXT;
BEGIN
  SELECT conname INTO c
  FROM pg_constraint
  WHERE conrelid = 'public.poll_votes'::regclass
    AND contype = 'u'
    AND array_length(conkey, 1) = 2
    AND EXISTS (
      SELECT 1 FROM unnest(conkey) k
      WHERE (SELECT attname FROM pg_attribute
             WHERE attrelid = 'public.poll_votes'::regclass
               AND attnum = k) = 'poll_id'
    )
    AND EXISTS (
      SELECT 1 FROM unnest(conkey) k
      WHERE (SELECT attname FROM pg_attribute
             WHERE attrelid = 'public.poll_votes'::regclass
               AND attnum = k) = 'user_id'
    );
  IF c IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.poll_votes DROP CONSTRAINT %I', c);
  END IF;
END $$;

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

DO $$
DECLARE
  c TEXT;
BEGIN
  SELECT conname INTO c
  FROM pg_constraint
  WHERE conrelid = 'public.announcement_reactions'::regclass
    AND contype = 'u'
    AND array_length(conkey, 1) = 3;
  IF c IS NOT NULL THEN
    EXECUTE format('ALTER TABLE public.announcement_reactions DROP CONSTRAINT %I', c);
  END IF;
END $$;

ALTER TABLE public.announcement_reactions
  DROP CONSTRAINT IF EXISTS announcement_reactions_announcement_user_unique;

ALTER TABLE public.announcement_reactions
  ADD CONSTRAINT announcement_reactions_announcement_user_unique
  UNIQUE (announcement_id, user_id);
