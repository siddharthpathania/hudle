-- Add FCM push token column to users so the Edge Function can look up
-- a recipient's device token when sending task-assigned notifications.
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
