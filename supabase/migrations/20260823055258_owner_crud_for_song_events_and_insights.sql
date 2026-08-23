-- Migration: give owners a path to UPDATE/DELETE their own song_events and shadow_insights
-- Purpose: currently there are no DELETE policies on either table, and no UPDATE policy on
--          shadow_insights. This breaks both GDPR/CCPA-style right-to-delete via the API
--          and any future "edit my entry" feature. Add owner-only policies.
-- Idempotent: safe to re-run.

-- song_events DELETE
drop policy if exists song_events_delete_own on public.song_events;
create policy song_events_delete_own
  on public.song_events
  for delete to authenticated
  using (user_id = auth.uid());

-- shadow_insights UPDATE
drop policy if exists shadow_insights_update_own on public.shadow_insights;
create policy shadow_insights_update_own
  on public.shadow_insights
  for update to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- shadow_insights DELETE
drop policy if exists shadow_insights_delete_own on public.shadow_insights;
create policy shadow_insights_delete_own
  on public.shadow_insights
  for delete to authenticated
  using (user_id = auth.uid());
