# Audit: Latest Functions Working

**Date:** Audit run to ensure Phase 4 / 572fd7c-style flows are wired and working.

---

## ✅ Fixes Applied

| Area | Issue | Fix |
|------|--------|-----|
| **SupabaseClientManager** | `markInsightGenerationStarted` / `markInsightGenerationCompleted` missing | Added in-flight set + both methods so `generate_insight` isn’t called twice for same event. |
| **DataCache** | Extra `}` in `invalidateInsightsCache()` | Removed extra brace so method and class parse correctly. |
| **NewTriggerView** | `TriggerValence` and `FormProgressIndicator` not defined | Added `enum TriggerValence { case shadow, positive }` and `private struct FormProgressIndicator` (step progress + labels). |
| **SongAnalyticsView** | `aggregateSongs` private → PatternsView can’t use it | Changed to `func aggregateSongs(...)` (internal) so PatternsView can call it. |
| **MusicShadowTheme** | Typography, Spacing, CornerRadius, Colors, accentGradient, floatingActionButton missing | Restored full theme: Typography, CornerRadius, Spacing, Colors (accentPrimary, error, etc.), accentColor, accentGradient, `floatingActionButton()` extension. |
| **SongEvent** | valence, partner/source fields, isPartnerShareLevelMinimal missing | Added valence, share_with_partner, partner_share_level, source_type, source_context, ai_reason, and `isPartnerShareLevelMinimal`. |
| **ShadowArchetypeDetailView** | Duplicate struct name (overview vs detail) | Renamed standalone overview to `ShadowArchetypeOverviewView` in ShadowArchetypeDetailView.swift. |

---

## ✅ Verified Working

| Flow | Status |
|------|--------|
| **App entry** | `Music_ShadowApp` → `AuthView`; when logged in → `ContentView()`. |
| **AI insight** | NewTriggerView: save event → `triggerInsight(...)` (edge URL, session, payload) → `fetchInsightForResultScreen(eventId)` polls `shadow_insights`; `markInsightGenerationStarted`/`Completed` used. |
| **Edge function** | `generate_insight` expects event_id, song_title, artist, lyrics_snippet, timestamp_seconds; client sends same in InsightPayload. |
| **DataCache** | getCachedEvents/Insights(userId), setCached*, invalidateInsightsCache, invalidateAll; ContentView uses cache and invalidateAll on sign-out. |
| **ContentView** | loadEvents(), loadInsights(), cache check, PatternHighlight.generate(from: events, insights), selectFeaturedInsight(), QuickStatsRibbon, FeaturedInsightCard. |
| **HapticManager** | Components/HapticManager.swift with Trigger cases and trigger(_:). |
| **ShadowInsight** | Model has event_id, wound_type, protector_mode, core_belief, summary, suggested_practice; matches edge output. |

---

## 📁 Key Files

- **Entry / auth:** Music_ShadowApp.swift, Views/AuthView.swift  
- **Dashboard / data:** Views/ContentView.swift, Utils/DataCache.swift  
- **New activation / AI:** Views/NewTriggerView.swift, SupabaseClientManager.swift  
- **Models:** SongEvent.swift, Models/ShadowInsight.swift, Models/ShadowArchetype.swift  
- **Theme:** MusicShadowTheme.swift  
- **Edge function:** supabase/functions/generate_insight/index.ts  

---

## 🔧 If Something Still Fails

1. **Build:** Product → Clean Build Folder (⇧⌘K), then build (⌘B).  
2. **“Cannot find X in scope”:** Confirm the fix for X is in the file that’s actually in the app target (e.g. Music Shadow/Music Shadow/...).  
3. **Partner / timestamp:** PartnerTriggerDetailView uses `event.timestamp_seconds` and `event.isPartnerShareLevelMinimal`; SongEvent includes those.  
4. **Overview vs detail:** Single-archetype detail = `ShadowArchetypeDetailView(archetype:)` in Views/ContentView; overview = `ShadowArchetypeOverviewView(currentName:)` in ShadowArchetypeDetailView.swift.
