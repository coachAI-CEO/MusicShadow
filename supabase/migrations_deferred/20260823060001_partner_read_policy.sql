-- DEFERRED. DO NOT APPLY AS WRITTEN.
-- Moved out of supabase/migrations/ on 2026-10-07 after the /autoplan review
-- (docs/send-receive-plan.md, "Final gate overrides"). Build item 1 (partner read path) is
-- unscheduled for v1; the token-link send flow replaces it.
-- Danger: section 3 creates `auth_users_authenticated_read` (SELECT using (true) on auth.users
-- for role authenticated), which exposes every user's email to every signed-in user.
-- The header below says "Applied: 2026-08-23" but this file was never tracked or confirmed applied;
-- check the live database before assuming anything. If item 1 is revived, replace that policy with a
-- security-definer function or a JWT email claim, and renumber this file so it sorts after the
-- newest migration (or push with --include-all).
--
-- Migration: partner read policy (NEXT_4_WEEKS item [1b])
-- Purpose: enables the partner sharing feature by opening a cross-user SELECT path
--          gated on email matching via partner_links. Also adds CHECK constraints
--          to enforce valid status and partner_share_level values.
-- Docs:   docs/partner-feature-spec.md
-- Applied: 2026-08-23
-- Idempotent: safe to re-run (DO NOTHING blocks are idempotent by design)

begin;

-- 1. Enforce partner_links.status as an enum
--    Before this, status was free text. Any value was accepted.
alter table public.partner_links
  drop constraint if exists partner_links_status_check,
  add constraint partner_links_status_check
    check (status in ('pending', 'active', 'revoked'));

-- 2. Enforce song_events.partner_share_level as an enum
--    Existing column already has a default of 'MINIMAL'; this adds DB-level enforcement.
alter table public.song_events
  drop constraint if exists song_events_partner_share_level_check,
  add constraint song_events_partner_share_level_check
    check (partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL'));

-- 3. auth.users — permissive SELECT for authenticated
--    Required because partner SELECT policies on song_events/shadow_insights join
--    auth.users via (u.email = pl.partner_email). Without this, the email→uuid
--    lookup in the EXISTS subquery fails for any user other than yourself.
--    Safe: auth.users row only contains email/metadata, not secrets. Proper row
--    access is still enforced by RLS on partner_links, song_events, etc.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'auth'
      and tablename = 'users'
      and policyname = 'auth_users_authenticated_read'
  ) then
    create policy auth_users_authenticated_read on auth.users
      for select to authenticated using (true);
  end if;
end $$;

-- 4. partner_links — partner SELECT policy
--    Allows a partner to see their own partner_links row (partner_email, status, etc.)
--    needed by the EXISTS subquery in the song_events partner policy.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'partner_links'
      and policyname = 'partner_links_partner_select'
  ) then
    create policy partner_links_partner_select on public.partner_links
      for select to authenticated
      using (
        exists (
          select 1 from auth.users u
          where u.email = partner_links.partner_email
            and u.id = auth.uid()
        )
        or owner_user_id = auth.uid()
      );
  end if;
end $$;

-- 5. song_events — add partner SELECT policy
--    RLS evaluates USING expression on every SELECT; auth.uid() OR the partner
--    EXISTS subquery must be true for the row to be returned.
--    partner_share_level check is server-side; the column is already NOT NULL.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'song_events'
      and policyname = 'song_events_partner_select'
  ) then
    create policy song_events_partner_select
      on public.song_events
      for select
      to authenticated
      using (
        user_id = auth.uid()
        or (
          share_with_partner = true
          and partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL')
          and exists (
            select 1
            from public.partner_links pl
            join auth.users u on u.email = pl.partner_email
            where pl.owner_user_id = song_events.user_id
              and u.id = auth.uid()
              and pl.status = 'active'
          )
        )
      );
  end if;
end $$;

-- 6. shadow_insights — add partner SELECT policy
--    Partners access insights through the event row: event must be share_with_partner=true
--    AND partner_share_level in ('SUMMARY', 'FULL') — MINIMAL rows do NOT surface insights.
do $$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'shadow_insights'
      and policyname = 'shadow_insights_partner_select'
  ) then
    create policy shadow_insights_partner_select
      on public.shadow_insights
      for select
      to authenticated
      using (
        user_id = auth.uid()
        or (
          exists (
            select 1
            from public.song_events e
            join public.partner_links pl on pl.owner_user_id = e.user_id
            join auth.users u on u.email = pl.partner_email
            where e.id = shadow_insights.event_id
              and u.id = auth.uid()
              and pl.status = 'active'
              and e.share_with_partner = true
              and e.partner_share_level in ('SUMMARY', 'FULL')
          )
        )
      );
  end if;
end $$;

commit;
