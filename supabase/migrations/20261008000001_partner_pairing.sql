-- Partner pairing and shared feed.
--
-- Two accounts pair with a short invite code (no email lookup, so nothing here reads auth.users data
-- beyond ids). Clients never read the partner tables or the partner's rows directly: every operation
-- is a security definer function that checks auth.uid() itself. The feed function returns only the
-- columns a share level allows, because row level security cannot hide individual columns.
--
-- Share levels (song_events.partner_share_level):
--   MINIMAL  song, artist, time, intensity, valence
--   SUMMARY  + body location, sensation, impulse, pattern note, and the AI reflection
--   FULL     + the free journal
-- The legacy partner_links table and the unapplied email-based policy are left alone.

-- ---------------------------------------------------------------------------------------------
-- Tables (no client access; functions below are the only way in)
-- ---------------------------------------------------------------------------------------------

create table if not exists public.partner_pairs (
  id          uuid primary key default gen_random_uuid(),
  created_at  timestamptz not null default now(),
  revoked_at  timestamptz,
  revoked_by  uuid references auth.users(id) on delete set null
);

create table if not exists public.partner_members (
  pair_id      uuid not null references public.partner_pairs(id) on delete cascade,
  user_id      uuid not null references auth.users(id) on delete cascade,
  display_name text check (display_name is null or char_length(display_name) between 1 and 40),
  active       boolean not null default true,
  primary key (pair_id, user_id)
);

-- A person can be in at most one active pair, whichever side of it they are on.
create unique index if not exists partner_members_one_active_pair
  on public.partner_members (user_id) where active;

create table if not exists public.partner_invites (
  id           uuid primary key default gen_random_uuid(),
  code         text not null unique check (code ~ '^[A-HJKMNP-Z2-9]{8}$'),
  inviter_id   uuid not null references auth.users(id) on delete cascade,
  inviter_name text check (inviter_name is null or char_length(inviter_name) between 1 and 40),
  created_at   timestamptz not null default now(),
  expires_at   timestamptz not null default now() + interval '48 hours',
  used_at      timestamptz,
  cancelled_at timestamptz
);
create index if not exists partner_invites_inviter_idx on public.partner_invites (inviter_id, created_at desc);

create table if not exists public.partner_invite_attempts (
  user_id uuid not null references auth.users(id) on delete cascade,
  at      timestamptz not null default now()
);
create index if not exists partner_invite_attempts_idx on public.partner_invite_attempts (user_id, at desc);

alter table public.partner_pairs           enable row level security;
alter table public.partner_members         enable row level security;
alter table public.partner_invites         enable row level security;
alter table public.partner_invite_attempts enable row level security;

revoke all on public.partner_pairs, public.partner_members, public.partner_invites, public.partner_invite_attempts
  from public, anon, authenticated;

-- Existing rows are not rewritten; the check applies to new and changed rows.
alter table public.song_events
  drop constraint if exists song_events_partner_share_level_check,
  add constraint song_events_partner_share_level_check
    check (partner_share_level is null or partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL')) not valid;

create index if not exists song_events_shared_feed_idx
  on public.song_events (user_id, created_at desc) where share_with_partner;

-- ---------------------------------------------------------------------------------------------
-- Helpers (not callable by clients)
-- ---------------------------------------------------------------------------------------------

-- 8 characters from an alphabet without 0, 1, I, L, O. Random bytes come from gen_random_uuid().
create or replace function public.partner_gen_code() returns text
language plpgsql volatile set search_path = public, pg_temp as $$
declare
  v_alphabet constant text := 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';  -- 31 characters
  v_out  text := '';
  v_bytes bytea;
  v_byte int;
  i int;
begin
  while char_length(v_out) < 8 loop
    v_bytes := uuid_send(gen_random_uuid());
    for i in 0..15 loop
      v_byte := get_byte(v_bytes, i);
      -- 248 = 31 * 8: drop the top bytes so every character is equally likely
      if v_byte < 248 and char_length(v_out) < 8 then
        v_out := v_out || substr(v_alphabet, (v_byte % 31) + 1, 1);
      end if;
    end loop;
  end loop;
  return v_out;
end $$;

create or replace function public.partner_other_member(p_user uuid) returns uuid
language sql stable security definer set search_path = public, pg_temp as $$
  select m2.user_id
  from public.partner_members m1
  join public.partner_members m2 on m2.pair_id = m1.pair_id and m2.user_id <> m1.user_id and m2.active
  where m1.user_id = p_user and m1.active
  limit 1
$$;

revoke all on function public.partner_gen_code(), public.partner_other_member(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------------------------------
-- Client functions
-- ---------------------------------------------------------------------------------------------

create or replace function public.create_partner_invite(p_name text default null)
returns table (invite_code text, invite_expires_at timestamptz)
language plpgsql security definer set search_path = public, pg_temp as $$
#variable_conflict use_column
declare
  v_uid  uuid := auth.uid();
  v_name text := left(nullif(btrim(coalesce(p_name, '')), ''), 40);
  v_code text;
  v_exp  timestamptz;
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;
  perform pg_advisory_xact_lock(hashtextextended('partner:' || v_uid::text, 0));

  if exists (select 1 from public.partner_members m where m.user_id = v_uid and m.active) then
    raise exception 'already_paired';
  end if;
  if (select count(*) from public.partner_invites i
      where i.inviter_id = v_uid and i.created_at > now() - interval '1 hour') >= 5 then
    raise exception 'rate_limited';
  end if;

  -- one open invite at a time
  update public.partner_invites i set cancelled_at = now()
  where i.inviter_id = v_uid and i.used_at is null and i.cancelled_at is null and i.expires_at > now();

  loop
    v_code := public.partner_gen_code();
    begin
      insert into public.partner_invites (code, inviter_id, inviter_name, expires_at)
      values (v_code, v_uid, v_name, now() + interval '48 hours')
      returning expires_at into v_exp;
      invite_code := v_code;
      invite_expires_at := v_exp;
      return next;
      return;
    exception when unique_violation then
      null;  -- extremely unlikely code collision: draw again
    end;
  end loop;
end $$;

-- Returns the new pair id, or null when the code does not work (wrong, used, cancelled, expired, or your
-- own). Failed tries are counted so codes cannot be guessed: 10 per hour per account.
create or replace function public.accept_partner_invite(p_code text, p_name text default null)
returns uuid
language plpgsql security definer set search_path = public, pg_temp as $$
#variable_conflict use_column
declare
  v_uid     uuid := auth.uid();
  v_name    text := left(nullif(btrim(coalesce(p_name, '')), ''), 40);
  v_code    text;
  v_inviter uuid;
  v_inv     public.partner_invites%rowtype;
  v_pair    uuid;
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;

  if (select count(*) from public.partner_invite_attempts a
      where a.user_id = v_uid and a.at > now() - interval '1 hour') >= 10 then
    raise exception 'rate_limited';
  end if;

  v_code := upper(regexp_replace(coalesce(p_code, ''), '[^A-Za-z0-9]', '', 'g'));
  select i.inviter_id into v_inviter from public.partner_invites i where i.code = v_code;

  if v_inviter is null then
    insert into public.partner_invite_attempts (user_id) values (v_uid);
    return null;
  end if;

  -- lock both people in a fixed order so two accepts cannot deadlock or double-pair
  perform pg_advisory_xact_lock(hashtextextended('partner:' || least(v_uid, v_inviter)::text, 0));
  if v_uid <> v_inviter then
    perform pg_advisory_xact_lock(hashtextextended('partner:' || greatest(v_uid, v_inviter)::text, 0));
  end if;

  select * into v_inv from public.partner_invites i where i.code = v_code for update;
  if not found or v_inv.used_at is not null or v_inv.cancelled_at is not null
     or v_inv.expires_at <= now() or v_inv.inviter_id = v_uid then
    insert into public.partner_invite_attempts (user_id) values (v_uid);
    return null;
  end if;

  if exists (select 1 from public.partner_members m where m.user_id = v_uid and m.active) then
    raise exception 'already_paired';
  end if;
  if exists (select 1 from public.partner_members m where m.user_id = v_inv.inviter_id and m.active) then
    return null;  -- they paired with someone else since inviting; not the caller's mistake
  end if;

  insert into public.partner_pairs default values returning id into v_pair;
  insert into public.partner_members (pair_id, user_id, display_name) values
    (v_pair, v_inv.inviter_id, v_inv.inviter_name),
    (v_pair, v_uid, v_name);
  update public.partner_invites i set used_at = now() where i.id = v_inv.id;
  return v_pair;
end $$;

-- state is 'none', 'invited' (you made a code that is still open) or 'paired'.
create or replace function public.partner_status()
returns table (state text, partner_name text, invite_code text, invite_expires_at timestamptz, paired_at timestamptz)
language plpgsql stable security definer set search_path = public, pg_temp as $$
#variable_conflict use_column
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;

  return query
    select 'paired'::text, other.display_name::text, null::text, null::timestamptz, p.created_at
    from public.partner_members me
    join public.partner_pairs p on p.id = me.pair_id
    join public.partner_members other on other.pair_id = me.pair_id and other.user_id <> me.user_id
    where me.user_id = v_uid and me.active and other.active
    limit 1;
  if found then return; end if;

  return query
    select 'invited'::text, null::text, i.code::text, i.expires_at, null::timestamptz
    from public.partner_invites i
    where i.inviter_id = v_uid and i.used_at is null and i.cancelled_at is null and i.expires_at > now()
    order by i.created_at desc
    limit 1;
  if found then return; end if;

  return query select 'none'::text, null::text, null::text, null::timestamptz, null::timestamptz;
end $$;

create or replace function public.cancel_partner_invite() returns void
language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null then raise exception 'not_signed_in'; end if;
  update public.partner_invites i set cancelled_at = now()
  where i.inviter_id = auth.uid() and i.used_at is null and i.cancelled_at is null;
end $$;

-- Either person can unlink. The partner's feed is empty from that moment, because the feed function
-- looks the pair up on every call.
create or replace function public.unlink_partner() returns boolean
language plpgsql security definer set search_path = public, pg_temp as $$
#variable_conflict use_column
declare
  v_uid  uuid := auth.uid();
  v_pair uuid;
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;
  perform pg_advisory_xact_lock(hashtextextended('partner:' || v_uid::text, 0));

  select m.pair_id into v_pair from public.partner_members m where m.user_id = v_uid and m.active;
  if v_pair is null then return false; end if;

  update public.partner_pairs p set revoked_at = now(), revoked_by = v_uid where p.id = v_pair;
  update public.partner_members m set active = false where m.pair_id = v_pair;
  return true;
end $$;

create or replace function public.partner_feed(p_limit int default 50, p_before timestamptz default null)
returns table (
  event_id uuid, created_at timestamptz, song_title text, artist text, intensity int, valence text,
  share_level text,
  body_location text, somatic_type text, impulse text, pattern_report text,
  free_journal text,
  archetype text, wound_type text, protector_mode text, core_belief text, summary text
)
language plpgsql stable security definer set search_path = public, pg_temp as $$
#variable_conflict use_column
declare
  v_uid     uuid := auth.uid();
  v_partner uuid;
  v_limit   int := greatest(1, least(coalesce(p_limit, 50), 100));
begin
  if v_uid is null then raise exception 'not_signed_in'; end if;

  v_partner := public.partner_other_member(v_uid);
  if v_partner is null then return; end if;

  return query
    select
      e.id,
      e.created_at::timestamptz,
      e.song_title::text,
      e.artist::text,
      e.intensity::int,
      e.valence::text,
      lvl.name,
      case when lvl.rank >= 2 then e.body_location::text end,
      case when lvl.rank >= 2 then e.somatic_type::text end,
      case when lvl.rank >= 2 then e.impulse::text end,
      case when lvl.rank >= 2 then e.pattern_report::text end,
      case when lvl.rank >= 3 then e.free_journal::text end,
      case when lvl.rank >= 2 then ins.archetype::text end,
      case when lvl.rank >= 2 then ins.wound_type::text end,
      case when lvl.rank >= 2 then ins.protector_mode::text end,
      case when lvl.rank >= 2 then ins.core_belief::text end,
      case when lvl.rank >= 2 then ins.summary::text end
    from public.song_events e
    cross join lateral (
      select case upper(coalesce(e.partner_share_level, 'MINIMAL'))
               when 'FULL' then 3 when 'SUMMARY' then 2 else 1 end as rank,
             case upper(coalesce(e.partner_share_level, 'MINIMAL'))
               when 'FULL' then 'FULL' when 'SUMMARY' then 'SUMMARY' else 'MINIMAL' end as name
    ) lvl
    left join lateral (
      select i.archetype, i.wound_type, i.protector_mode, i.core_belief, i.summary
      from public.shadow_insights i
      where i.event_id = e.id
      order by i.created_at desc
      limit 1
    ) ins on true
    where e.user_id = v_partner
      and e.share_with_partner is true
      and e.created_at < coalesce(p_before, 'infinity'::timestamptz)
    order by e.created_at desc
    limit v_limit;
end $$;

revoke all on function
  public.create_partner_invite(text), public.accept_partner_invite(text, text), public.partner_status(),
  public.cancel_partner_invite(), public.unlink_partner(), public.partner_feed(int, timestamptz)
  from public, anon;
grant execute on function
  public.create_partner_invite(text), public.accept_partner_invite(text, text), public.partner_status(),
  public.cancel_partner_invite(), public.unlink_partner(), public.partner_feed(int, timestamptz)
  to authenticated;
