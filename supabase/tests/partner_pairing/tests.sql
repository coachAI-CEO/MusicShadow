-- Tests for 20261008000001_partner_pairing.sql. Run with run.sh; any failed check aborts with its message.

create schema t;
grant usage on schema t to anon, authenticated;

create table t.state (k text primary key, v text);
grant all on t.state to authenticated;

create function t.alice() returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-00000000000a'::uuid $$;
create function t.bob()   returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-00000000000b'::uuid $$;
create function t.carol() returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-00000000000c'::uuid $$;
create function t.dave()  returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-00000000000d'::uuid $$;
create function t.erin()  returns uuid language sql immutable as $$ select '00000000-0000-0000-0000-00000000000e'::uuid $$;

create function t.login(u uuid) returns void language plpgsql as $$
begin
  perform set_config('request.jwt.claim.sub', u::text, false);
  execute 'set role authenticated';
end $$;

create function t.logout() returns void language plpgsql as $$
begin
  execute 'reset role';
  perform set_config('request.jwt.claim.sub', '', false);
end $$;

create function t.ok(cond boolean, msg text) returns void language plpgsql as $$
begin
  if cond is not true then raise exception 'FAILED: %', msg; end if;
end $$;

create function t.eq(actual anyelement, expected anyelement, msg text) returns void language plpgsql as $$
begin
  if actual is distinct from expected then
    raise exception 'FAILED: % (expected %, got %)', msg, expected, actual;
  end if;
end $$;

create function t.raises(q text, expected text) returns void language plpgsql as $$
declare v_msg text;
begin
  begin
    execute q;
  exception when others then
    v_msg := sqlerrm;
  end;
  if v_msg is null then raise exception 'FAILED: expected error "%" but succeeded: %', expected, q; end if;
  if position(expected in v_msg) = 0 then
    raise exception 'FAILED: expected error "%" but got "%" for: %', expected, v_msg, q;
  end if;
end $$;

grant execute on all functions in schema t to anon, authenticated;

insert into auth.users (id, email) values
  (t.alice(), 'alice@example.com'), (t.bob(), 'bob@example.com'),
  (t.carol(), 'carol@example.com'), (t.dave(), 'dave@example.com'), (t.erin(), 'erin@example.com');

-- ---------------------------------------------------------------------------------------------
\echo '1. clients cannot touch the partner tables or call anything unsigned'
select t.login(t.alice());
select t.raises('select * from public.partner_invites', 'permission denied');
select t.raises('select * from public.partner_members', 'permission denied');
select t.raises('select * from public.partner_pairs', 'permission denied');
select t.raises('select * from public.partner_invite_attempts', 'permission denied');
select t.raises('insert into public.partner_members (pair_id, user_id) values (gen_random_uuid(), t.alice())', 'permission denied');
select t.raises('select public.partner_gen_code()', 'permission denied');
select t.raises('select public.partner_other_member(t.bob())', 'permission denied');
select t.logout();

select t.logout();
set role anon;
select t.raises('select * from public.partner_status()', 'permission denied');
select t.raises('select public.create_partner_invite(''x'')', 'permission denied');
select t.raises('select * from public.partner_feed()', 'permission denied');
reset role;

-- signed-in role but no user id
set role authenticated;
select t.raises('select * from public.partner_status()', 'not_signed_in');
select t.raises('select * from public.partner_feed()', 'not_signed_in');
reset role;

-- ---------------------------------------------------------------------------------------------
\echo '2. creating an invite'
select t.login(t.alice());
insert into t.state select 'code1', invite_code from public.create_partner_invite('Alice');
select t.ok((select v from t.state where k = 'code1') ~ '^[A-HJKMNP-Z2-9]{8}$', 'code has 8 characters from the safe alphabet');
select t.eq((select state from public.partner_status()), 'invited', 'status is invited after creating a code');
select t.eq((select invite_code from public.partner_status()), (select v from t.state where k = 'code1'), 'status shows the open code');
select t.ok((select invite_expires_at from public.partner_status()) > now() + interval '47 hours', 'code lasts about 48 hours');

-- a second code replaces the first
insert into t.state select 'code2', invite_code from public.create_partner_invite('Alice');
select t.ok((select v from t.state where k = 'code2') <> (select v from t.state where k = 'code1'), 'a new code is a different code');
select t.logout();
select t.eq((select count(*)::int from public.partner_invites where inviter_id = t.alice() and cancelled_at is null), 1, 'only one open invite at a time');

-- creating codes is limited too: five an hour
select t.login(t.erin());
do $$
begin
  for i in 1..5 loop
    perform public.create_partner_invite('Erin');
  end loop;
end $$;
select t.raises('select * from public.create_partner_invite(''Erin'')', 'rate_limited');
select t.logout();

-- ---------------------------------------------------------------------------------------------
\echo '3. codes that must not work'
select t.login(t.bob());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code1')) is null, 'a replaced (cancelled) code is rejected');
select t.ok(public.accept_partner_invite('ZZZZZZZZ') is null, 'an unknown code is rejected');
select t.ok(public.accept_partner_invite('') is null, 'an empty code is rejected');
select t.ok(public.accept_partner_invite(null) is null, 'a null code is rejected');
select t.logout();
select t.eq((select count(*)::int from public.partner_invite_attempts where user_id = t.bob()), 4, 'each failed try is counted');

select t.login(t.alice());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code2')) is null, 'you cannot accept your own code');
select t.logout();

-- expired
update public.partner_invites set expires_at = now() - interval '1 minute'
  where code = (select v from t.state where k = 'code2');
select t.login(t.carol());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code2')) is null, 'an expired code is rejected');
select t.eq((select state from (select * from public.partner_status()) s), 'none', 'carol is still unpaired');
select t.logout();

-- ---------------------------------------------------------------------------------------------
\echo '4. guessing is throttled'
select t.login(t.dave());
do $$
begin
  for i in 1..10 loop
    perform public.accept_partner_invite('GUESS' || i);
  end loop;
end $$;
select t.logout();
-- a real, valid code now must not be usable by someone who has used up their tries
update public.partner_invites set cancelled_at = now() where inviter_id = t.alice();
select t.login(t.alice());
insert into t.state select 'code3', invite_code from public.create_partner_invite('Alice');
select t.logout();
select t.login(t.dave());
select t.raises('select public.accept_partner_invite(''' || (select v from t.state where k = 'code3') || ''')', 'rate_limited');
select t.logout();

-- ---------------------------------------------------------------------------------------------
\echo '5. pairing'
select t.login(t.bob());
-- lower case, spaces and dashes are forgiven
insert into t.state select 'pair1', public.accept_partner_invite(
  lower(substr((select v from t.state where k = 'code3'), 1, 4)) || ' - ' || substr((select v from t.state where k = 'code3'), 5), 'Bobby')::text;
select t.ok((select v from t.state where k = 'pair1') is not null, 'bob accepted alice''s code');
select t.eq((select state from public.partner_status()), 'paired', 'bob is paired');
select t.eq((select partner_name from public.partner_status()), 'Alice', 'bob sees the name alice chose');
select t.ok((select paired_at from public.partner_status()) is not null, 'paired_at is set');
select t.logout();
select t.login(t.alice());
select t.eq((select state from public.partner_status()), 'paired', 'alice is paired too');
select t.eq((select partner_name from public.partner_status()), 'Bobby', 'alice sees the name bob chose');
select t.raises('select * from public.create_partner_invite(''x'')', 'already_paired');
select t.logout();

-- the code cannot be used twice
select t.login(t.carol());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code3')) is null, 'a used code is rejected');
select t.logout();

-- someone already paired cannot join another pair
select t.login(t.dave());
select t.logout();
update public.partner_invite_attempts set at = now() - interval '2 hours' where user_id = t.dave();
select t.login(t.dave());
insert into t.state select 'code4', invite_code from public.create_partner_invite('Dave');
select t.logout();
select t.login(t.bob());
select t.raises('select public.accept_partner_invite(''' || (select v from t.state where k = 'code4') || ''')', 'already_paired');
select t.logout();

-- the database itself refuses a second active pair for one person
select t.raises('insert into public.partner_members (pair_id, user_id) values ((select id from public.partner_pairs limit 1), t.alice())', 'duplicate key');
do $$
declare v_pair uuid;
begin
  insert into public.partner_pairs default values returning id into v_pair;
  begin
    insert into public.partner_members (pair_id, user_id) values (v_pair, t.alice());
    raise exception 'FAILED: alice joined a second active pair';
  exception when unique_violation then null;
  end;
  delete from public.partner_pairs where id = v_pair;
end $$;

-- ---------------------------------------------------------------------------------------------
\echo '6. the feed shows only what was shared, at the level it was shared'
insert into public.song_events (id, user_id, song_title, artist, intensity, valence, body_location, somatic_type, impulse, pattern_report, free_journal, share_with_partner, partner_share_level, created_at) values
  ('10000000-0000-0000-0000-000000000001', t.alice(), 'Minimal Song', 'A1', 3, 'shadow', 'chest', 'tight', 'cry',  'minimal pattern', 'minimal journal', true,  'MINIMAL', now() - interval '3 hours'),
  ('10000000-0000-0000-0000-000000000002', t.alice(), 'Summary Song', 'A2', 5, 'positive', 'throat', 'urgeCry', 'cling', 'summary pattern', 'summary journal', true,  'SUMMARY', now() - interval '2 hours'),
  ('10000000-0000-0000-0000-000000000003', t.alice(), 'Full Song',    'A3', 7, 'shadow', 'gut', 'heavy', 'hide', 'full pattern', 'full journal', true,  'FULL',    now() - interval '1 hours'),
  ('10000000-0000-0000-0000-000000000004', t.alice(), 'Private Song', 'A4', 9, 'shadow', 'chest', 'tight', 'cry', 'private pattern', 'private journal', false, 'FULL', now()),
  ('10000000-0000-0000-0000-000000000005', t.alice(), 'Null Level',   'A5', 2, 'shadow', 'arms', 'buzzing', 'scream', 'null pattern', 'null journal', true, null, now() - interval '4 hours'),
  ('20000000-0000-0000-0000-000000000001', t.carol(), 'Carol Song',   'C1', 4, 'shadow', 'chest', 'tight', 'cry', 'carol pattern', 'carol journal', true, 'FULL', now());
insert into public.shadow_insights (event_id, user_id, wound_type, protector_mode, core_belief, summary, archetype, created_at) values
  ('10000000-0000-0000-0000-000000000001', t.alice(), 'w1', 'p1', 'b1', 's1', 'The Ghost', now() - interval '3 hours'),
  ('10000000-0000-0000-0000-000000000002', t.alice(), 'w2-old', 'p2', 'b2', 's2-old', 'The Maker', now() - interval '3 hours'),
  ('10000000-0000-0000-0000-000000000002', t.alice(), 'w2', 'p2', 'b2', 's2', 'The Open Heart', now() - interval '1 hours'),
  ('10000000-0000-0000-0000-000000000003', t.alice(), 'w3', 'p3', 'b3', 's3', 'The Protector', now());

select t.login(t.bob());
select t.eq((select count(*)::int from public.partner_feed()), 4, 'bob sees alice''s four shared events and no others');
select t.eq((select array_agg(song_title order by created_at desc) from public.partner_feed()),
            array['Full Song','Summary Song','Minimal Song','Null Level'], 'newest first, private and carol''s events excluded');

-- MINIMAL: nothing beyond song, time, intensity, valence
select t.ok((select song_title = 'Minimal Song' and artist = 'A1' and intensity = 3 and valence = 'shadow' and share_level = 'MINIMAL'
             from public.partner_feed() where song_title = 'Minimal Song'), 'minimal row carries the basics');
select t.ok((select body_location is null and somatic_type is null and impulse is null and pattern_report is null
                    and free_journal is null and archetype is null and wound_type is null and protector_mode is null
                    and core_belief is null and summary is null
             from public.partner_feed() where song_title = 'Minimal Song'), 'minimal row hides every private column');

-- SUMMARY: body, pattern and the latest reflection, but never the journal
select t.ok((select body_location = 'throat' and somatic_type = 'urgeCry' and impulse = 'cling' and pattern_report = 'summary pattern'
             from public.partner_feed() where song_title = 'Summary Song'), 'summary row shows body and pattern');
select t.ok((select archetype = 'The Open Heart' and wound_type = 'w2' and summary = 's2'
             from public.partner_feed() where song_title = 'Summary Song'), 'summary row uses the newest reflection');
select t.ok((select free_journal is null from public.partner_feed() where song_title = 'Summary Song'), 'summary row hides the journal');

-- FULL: everything
select t.ok((select free_journal = 'full journal' and archetype = 'The Protector' and share_level = 'FULL'
             from public.partner_feed() where song_title = 'Full Song'), 'full row shows the journal');

-- a missing level is treated as the most private one
select t.ok((select share_level = 'MINIMAL' and free_journal is null and pattern_report is null
             from public.partner_feed() where song_title = 'Null Level'), 'null level behaves as minimal');

-- columns that identify the owner or other people never appear
select t.ok(not exists (select 1 from information_schema.columns where table_name = 'partner_feed'), 'feed is a function, not a table');
select t.logout();

-- paging and limits
select t.login(t.bob());
select t.eq((select count(*)::int from public.partner_feed(1)), 1, 'limit 1 returns one row');
select t.eq((select count(*)::int from public.partner_feed(0)), 1, 'limit 0 is raised to 1');
select t.eq((select count(*)::int from public.partner_feed(100000)), 4, 'a huge limit is capped and still works');
select t.eq((select count(*)::int from public.partner_feed(50, now() - interval '150 minutes')), 2, 'p_before pages older events');
select t.logout();

-- sharing is one way: bob shared nothing, so alice sees nothing
select t.login(t.alice());
select t.eq((select count(*)::int from public.partner_feed()), 0, 'alice sees nothing because bob shared nothing');
select t.logout();

-- unpaired people see nothing, whatever others shared
select t.login(t.carol());
select t.eq((select count(*)::int from public.partner_feed()), 0, 'carol (unpaired) sees nothing');
select t.logout();

-- switching an event off removes it at once
update public.song_events set share_with_partner = false where id = '10000000-0000-0000-0000-000000000003';
select t.login(t.bob());
select t.eq((select count(*)::int from public.partner_feed()), 3, 'unsharing an event removes it from the feed');
select t.logout();
update public.song_events set share_with_partner = true where id = '10000000-0000-0000-0000-000000000003';

-- lowering the level takes effect at once
update public.song_events set partner_share_level = 'MINIMAL' where id = '10000000-0000-0000-0000-000000000003';
select t.login(t.bob());
select t.ok((select free_journal is null and summary is null from public.partner_feed() where song_title = 'Full Song'), 'lowering the level hides the extra fields at once');
select t.logout();
update public.song_events set partner_share_level = 'FULL' where id = '10000000-0000-0000-0000-000000000003';

-- ---------------------------------------------------------------------------------------------
\echo '7. unlinking'
select t.login(t.bob());
select t.eq(public.unlink_partner(), true, 'bob unlinks');
select t.eq((select count(*)::int from public.partner_feed()), 0, 'bob''s feed is empty at once');
select t.eq((select state from public.partner_status()), 'none', 'bob is unpaired');
select t.eq(public.unlink_partner(), false, 'unlinking twice does nothing');
select t.logout();
select t.login(t.alice());
select t.eq((select state from public.partner_status()), 'none', 'alice is unpaired too');
select t.logout();

-- either side can re-pair afterwards, with anyone
select t.login(t.alice());
insert into t.state select 'code5', invite_code from public.create_partner_invite('Alice');
select t.logout();
select t.login(t.carol());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code5'), 'Carol') is not null, 'alice can pair with carol after unlinking bob');
select t.eq((select count(*)::int from public.partner_feed()), 4, 'carol now sees alice''s shared events');
select t.logout();
select t.login(t.bob());
select t.eq((select count(*)::int from public.partner_feed()), 0, 'bob still sees nothing');
select t.logout();

-- the other side can unlink too
select t.login(t.alice());
select t.eq(public.unlink_partner(), true, 'alice can unlink carol');
select t.logout();
select t.login(t.carol());
select t.eq((select count(*)::int from public.partner_feed()), 0, 'carol''s feed is empty after alice unlinks');
select t.logout();

-- ---------------------------------------------------------------------------------------------
\echo '8. cancelling an invite and account deletion'
select t.login(t.dave());
select t.eq((select state from public.partner_status()), 'invited', 'dave still has his open code');
select public.cancel_partner_invite();
select t.eq((select state from public.partner_status()), 'none', 'cancelling closes the invite');
select t.logout();

select t.login(t.alice());
insert into t.state select 'code6', invite_code from public.create_partner_invite('Alice');
select t.logout();
select t.login(t.bob());
select t.ok(public.accept_partner_invite((select v from t.state where k = 'code6')) is not null, 'bob pairs with alice again');
select t.logout();
delete from auth.users where id = t.alice();
select t.eq((select count(*)::int from public.partner_members where user_id = t.alice()), 0, 'deleting an account removes its membership');
select t.login(t.bob());
select t.eq((select count(*)::int from public.partner_feed()), 0, 'bob sees nothing once alice is gone');
select t.logout();

\echo 'all checks passed'
