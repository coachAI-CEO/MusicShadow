# Partner Feature — Technical Spec

**Status:** Draft
**Generated:** 2026-08-23
**Source:** `NEXT_4_WEEKS.md` item [1a]; `SettingsView`, `PartnerFeedView`, `partner_links` table, `song_events` columns
**Default decisions:** all five product questions answered with reasonable defaults (documented as such); override by editing this doc.

---

## Data Model

```
partner_links
  id             uuid PK (default gen_random_uuid())
  owner_user_id  uuid FK → auth.users(id), NOT NULL, UNIQUE
  partner_email  text NOT NULL
  status        text NOT NULL DEFAULT 'active'
                CHECK (status in ('pending', 'active', 'revoked'))
  created_at    timestamptz NOT NULL DEFAULT now()
```

```
song_events (relevant columns)
  share_with_partner  boolean NOT NULL DEFAULT false
  partner_share_level text     NOT NULL DEFAULT 'MINIMAL'
                       CHECK (partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL'))
  ... all other columns unchanged ...
```

`shadow_insights` is joined to `song_events` via `event_id`; no changes needed to its schema.

---

## Decisions (defaults, overridable)

### D1 — Invite lifecycle

**Decision:** No formal invite / acceptance flow. The link goes live immediately when the owner saves the email.

Rationale: simplest possible implementation that still provides real value. The partner must already have an account with that email address; no pending state needed for the MVP. If the email has no account, RLS will return 0 rows for that partner on every query, so nothing breaks — it just silently doesn't work.

Future improvement: add `pending` status + invite email flow + partner-facing "Accept your invitation" screen.

### D2 — partner_share_level semantics

| Level | Columns partner receives |
|---|---|
| `MINIMAL` | `song_title`, `artist`, `intensity`, `valence`, `created_at` |
| `SUMMARY` | `MINIMAL` + `body_location`, `somatic_type`, `impulse`, `pattern_report` |
| `FULL` | All columns except `user_id`, `ai_reason`, `source_type`, `source_context` |

`wound_type`, `core_belief`, `summary`, `suggested_practice` from the joined `shadow_insights` row are included in `SUMMARY` and `FULL` only.

`free_journal` is excluded from `MINIMAL` and `SUMMARY`; it's only in `FULL`.

### D3 — What the partner sees (full column map)

```
song_events — columns visible to partner (filtered by partner_share_level):
  id               always  (needed for navigation)
  song_title      MINIMAL+
  artist          MINIMAL+
  intensity       MINIMAL+
  valence         MINIMAL+
  created_at      MINIMAL+
  body_location   SUMMARY+
  somatic_type    SUMMARY+
  impulse         SUMMARY+
  pattern_report  SUMMARY+
  free_journal    FULL only
  (all other columns hidden from partner, including user_id)

shadow_insights — joined via event_id, visible to partner when:
  event.share_with_partner = true AND partner_share_level in ('SUMMARY', 'FULL')
  visible columns: wound_type, protector_mode, core_belief, summary, suggested_practice
```

### D4 — Revocation behavior

When the owner taps "Unlink partner" in Settings:

1. Delete the `partner_links` row (CASCADE deletes nothing — no FK from song_events).
2. The partner loses read access immediately (RLS checks `partner_links` rows at query time; no cache invalidation needed because RLS is evaluated on every SELECT).

No retroactive change to `song_events.share_with_partner` on previously shared rows. If the owner re-links the same partner later, all previously shared rows become readable again (assuming they're still `share_with_partner = true`).

### D5 — Partner has no account

If the partner email has no `auth.users` account:
- The `partner_links` row is created normally (D1: no pending state).
- The partner SELECT policy joins `auth.users.email` → no match → 0 rows returned.
- No error, no broken state. It just silently shows nothing.

---

## RLS Policies

### song_events

```sql
-- Owner: full access
create policy song_events_owner_all
  on song_events for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Partner: SELECT only, gated on email match + active link + share flag + level
create policy song_events_partner_select
  on song_events for select
  to authenticated
  using (
    user_id = auth.uid()
    or (
      share_with_partner = true
      and partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL')
      and exists (
        select 1
        from partner_links pl
        join auth.users u on u.email = pl.partner_email
        where pl.owner_user_id = song_events.user_id
          and u.id = auth.uid()
          and pl.status = 'active'
      )
    )
  );
```

Note: `partner_share_level in ('MINIMAL', 'SUMMARY', 'FULL')` is enforced server-side here. The column is already NOT NULL with a CHECK constraint; the policy's USING expression adds the enforcement for SELECT.

### shadow_insights

```sql
-- Owner: full access
create policy shadow_insights_owner_all
  on shadow_insights for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- Partner: SELECT, joined through song_events
-- Only for events where share_with_partner = true AND partner_share_level in ('SUMMARY', 'FULL')
create policy shadow_insights_partner_select
  on shadow_insights for select
  to authenticated
  using (
    user_id = auth.uid()
    or (
      exists (
        select 1
        from song_events e
        join partner_links pl on pl.owner_user_id = e.user_id
        join auth.users u on u.email = pl.partner_email
        where e.id = shadow_insights.event_id
          and u.id = auth.uid()
          and pl.status = 'active'
          and e.share_with_partner = true
          and e.partner_share_level in ('SUMMARY', 'FULL')
      )
    )
  );
```

---

## Client Flows

### Owner saves partner email (SettingsView)

```
1. Owner enters partner email in text field
2. Tap "Save partner"
   → Upsert partner_links row:
       INSERT ON CONFLICT (owner_user_id)
       DO UPDATE SET partner_email = EXCLUDED.partner_email, status = 'active'
   → Supabase upsert with user JWT (owner_user_id = auth.uid())
3. Show "Saved!" confirmation for 2s
```

**SQL (client calls this via PostgREST with user's JWT):**
```sql
upsert on partner_links (owner_user_id = auth.uid())
values (auth.uid(), trimmed_email, 'active')
```

### Partner views shared activations (PartnerFeedView)

```
1. Partner navigates to Partner Feed
2. Query: SELECT * FROM song_events
          WHERE share_with_partner = true
          ORDER BY created_at DESC
          LIMIT 50
   (RLS filters: only rows where partner_links join matches partner's auth.uid()
    AND partner_share_level is non-null)
3. For each row with partner_share_level in ('SUMMARY', 'FULL'):
   Query shadow_insights by event_id
4. Display with TriggerRow — some columns hidden based on level
```

### Owner unlinks partner (SettingsView)

```
1. Owner taps "Unlink partner"
2. DELETE FROM partner_links WHERE owner_user_id = auth.uid()
3. Clear savedPartnerEmail from UserDefaults
4. RLS immediately blocks partner's access on next query
```

---

## Out of Scope (MVP)

- Formal invite / acceptance flow (`pending` status never used in MVP)
- Email notifications to partner when a new row is shared
- Changing `partner_share_level` per-event in the logging UI (column exists but no UI to set it)
- Per-insight revocation (once shared, always shared until owner unlinks)
- Column-level redaction within a level (e.g. hiding `somatic_type` in SUMMARY)

---

## Verification Checklist

- [ ] Owner can save a partner email → `partner_links` row created
- [ ] Owner can unlink → `partner_links` row deleted
- [ ] Partner with no account sees empty feed
- [ ] Partner with active link sees only `share_with_partner = true` rows
- [ ] Partner sees MINIMAL columns for MINIMAL rows, SUMMARY+ for SUMMARY rows, all for FULL rows
- [ ] Partner sees `shadow_insights` for SUMMARY/FULL rows, not for MINIMAL
- [ ] Unlinking immediately blocks partner access (no cached data exposed)
- [ ] Owner still sees all their own data throughout
- [ ] `partner_links.status` cannot be set to anything outside `pending/active/revoked`
- [ ] `song_events.partner_share_level` cannot be set to anything outside `MINIMAL/SUMMARY/FULL`
