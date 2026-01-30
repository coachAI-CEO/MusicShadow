# Phase 3: Insights - Plan & Status

## Overview

Phase 3 focuses on making patterns more discoverable and insights more actionable. The goal is to improve how users explore and understand their shadow work patterns.

---

## 📋 **Phase 3 Tasks**

### 1. PatternsView Tab Reorganization ⏱️ **2-3 hours**
**Status:** Not started

**Current Problem:**
- PatternsView (1747 lines) is information overload
- Everything in one long scrollable view
- No prioritization
- Difficult to find specific information

**Solution:**
Implement tab-based organization:

```swift
TabView {
    // Tab 1: Overview (primary archetypes + key themes)
    PrimaryPatternsView()
        .tabItem {
            Label("Overview", systemImage: "chart.bar")
        }
    
    // Tab 2: Body Patterns (somatic map + impulses)
    BodyPatternsView()
        .tabItem {
            Label("Body", systemImage: "figure.walk")
        }
    
    // Tab 3: Shadow Archetypes (deep dive)
    ArchetypeDeepDiveView()
        .tabItem {
            Label("Archetypes", systemImage: "person.3")
        }
    
    // Tab 4: Timeline (emotional radar over time)
    TimelineView()
        .tabItem {
            Label("Timeline", systemImage: "calendar")
        }
}
```

**Benefits:**
- Reduces cognitive load (one pattern category at a time)
- Faster initial load (lazy load tabs)
- Better scannability
- Clearer information hierarchy

---

### 2. Song Detail View ⏱️ **2-3 hours**
**Status:** Partially done (SongAnalyticsView has detail views, but needs enhancement)

**Current State:**
- `SongAnalyticsSongDetailView` exists
- Shows basic stats, intensity distribution, time-of-day

**Enhancements Needed:**

#### A. Correlation Insights
```swift
// Auto-generated insights
InsightCard(
    icon: "lightbulb.fill",
    title: "Pattern Detected",
    description: "Songs by The National always trigger Fight responses in your chest"
)
```

#### B. Intensity Trends Over Time
- Line chart showing intensity over time for this song
- Helps see if intensity increases/decreases over multiple listens

#### C. Body Location Patterns
- Show which body locations are most common for this song
- Visual map or distribution chart

#### D. Time-of-Day Preferences
- Enhanced time-of-day analysis per song
- "This song usually triggers you in the evening"

**Implementation:**
- Enhance existing `SongAnalyticsSongDetailView`
- Add correlation detection algorithm
- Add chart components for trends
- Add body location analysis

---

### 3. Pattern Correlation Insights ⏱️ **2-3 hours**
**Status:** Not started

**Goal:** Auto-generate insights about correlations

**Examples:**
- "Songs by The National always trigger Fight responses in your chest"
- "Evening triggers tend to be higher intensity"
- "Shadow triggers cluster on weekdays"

**Implementation:**
```swift
func detectPatternCorrelations() -> [PatternCorrelation] {
    // Group events by artist
    // Find artists with 3+ events
    // Check if >80% have same nervous_system + body_location
    // Return correlation insights
}
```

**Display:**
- Add correlation cards at top of analytics/patterns views
- Auto-generated based on user data
- Only show if confidence threshold met (e.g., >80% correlation)

---

### 4. Advanced Filters in Analytics ⏱️ **2-3 hours**
**Status:** Not started

**Current State:**
- SongAnalyticsView has valence filter (All/Shadow/Positive)
- No other filters

**Add Filters:**
```swift
struct AnalyticsFilters {
    var valence: TriggerValence? = nil
    var dateRange: DateRange = .all
    var nervousSystem: String? = nil
    var bodyLocation: BodyLocation? = nil
    var intensity: ClosedRange<Int>? = nil
}
```

**UI:**
- Filter menu button
- Filter chips showing active filters
- Clear all filters option
- Save filter presets (future enhancement)

---

### 5. Related Patterns in TriggerDetailView ⏱️ **1-2 hours**
**Status:** Not started

**Goal:** Show related triggers at bottom of insight detail

**Implementation:**
```swift
// At bottom of TriggerDetailView
Section {
    Text("Related Patterns")
        .font(.headline)
    
    // Show 3-5 other events with same wound_type or archetype
    ForEach(relatedEvents) { event in
        NavigationLink(destination: TriggerDetailView(event: event)) {
            RelatedTriggerRow(event: event)
        }
    }
}
```

**Benefits:**
- Helps users discover patterns
- Contextual navigation
- Better exploration of similar activations

---

### 6. Insight Density Filter (Time Range) ⏱️ **30 min**
**Status:** Not started

**Add to PatternsView:**
```swift
Picker("Time Range", selection: $timeRange) {
    Text("Last 7 days").tag(7)
    Text("Last 30 days").tag(30)
    Text("Last 90 days").tag(90)
    Text("All time").tag(0)
}
.pickerStyle(.segmented)
```

**Benefits:**
- See pattern evolution over time
- Reduce noise for new users
- Identify recent vs historical patterns

---

### 7. Expandable Pattern Highlights ⏱️ **45 min**
**Status:** Not started

**Current:** Only shows top 2 pattern highlights

**Enhancement:**
- Add "See all patterns" button
- Expandable view showing all detected patterns
- Sorting/filtering options

---

## 📊 **Phase 3 Summary**

| Task | Status | Effort | Priority |
|------|--------|--------|----------|
| PatternsView tab reorganization | ⏸️ Not started | 2-3 hours | High |
| Song detail enhancements | ⚠️ Partial | 2-3 hours | High |
| Pattern correlation insights | ⏸️ Not started | 2-3 hours | Medium |
| Advanced filters | ⏸️ Not started | 2-3 hours | Medium |
| Related patterns | ⏸️ Not started | 1-2 hours | Low |
| Time range filter | ⏸️ Not started | 30 min | Low |
| Expandable pattern highlights | ⏸️ Not started | 45 min | Low |

**Total Estimated Effort:** ~10-15 hours

---

## 🎯 **Recommended Implementation Order**

### Week 1 (High Priority)
1. **PatternsView tab reorganization** (2-3 hours)
   - Biggest UX improvement
   - Reduces information overload
   - Foundation for other improvements

2. **Advanced filters** (2-3 hours)
   - Users with many triggers need this
   - Relatively straightforward

### Week 2 (Medium Priority)
3. **Song detail enhancements** (2-3 hours)
   - Build on existing detail view
   - Add correlation insights
   - Add charts for trends

4. **Pattern correlation insights** (2-3 hours)
   - Intelligent pattern detection
   - Auto-generated insights
   - High user value

### Week 3 (Polish)
5. **Related patterns** (1-2 hours)
   - Contextual navigation
   - Easy to implement

6. **Time range filter** (30 min)
   - Quick win
   - Simple picker implementation

7. **Expandable pattern highlights** (45 min)
   - Enhance existing component
   - Better pattern visibility

---

## 💡 **Implementation Notes**

### PatternsView Reorganization
- Split large 1747-line file into multiple focused views
- Maintain existing functionality
- Lazy load tabs for performance
- Smooth tab transitions

### Correlation Detection
- Algorithm should be conservative (high confidence threshold)
- Only show correlations that are statistically meaningful
- Explain how correlation was detected
- Allow users to dismiss insights they find irrelevant

### Advanced Filters
- Start simple, iterate based on usage
- Consider filter presets in future
- Make filters visually clear when active
- Easy to clear all filters

---

## 🚀 **Expected Impact**

### User Engagement
- **+50% pattern view engagement** (via tab organization)
- **+30% song detail view visits** (via better insights)
- **+40% feature discovery** (via related patterns, correlations)

### User Value
- Users can find patterns faster
- Deeper insights into song correlations
- Better understanding of time-based patterns
- More actionable insights

---

## 📝 **Current State Assessment**

### What's Working
- ✅ SongAnalyticsView has good foundation
- ✅ Pattern detection algorithms exist
- ✅ Data aggregation functions work well

### What Needs Work
- ⚠️ PatternsView is too dense
- ⚠️ Limited filtering options
- ⚠️ No correlation insights
- ⚠️ No related pattern discovery

---

**Status:** Ready to start Phase 3
**Next Action:** Begin with PatternsView tab reorganization
