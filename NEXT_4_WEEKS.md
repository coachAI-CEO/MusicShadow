# Next 4 Weeks — Executable Plan

**Generated:** 2026-08-22
**Source:** Priorities section of `APP_MAP.md` §11
**Scope:** six items, sequenced so each builds on the previous one's output. **Phase 5 (Watch, Widgets, Siri, ML, iCloud, iPad-Mac) is explicitly out of scope** — defer until the partner feature is real.

Total estimated effort: **~22-32 hours of focused work**, spread over 4 calendar weeks assuming ~6-8 hours/week. Realistic if you treat this as your only project; aggressive if it isn't.

---

## Sequencing & dependencies

```
Week 1:  [0] Doc sync  ──┐
                          ├── enables
Week 1-2:[1] Migration 4 + invite RPC
              │
              ├── unlocks real partner read path
              │
Week 2:  [3] iOS polish (pull-to-refresh, swipe)  ← can start in parallel with [1]
              │
Week 3:  [2] MusicKit decision + (delete or wire)
              │
              ├── unblocks Phase 5 later
              │
Week 3-4:[4] Live-device QA decision (plan + unblock)
              │
Week 4:  [5] Pagination  ← only if [4] revealed user growth; otherwise defer
```

Why this order:
- **[0] before [1]** — writing the Migration 4 spec against outdated doc claims is a recipe for spec drift.
- **[1] before [3]** — partner RPC introduces a notification pattern; better to land that before you start touching the row-level UI.
- **[2] before any Phase 5]** — MusicKit has to be either real or gone before we add Siri shortcuts that would call into it.
- **[4] is a decision, not a feature.** You're either going to migrate to `@Observable` + SPM + get a device, or you're going to commit to static QA. Both are valid; doing neither is the worst option.
- **[5] is conditional.** Only worth doing if [4] reveals you actually have users at scale.

---

## [0] Doc sync — bring docs back to truth

**Why first:** every spec written this month will reference these docs. Stale = wrong spec = wrong work.

**Effort:** ~2 hours
**Risk:** none — documentation only
**Files to edit:**

| File | What to change |
|---|---|
| `PHASE_STATUS_CHECK.md` | Phase 1 status: mark Search ✅ (it's now in `AllTriggersView`); mark Milestone Celebrations ✅ (code ships it). Reorder counts accordingly. |
| `CURRENT_STATE_AND_MARKETING.md` Phase 1 section | Same: remove Pagination / Search / Pull-to-refresh from "✅ Phase 1 done" — Pagination isn't done, Pull-to-refresh only exists on PartnerFeedView. Move them under "Phase 2 partial" or remove them. |
| `CURRENT_STATE_AND_MARKETING.md` Archetypes section | Bump from "6 archetypes" to "10 archetypes" and list all 10 by name (the asset directories in `Assets.xcassets/Archetype*.imageset/` are the source of truth). |
| `CURRENT_STATE_AND_MARKETING.md` Partner Sharing section | Replace "Optional sharing of activations with partner — Privacy controls per activation — Summary sharing" with the **honest** description: "Settings UI for entering a partner email exists; the partner read path is not yet implemented at the database level." |

**Success criteria:**
- A new contributor reading these docs would not be misled into thinking pagination or partner-read work is shipped.
- All 10 archetypes are named in the marketing doc.

**Verification:** `git diff` shows only the four targeted edits. No code touched.

---

## [1] Migration 4 + partner invite RPC

**Goal:** a real, working partner sharing flow. End state: owner adds a partner by email → partner signs up or logs in → partner sees owner's shared activations via a real DB read path.

This is the highest-impact item because the partner feature is the only **product claim** in your App Store copy that the code cannot fulfill today.

**Effort:** 4-6 hours
**Risk:** medium — touches RLS policies, requires careful spec, and adds the first server-side business logic beyond `generate_insight`.

### 1a. Spec the partner data flow (1-1.5 hours)

Before writing SQL, write a one-page spec answering:

- **Invite lifecycle:** who initiates, who accepts, what happens to the `partner_links` row in each state (`pending` → `active` → `revoked`)?
- **Email matching:** is the partner match done by `auth.users.email = partner_links.partner_email` (current schema assumes this), or do you need an invite token?
- **`partner_share_level` semantics:** what does `MINIMAL` vs. `FULL` allow? Code currently ships these strings but no policy uses them. The spec needs to say "MINIMAL = title + intensity + valence" or similar.
- **Revocation:** what happens to a partner's cached reads when the owner revokes? (Cache invalidation is a separate concern; for now document that read-time RLS check is sufficient.)
- **What the partner sees:** if RLS opens up, does the partner see `free_journal`, `body_report`, etc.? Privacy column-by-column needs an answer.

Write this spec to `docs/partner-feature-spec.md` (create the `docs/` dir if it doesn't exist). The Migration 4 SQL will cite this doc.

### 1b. Migration 4 — partner read policy (1 hour)

After spec is signed off, write `supabase/migrations/<timestamp>_partner_read_policy.sql`. Pattern:

```sql
-- partner_links: enforce enum on status
alter table public.partner_links
  add constraint partner_links_status_check
  check (status in ('pending', 'active', 'revoked'));

-- song_events: partner SELECT, gated on email match + active link + share_with_partner
create policy song_events_partner_select
  on public.song_events for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.partner_links pl
      join auth.users u on u.email = pl.partner_email
      where pl.owner_user_id = song_events.user_id
        and u.id = auth.uid()
        and pl.status = 'active'
        and song_events.share_with_partner = true
    )
  );

-- shadow_insights: same shape, joined via event_id
create policy shadow_insights_partner_select
  on public.shadow_insights for select to authenticated
  using (
    user_id = auth.uid()
    or exists (
      select 1
      from public.song_events e
      join public.partner_links pl on pl.owner_user_id = e.user_id
      join auth.users u on u.email = pl.partner_email
      where e.id = shadow_insights.event_id
        and u.id = auth.uid()
        and pl.status = 'active'
        and e.share_with_partner = true
    )
  );
```

**Success criteria:**
- Migration applies cleanly to live DB.
- Re-run the cross-user test from tonight (throwaway user → insert event owned by user A → user B with active partner link to A's email can SELECT → user B without link returns 0 rows).
- `partner_links.status` cannot be set to anything other than `pending` / `active` / `revoked`.

### 1c. Wire `PartnerFeedView` to actually fetch (1-2 hours)

Once the policy exists, `PartnerFeedView.swift` needs a real query. Pattern (do NOT use `service_role` from the client — use the user's own JWT):

```swift
let events = try await client
  .from("song_events")
  .select("*, shadow_insights(*)")
  .eq("share_with_partner", value: true)
  .order("created_at", ascending: false)
  .limit(50)
  .execute()
  .value
```

RLS will filter server-side; client gets only rows the partner is authorized to see.

**Files to edit:** `Music Shadow/Views/PartnerFeedView.swift` (currently ~80 lines of stub UI).

### 1d. Wire `SettingsView` partner section (30 min)

The "Add partner" UI in `SettingsView` currently just shows an email field with no persistence. Wire it to upsert a `partner_links` row.

### 1e. Verify end-to-end (1 hour)

- Owner logs in, adds partner email.
- Sign up a new account with that email.
- Owner logs an activation with `share_with_partner = true`.
- Partner logs in, navigates to Partner feed, sees the activation.
- Partner with no link sees nothing.
- Partner whose link is `revoked` sees nothing.

Use the same throwaway-user pattern we used tonight for the RLS verification.

---

## [2] MusicKit decision — ship or kill

**Goal:** resolve the documentation/code drift on MusicKit. Either it works or it's gone.

**Effort:** 1-3 hours depending on outcome
**Risk:** medium if "ship it" — needs Apple Developer account, MusicKit capability, App Store review impact. Low if "kill it".

### Decision tree

**Option A — Ship it (1-3 hours, plus App Store review implications):**
1. Enable MusicKit capability in `Music Shadow.xcodeproj`.
2. Add `NSAppleMusicUsageDescription` to `Info.plist`.
3. Implement `MusicSearchService` to call `MusicCatalogSearchRequest`.
4. Wire results into the song-title field in `NewTriggerView`.
5. Submit a new build to App Store (MusicKit capability changes often trigger re-review).

**Option B — Kill it (30 minutes):**
1. Delete `Music Shadow/Services/MusicSearchService.swift`.
2. Update `MUSICKIT_SETUP.md` to a short "Why we removed this" note (or delete the file).
3. Update `CURRENT_STATE_AND_MARKETING.md` to remove MusicKit from any feature lists.
4. The `Migrate("Apple Watch", ...)` and Phase 5 mentions of MusicKit remain — those are correct aspirational doc.

**Recommendation:** ship only if you have an Apple Developer account ready and you're already shipping updates. Otherwise Option B — the dead-code-and-doc-fragment combo is a tax you pay every time someone reads the repo.

**Success criteria:** the words "MusicKit" no longer appear anywhere as a shipped feature that the user can't actually use.

---

## [3] iOS polish — pull-to-refresh + swipe actions on `AllTriggersView`

**Goal:** finish two items that the docs said were shipped but weren't.

**Effort:** ~1 hour
**Risk:** very low
**Files to edit:** `Music Shadow/AllTriggersView.swift` only.

### Pull-to-refresh
The `ScrollView` in `AllTriggersView` needs:
```swift
.refreshable { await viewModel.reload() }
```
…where `viewModel.reload()` is the function that re-fetches from Supabase. If there's no view model yet, you can wrap the existing fetch in `@MainActor` and call it. ~5 lines.

### Swipe actions
Each row needs `.swipeActions` with:
- **Delete** — calls the now-allowed owner DELETE on `song_events`. Note: client should `Prefer: count=exact` to distinguish "deleted" from "0 rows matched" (see tonight's session note).
- **Share** — `ShareLink` with the activation title + summary text.

```swift
.swipeActions(edge: .trailing) {
    Button(role: .destructive) { await delete(event) } label: {
        Label("Delete", systemImage: "trash")
    }
    Button { showShare = true } label: {
        Label("Share", systemImage: "square.and.arrow.up")
    }
    .tint(.blue)
}
```

**Success criteria:** pull-to-refresh works; swipe-delete confirms before destroying; swipe-share presents a `UIActivityViewController`.

**Verification:** run on simulator, confirm both gestures work; check the network panel shows the `DELETE` going out on swipe.

---

## [4] Live-device QA decision

**Goal:** explicitly decide and commit to a QA approach. Don't let this keep blocking you.

**Effort:** 30-60 min for the decision + plan; multi-day if you decide to migrate.
**Risk:** the *cost of not deciding* is the highest risk.

### Three options

**Option A — Migrate to `@Observable` + SPM + get a device.**
Steps:
1. Convert `ObservableObject` → `@Observable` (one model at a time, ~30 min each).
2. Add `Package.swift` with Supabase as a dep.
3. Connect a physical iPhone.
4. Run `gstack-ios-qa` against it.

Cost: 2-3 days of focused work. Benefit: full live-device QA + future gstack iOS skills become available.

**Option B — Accept static QA ceiling.**
Document the constraint, formalize the static QA process (we've been doing it), and stop expecting live QA.

Cost: 30 min to write the decision down. Benefit: clarity. Cost of doing nothing: continued re-asking every few weeks.

**Option C — Hybrid.** Run static QA on the desktop codebase + a manual smoke test on your personal device before each release.

Cost: 1 hour to write a `SMOKE_TEST_CHECKLIST.md` (which already exists but isn't kept current).

**Recommendation:** **Option B** unless you have a release scheduled. Option A only pays off if you're shipping frequently. Option C is a reasonable middle if you ship quarterly.

**Success criteria:** a one-paragraph statement of the QA approach exists at `docs/qa-approach.md` (or appended to `APP_MAP.md` if you prefer to keep it co-located).

---

## [5] Pagination on `AllTriggersView`

**Goal:** only do this if [4] revealed you have users at >100 activations each.

**Effort:** 1-2 hours
**Risk:** low — additive change
**Files to edit:** `Music Shadow/AllTriggersView.swift`, possibly `Utils/DataCache.swift`.

### Implementation outline

1. Add `@State private var hasMore = true` and `@State private var loadingMore = false`.
2. Add a `.range(from:to:)` parameter to the existing Supabase query.
3. Add an `onAppear` of the last row that triggers `loadMore()` if `hasMore`.
4. `loadMore()` issues the next page; if empty, set `hasMore = false`.

**Defer until:** you have a single user with >100 events *and* the existing `LOADING all events at once` is visibly slow. With 51 events today, there's no problem.

**Success criteria:** list scrolls smoothly to the bottom, "Loading more…" appears at the end, no duplicate rows.

---

## What this plan is NOT

- **Not a Phase 5 commitment.** Watch / Widgets / Siri / ML / iCloud / iPad-Mac remain deferred.
- **Not a marketing push.** Marketing lives in `MARKETING_DASHBOARD_PROJECT.md` and the `marketing-dashboard/` subdir — that's its own project.
- **Not a launch checklist.** You're past launch.

## Risks across all six items

| Risk | Mitigation |
|---|---|
| Doc sync drifts again | Add a CI check that fails if `PHASE_STATUS_CHECK.md` claims a feature the static audit doesn't see. (Heavy; defer.) |
| Partner spec written too loosely | The 1a spec must enumerate privacy at the column level, not just "partner sees activations". |
| Live QA decision never made | Treat [4] as blocking — don't start Phase 5 work until it's decided. |
| MusicKit App Store re-review surprise | Option B (kill it) avoids this entirely. |
| Migration 4 policy performance | The EXISTS join is O(N) per query — fine for personal-scale data, document it. |

---

## Tracking

Suggested commit convention for the next 4 weeks:

```
chore:   doc sync [APP_MAP §11 #0]
feat(db): partner read policy (Migration 4)
feat(db): partner_links.status enum constraint
feat(db): partner invite RPC
feat(client): wire PartnerFeedView to real query
feat(client): wire SettingsView partner section
chore:   smoke-tested partner feature end-to-end
docs:    remove or implement MusicKit  [APP_MAP §11 #2]
feat(ui): pull-to-refresh on AllTriggersView
feat(ui): swipe actions on AllTriggersView
docs:    QA approach decision  [APP_MAP §11 #4]
feat(ui): pagination in AllTriggersView  [APP_MAP §11 #5]
```

Each `feat` and `chore` is its own commit. Each group (`feat(db): partner ...` cluster) lands together as one PR-equivalent.
