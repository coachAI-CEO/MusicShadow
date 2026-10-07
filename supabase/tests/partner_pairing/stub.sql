-- Minimal stand-in for the Supabase pieces the partner migration depends on.
-- Real Supabase provides auth.users, auth.uid() and the anon/authenticated roles; the app tables below
-- carry only the columns the partner functions read.
create role anon nologin;
create role authenticated nologin;

create schema auth;
create table auth.users (id uuid primary key default gen_random_uuid(), email text);
create function auth.uid() returns uuid language sql stable as $$
  select nullif(current_setting('request.jwt.claim.sub', true), '')::uuid
$$;
grant usage on schema auth to anon, authenticated;
grant execute on function auth.uid() to anon, authenticated;
grant usage on schema public to anon, authenticated;

create table public.song_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  song_title text, artist text, intensity integer, valence text,
  body_location text, somatic_type text, impulse text, pattern_report text, free_journal text,
  share_with_partner boolean not null default false,
  partner_share_level text default 'MINIMAL',
  created_at timestamptz not null default now()
);
create table public.shadow_insights (
  id uuid primary key default gen_random_uuid(),
  event_id uuid not null references public.song_events(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  wound_type text, protector_mode text, core_belief text, summary text, archetype text,
  created_at timestamptz not null default now()
);
