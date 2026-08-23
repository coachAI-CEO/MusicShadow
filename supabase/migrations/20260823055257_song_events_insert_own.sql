-- Migration: tighten song_events INSERT policy
-- Purpose: the existing policy has an empty with_check (effectively WITH CHECK (true)),
--          which lets any authenticated user insert rows attributed to any user_id.
--          Replace it with a strict user_id = auth.uid() check.
-- Idempotent: safe to re-run.

-- Drop the existing permissive policy. We use the name we observed via pg_policies.
drop policy if exists "user can insert own events" on public.song_events;

create policy song_events_insert_own
  on public.song_events
  for insert to authenticated
  with check (user_id = auth.uid());
