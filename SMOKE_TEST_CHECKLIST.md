# Smoke Test Checklist - Music Shadow

## Instructions
Run the app and manually verify every flow below. Mark each as ✅ PASS or ❌ FAIL.

---

## Auth & Entry

- [ ] App launches cleanly
- [ ] Onboarding shows only once
- [ ] Skip button works
- [ ] Get Started routes correctly
- [ ] Logged-in users skip onboarding

---

## Trigger Creation

- [ ] NewTriggerView opens
- [ ] Song + artist optional but valid
- [ ] Somatic inputs work
- [ ] Intensity saves correctly
- [ ] Share with partner toggle persists
- [ ] Save completes without spinner freeze

---

## AI Flow

- [ ] AI reflection generates for new triggers
- [ ] ai_reason appears in TriggerDetailView
- [ ] "Checking for insight…" disappears correctly
- [ ] Regenerate AI reflection works
- [ ] No duplicate insights created
- [ ] Timeout message appears after 15 seconds if still processing
- [ ] Missing insight shows "AI reflection will appear here once available."

---

## Views

- [ ] AllTriggersView loads correctly
- [ ] TriggerDetailView refreshes after changes
- [ ] SongAnalyticsView works with:
  - [ ] 1 trigger
  - [ ] multiple triggers
  - [ ] missing song/artist (shows "Unknown song"/"Unknown artist")
- [ ] PatternsView renders without empty crashes
- [ ] PartnerFeedView only shows shared triggers
- [ ] PartnerFeedView shows empty state when no shared triggers

---

## Edge Cases

- [ ] Missing AI Insight: Shows friendly message (no error styling)
- [ ] Missing Song/Artist: Analytics doesn't crash, shows "Unknown song"/"Unknown artist"
- [ ] Empty Partner Feed: Always shows empty state CTA, never looks broken

---

## Performance

- [ ] No console spam (repeated warnings)
- [ ] No layout constraint errors
- [ ] Polling stops after timeout
- [ ] No runaway async tasks
- [ ] No memory spikes during 5-10 minute session

---

## UI/UX

- [ ] All empty states have clear CTAs
- [ ] No confusing dead ends
- [ ] Error messages are friendly (not technical)
- [ ] Loading states are clear
- [ ] Transitions are smooth

---

## Notes
_Add any issues found during testing:_

