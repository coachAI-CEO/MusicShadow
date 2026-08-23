# Music Shadow — The Documented App Map vs. The Actual App

**Generated:** 2026-08-22 (after the static-QA pass, RLS lockdown, and cleanup)
**Sources:** every `.md` in the repo (`PHASE_*`, `CURRENT_STATE_*`, `NEXT_STEPS_*`, `AUDIT_LATEST_FUNCTIONS.md`), all Swift source, the Supabase schema, the edge function, `git log`.

This is a single source of truth for "what is the app right now." It separates three things:
- **What the docs claim** (the marketing / phase plans say)
- **What the code does** (the actual Swift + Supabase)
- **Where the gap is** (claimed but missing, or built but undocumented)

---

## 1. The product, in one paragraph

Music Shadow is a private, single-user **iOS shadow-work journal**. You log a song the moment it hits you — title, artist, time-in-song, intensity, body location, free journal. The app optionally fetches lyrics at the timestamp you logged, then calls an AI (Gemini, via a Supabase Edge Function) to write a reflection tied to that exact moment and lyric. Over time you see patterns (artist, body location, time of day, intensity trends), get assigned a "shadow archetype" (Abandoned Child, Lone Wolf, Overachiever, Invisible One, Mask, Ghost, Buried Fire, Defective One, Protector, Performer — 10 in code, 6 named in docs), and can optionally share individual activations with a "partner" by email.

**Tagline (from docs):** *"Every song that hits you is a map to your shadow."*

---

## 2. Stack — what's actually in the build

| Layer | Tech | Source |
|---|---|---|
| UI | SwiftUI (iOS), `@StateObject` / `ObservableObject` (no `@Observable` migration) | every `*.swift` |
| Backend | Supabase (Postgres + Auth + Edge Functions) | `supabase/migrations/`, `supabase/functions/` |
| AI | Google Gemini (primary + fallback models in env) | `supabase/functions/generate_insight/index.ts` |
| Lyrics | LRCLIB public API (no key, sync fetch in edge function) | in the same edge fn |
| Local store | `UserDefaults` (`@AppStorage`) + in-memory `DataCache` | `Utils/DataCache.swift`, `Music_ShadowApp.swift` |
| Music lookup | `MusicSearchService.swift` — **disabled / stub** (no MusicKit auth wired) | grep |
| Bundle size | ~11.6k lines of Swift across 47 files | `find ... | xargs wc -l` |

No SPM dependencies beyond the Supabase Swift SDK (`import Supabase`).

---

## 3. Architecture — entry, navigation, screens

### 3.1 App entry

`Music_ShadowApp.swift` — 19 lines total:

```swift
@main
struct Music_ShadowApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false
    var body: some Scene {
        WindowGroup {
            AuthView()
                .onAppear { if !hasSeenOnboarding { showOnboarding = true } }
                .fullScreenCover(isPresented: $showOnboarding) { OnboardingView() }
        }
    }
}
```

There is **no `TabView` in the main app.** Navigation is a single `NavigationStack` rooted at `ContentView` (Dashboard), with deep-links via string keys (`"patterns"`, `"allTriggers"`, `"songAnalytics"`, `"archetypes"`, `"timeline"`) and modal sheets for new-trigger logging, settings, and onboarding.

### 3.2 Screen map (live, from code)

```
Music_ShadowApp
├── AuthView (sign-in / sign-up)
├── OnboardingView (first-launch, full-screen sheet, 4 tabs internally)
└── ContentView  ── Dashboard (root of NavigationStack)
    ├── NavigationLink → SettingsView
    │   ├── HowAIWorksView
    │   ├── PrivacyAndDataView
    │   ├── PrivacyPolicyView
    │   ├── DeleteAccountView
    │   └── ExportDataView
    ├── navigationDestination("patterns") → PatternsView
    ├── navigationDestination("allTriggers") → AllTriggersView
    │   └── per-row → TriggerDetailView
    ├── navigationDestination("songAnalytics") → SongAnalyticsView
    ├── navigationDestination("archetypes") → ArchetypesView
    │   └── per-archetype → ShadowArchetypeDetailView
    │   └── learn-more → ShadowArchetypeLearnMoreView
    ├── navigationDestination("timeline") → TriggerTimelineView
    │   └── per-event → TriggerDetailView
    ├── sheet(New Trigger) → NewTriggerView (3-step form)
    │   └── on save → result sheet polling for AI insight
    └── Hero card → ShadowArchetypeDetailView (primary archetype)
```

### 3.3 Partner feature (separate entry)

`PartnerFeedView` is **reachable as a separate push from Settings** (not from the main nav stack). It is **a stub** — empty list, hard-coded title. Confirmed live in `Views/PartnerFeedView.swift`. Per-row destination `PartnerTriggerDetailView` exists but is unreachable in practice because the data path is broken (see §7).

---

## 4. Data model — actual live schema

| Table | Purpose | Key columns |
|---|---|---|
| `song_events` | One row per activation | `id`, `user_id`, `song_title`, `artist`, `intensity`, `body_location`, `somatic_type`, `impulse`, `body_report`, `impulse_report`, `block_report`, `echo_report`, `belief_report`, `pattern_report`, `interruption_directive`, `free_journal`, `timestamp_seconds`, `valence`, `share_with_partner`, `partner_share_level`, `source_type`, `source_context`, `ai_reason`, `normalized_*`, `created_at` |
| `shadow_insights` | AI output | `id`, `event_id`, `user_id`, `wound_type`, `protector_mode`, `age_range`, `nervous_system_state`, `nervous_system`, `core_belief`, `summary`, `suggested_practice`, `created_at` |
| `partner_links` | Owner ↔ partner email | `id`, `owner_user_id` (FK→auth.users, UNIQUE), `partner_email`, `status` (free text, default `'active'`), `created_at` |

**No `profiles` / `users` table.** Identity lives in `auth.users` (Supabase GoTrue).

Total rows in production today: **51 `song_events`**, **0–1 `shadow_insights`**, **1 `partner_links`** (the seeded one from your earlier work).

---

## 5. RLS — current state, after tonight's lockdown

| Table | SELECT | INSERT | UPDATE | DELETE | Anon grants |
|---|---|---|---|---|---|
| `song_events` | ✅ `(user_id = auth.uid())` | ✅ `(user_id = auth.uid())` *(tightened tonight)* | ✅ `(user_id = auth.uid())` | ✅ *(added tonight)* | yes, but RLS denies |
| `shadow_insights` | ✅ `(user_id = auth.uid())` | ✅ `(auth.uid() = user_id)` | ✅ *(added tonight)* | ✅ *(added tonight)* | yes, but RLS denies |
| `partner_links` | ✅ owner-only *(added tonight)* | ✅ owner-only | ✅ owner-only | ✅ owner-only | **revoked** *(tonight)* |

Migration files in repo: `supabase/migrations/2026082305*.sql` (3 files). Verified end-to-end with a throwaway user; DB restored to pre-test state.

---

## 6. Feature inventory — claimed vs. shipped vs. honest gap

Each row uses:
- ✅ **shipped + verified** in code
- 🟡 **implemented but partial** or **stubbed**
- ❌ **documented but missing** from code
- ⚪ **not claimed, not built**

### 6.1 Phase 1 — Foundation

| Feature | Doc claim | Code reality |
|---|---|---|
| Dashboard redesign | ✅ done | ✅ `ContentView` with hero, stats, patterns, archetype card |
| FAB for new trigger | ✅ done | ✅ `MusicShadowTheme.floatingActionButton` (now with a11y label) |
| Form progress (4 steps) | ✅ done, 4 steps | ✅ but **3 steps** in current `FormSection` (song, somatic, journal). QA-11 fixed the misleading 4th "share" step |
| Pull-to-refresh | ⚠️ "1/4 views" | Still the same — only `PartnerFeedView` has `.refreshable` |
| Search | ❌ missing | 🟡 `AllTriggersView` filter now works on artist/title/journal via `.searchable` (QA-7 added it; doc still says "missing") |
| Pagination | ❌ missing | 🟡 **No** PostgREST `.range(from:to:)`; `AllTriggersView` and `PatternsView` load everything in one query (fine until ~hundreds of rows) |

### 6.2 Phase 2 — Polish

| Feature | Doc claim | Code reality |
|---|---|---|
| Haptics | ✅ done | ✅ `HapticManager.swift` |
| Empty states | ✅ done | ✅ `EmptyStateView.swift` |
| Skeleton loading | ✅ done | ✅ `LoadingStateView.swift`, `EtherealLoadingView` |
| Swipe actions | ❌ missing | ❌ **Still missing** — no `.swipeActions` in any view |
| Milestone celebrations | ❌ missing | ✅ actually exists — `MilestoneCelebrationView.swift`, called from `SettingsView.eraseAllData` reset path. Doc is wrong, code shipped. |

### 6.3 Phase 3 — Insights & Patterns

| Feature | Doc claim | Code reality |
|---|---|---|
| PatternsView tabs (Overview/Body/Archetypes/Timeline) | ✅ done | 🟡 `PatternsView` is one long view (~900 lines). Tabs live in **separate** views (`TriggerTimelineView`, `ArchetypesView`) reached from dashboard, not as tabs within `PatternsView`. Behavior partially matches. |
| Song detail analytics | ✅ done | ✅ `SongAnalyticsView.swift` |
| Pattern correlation insights | ✅ done | 🟡 In code but rule-based, not ML |
| Advanced filters (date / body / intensity / valence) | ✅ done | 🟡 Filter UI present in `PatternsView`; computed properties filter the in-memory event list |
| 6 Shadow Archetypes | ✅ "6 archetypes" | 🟡 **10 archetypes** in code (AbandonedChild, LoneWolf, Overachiever, InvisibleOne, Mask, Ghost, BuriedFire, DefectiveOne, Protector, Performer). Asset sets exist for all 10; old docs predate Ghost / BuriedFire / DefectiveOne / Mask |

### 6.4 Phase 4 — Polish & Production (commit `572fd7c`)

| Feature | Doc claim | Code reality |
|---|---|---|
| AI reflection w/ lyrics + timestamp | ✅ done | ✅ Edge function `generate_insight` does this; client passes `lyrics_snippet` + `timestamp_seconds` |
| "Activation not saved" discard overlay | ✅ done | ✅ in `NewTriggerView` |
| Dashboard nav (every icon goes somewhere) | ✅ done | ✅ |
| FAB uses Music Shadow emblem | ✅ done | ✅ |
| Patterns: no nav title, custom filter chips | ✅ done | ✅ |
| Per-user cache | ✅ done | ✅ — and after QA-17, **two separate user-id scopes** (events cache vs. insights cache) |

### 6.5 Phase 5 — Platform expansion (the doc, **not started**)

| Feature | Doc claim | Code reality |
|---|---|---|
| Apple Watch app | planned, 8-10h | ❌ not started |
| Home Screen widgets | planned, 4-5h | ❌ not started |
| Siri Shortcuts / App Intents | planned, 3-4h | ❌ not started |
| MusicKit deep integration | planned, 6-8h | ⚪ MusicKit dependency present in `MusicSearchService.swift` but no auth wired — feature **disabled** per `MUSICKIT_SETUP.md` |
| Share Sheet extension | planned, 4-5h | ❌ not started |
| ML pattern prediction | planned, 10-12h | ❌ not started |
| iCloud / multi-device sync | planned, 5-6h | ❌ not started |
| iPad / Mac adaptation | planned, 6-8h | ❌ not started |

### 6.6 The partner feature (cross-cutting, not in any single phase plan)

| Piece | Status |
|---|---|
| `partner_links` table & schema | ✅ exists, FK to `auth.users`, UNIQUE on `owner_user_id` |
| Settings UI for adding a partner | 🟡 in `SettingsView`, but only an `Email` field — no invite flow, no acceptance flow |
| `share_with_partner` + `partner_share_level` columns on events | ✅ columns exist |
| Client `PartnerFeedView` | 🟡 stub — empty list, no fetch |
| Client `PartnerTriggerDetailView` | 🟡 reachable, reads from `event`, but data path is broken |
| RLS that lets a partner read shared events | ❌ **none.** `(user_id = auth.uid())` denies all cross-user SELECT |
| Server-side partner invite / accept / revoke RPC | ❌ **none.** No `auth.users.email`→`partner_links.partner_email` join logic |
| Migration 4 (the partner-read policy) | ❌ **pending.** Spec'd but not written. |

The honest summary: **the partner feature is roughly 25% built.** The schema and lock-down are real. The "partner can see anything" half is entirely a UI shell.

---

## 7. Honest gaps — the things you actually care about

Ordered by impact, not by phase:

### S0 — security / correctness
- ✅ Fixed tonight: `partner_links` RLS, `song_events` INSERT WITH CHECK, missing owner-only UPDATE/DELETE.

### S1 — broken product promises
- **Partner feature doesn't work.** User-facing UI implies sharing; nothing arrives at the partner. Needs Migration 4 + likely a real invite RPC. Realistic effort: **2-4 hours of spec + 1-2 hours of SQL.**
- **MusicKit is disabled.** `MUSICKIT_SETUP.md` documents the setup but it's not wired; `MusicSearchService.swift` is a placeholder. Either ship it or rip it out (currently it's dead code in production).

### S2 — iOS polish gaps vs. doc claims
- Pull-to-refresh on dashboard / AllTriggers / Patterns — adds 4 lines each.
- Swipe actions on trigger rows — adds ~30 lines.
- Pagination — only matters at 100+ rows; you're at 51.
- PatternsView tab restructure — would actually shorten that 900-line file.

### S3 — iOS live QA
- **Still blocked.** gstack's live-device skills require `@Observable`, SPM, and a connected device. You're on `ObservableObject`, no SPM, no device.

### S4 — Phase 5 (entirely aspirational)
- Apple Watch / Widgets / Siri / Share Extension / ML / iCloud / iPad-Mac — **none started**. Phase 5 doc is *planning*, not *plan-of-record*.

---

## 8. Doc-to-code drift — what's misleading in the docs

These are things the docs say that aren't true (or vice versa):

| Doc says | Reality |
|---|---|
| `PHASE_STATUS_CHECK.md`: "Pagination: not done" | ✅ confirms — still true tonight |
| `PHASE_STATUS_CHECK.md`: "Search: not done" | ❌ **out of date** — QA-pass added `.searchable` to `AllTriggersView` |
| `PHASE_STATUS_CHECK.md`: "Milestone celebrations: not done" | ❌ **out of date** — code ships it; only the reset-on-erase path triggers it currently |
| `PHASE_STATUS_CHECK.md`: "Pull-to-refresh 1/4 views" | ✅ still accurate |
| `PHASE_STATUS_CHECK.md`: "Swipe actions: not done" | ✅ still accurate |
| `CURRENT_STATE_AND_MARKETING.md`: "6 archetypes" | ❌ **out of date** — 10 in code + assets |
| `CURRENT_STATE_AND_MARKETING.md`: "Pagination 20/page, Search, Swipe actions" listed under "Phase 1 ✅" | ❌ **out of date** — never shipped |
| `NEXT_STEPS_RECOMMENDATIONS.md`: "Add Search (15 min)" | ❌ **out of date** — already done |
| `NEXT_STEPS_RECOMMENDATIONS.md`: "Add Pull-to-Refresh (10 min)" | ✅ still applicable |
| `AUDIT_LATEST_FUNCTIONS.md` | ✅ accurate — describes what's actually wired |
| `PHASE_5_PLAN.md` | ✅ accurate — clearly marked "future planning, depends on Phase 4 complete" |

The drift is concentrated in `PHASE_STATUS_CHECK.md` and `CURRENT_STATE_AND_MARKETING.md` — these are pre-Phase-4 docs that haven't been updated.

---

## 9. What ships today (user-visible summary)

A user who installs Music Shadow from the App Store right now can:

1. Sign up with email + password.
2. See a 4-page onboarding (or skip).
3. Land on a Dashboard with hero, quick stats, featured insight, and an emblem FAB.
4. Tap FAB → multi-step form: song → body → journal → save.
5. Wait up to ~60s for an AI reflection (Gemini via your edge fn, lyric-aware).
6. See their activations in **All Triggers** with timestamp formatting (QA-7 fix).
7. Filter by date / body / intensity / valence in **Patterns**.
8. See one or more shadow archetypes from their patterns.
9. Drill into a song for **Song Analytics**.
10. See a **Timeline** of activations.
11. Open **Settings** → export data, read privacy/AI docs, delete account, sign out (the latter now correctly posts `.musicShadowDidLogout`).
12. Reach a **Partner** section in Settings (no real sharing — see S1).

What they **cannot** do:

- Search across triggers without going through filter chips — actually now they can via QA-7 fix. (doc was wrong)
- Swipe-delete a trigger row.
- Receive a real shared activation from a partner.
- Use the app on iPad or Apple Watch.
- Use Siri / widgets / share sheet.

---

## 10. Repo hygiene — current state

- **Branch:** `main`
- **Commits ahead of `1b135fd`:** 4 — `69b20cc` (RLS), `c4edc0e` (QA pass + initial .gitignore), `eba0a68` (PNG re-encode), `c7f401d` (cleanup, .gitignore tighten)
- **Working tree:** clean
- **Migrations:** 3 applied, in `supabase/migrations/`
- **`.gitignore`:** covers Xcode user state, Xcode build output, `supabase/.temp/`, `.DS_Store`, swapfiles, `.vscode/`
- **Sensitive tracked state:** none (machine-local `.temp/` untracked tonight)

---

## 11. If I had to prioritize the next 4 weeks

Best ROI, in order:

1. **Migration 4 + partner invite RPC** — turns the partner feature from a UI lie into a real product. 4-6 hours.
2. **Update the two stale docs** (`PHASE_STATUS_CHECK.md`, `CURRENT_STATE_AND_MARKETING.md`) — 30 min each, prevents the drift from getting worse.
3. **Decide on MusicKit**: ship it or delete the stub. Otherwise it's documentation fraud.
4. **Pull-to-refresh + swipe actions on `AllTriggersView`** — one sitting, ~1 hour, big UX win.
5. **Live-device QA** — requires either migrating to `@Observable` + SPM + a connected device, OR accepting the static-QA ceiling. Decide explicitly.
6. **Pagination in `AllTriggersView`** — only matters after you ship growth; defer until ~100+ activations per user.

What I'd skip:
- Phase 5 work until product/partner are solid. Building Apple Watch on top of a half-built partner feature is a recipe for compounding tech debt.
