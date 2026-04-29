-- Add allow_multiple column to polls table for single vs. multi-choice polls.
ALTER TABLE public.polls
  ADD COLUMN IF NOT EXISTS allow_multiple BOOLEAN NOT NULL DEFAULT FALSE;
