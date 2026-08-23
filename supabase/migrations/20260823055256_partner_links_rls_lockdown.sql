-- Migration: partner_links RLS lockdown
-- Purpose: partner_links currently has RLS disabled and grants SELECT/INSERT/UPDATE/DELETE
--          to anon + authenticated. Lock it down so only the owner can manage their own
--          partner relationship, and revoke anon entirely (partner_links is owner-only data).
-- Idempotent: safe to re-run.

-- 1. Enable RLS on partner_links (idempotent).
alter table public.partner_links enable row level security;

-- 2. Revoke anon privileges. partner_links is only meaningful for logged-in owners.
revoke all on public.partner_links from anon;

-- 3. Ensure authenticated has the base table privileges; RLS will gate row access.
grant select, insert, update, delete on public.partner_links to authenticated;

-- 4. Drop any old, partial, or wrongly-scoped policies so this migration is the single source of truth.
--    (pg_policies shows 0 today, but we drop defensively in case a future migration adds one.)
do $$
declare
  pol record;
begin
  for pol in
    select policyname from pg_policies
    where schemaname = 'public' and tablename = 'partner_links'
  loop
    execute format('drop policy %I on public.partner_links', pol.policyname);
  end loop;
end $$;

-- 5. Owner-only policy: a row is visible/writable only to the user identified by owner_user_id.
create policy partner_links_owner_select
  on public.partner_links
  for select to authenticated
  using (owner_user_id = auth.uid());

create policy partner_links_owner_insert
  on public.partner_links
  for insert to authenticated
  with check (owner_user_id = auth.uid());

create policy partner_links_owner_update
  on public.partner_links
  for update to authenticated
  using (owner_user_id = auth.uid())
  with check (owner_user_id = auth.uid());

create policy partner_links_owner_delete
  on public.partner_links
  for delete to authenticated
  using (owner_user_id = auth.uid());
