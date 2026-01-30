# QA Notes - Music Shadow

## Known Limitations

### AI Reflection Generation
- **Expected Delay**: AI reflections may take 15-30 seconds to generate after creating a trigger
- **Timeout Behavior**: If a reflection doesn't appear within 15 seconds, a "Still processing..." message will appear
- **Retry Mechanism**: Users can tap "Check again" or "Regenerate AI reflection" to retry
- **No Duplicate Insights**: The system prevents duplicate insight generation for the same trigger

### Data Loading
- **Cache Behavior**: The app uses an in-memory cache to reduce repeated queries
- **Refresh**: Pull-to-refresh is available on most list views
- **Network Errors**: Friendly error messages are shown instead of raw database errors

### Partner Sharing
- **Share Levels**: 
  - MINIMAL: Partner sees song, artist, date, intensity, and AI reflection
  - FULL: Adds somatic details and selected journal fields (never free_journal)
- **Unlinking**: Unlinking a partner sets all shared triggers back to private
- **Reversible**: All sharing actions can be reversed

## Expected Behavior

### Onboarding
- Shows only once per installation
- Can be reset via Debug Mode in Settings (for testing)
- Skip button always available
- "Get Started" appears on final page

### Trigger Creation
- Song title is required
- Artist is optional
- All somatic fields are optional
- Intensity defaults to 5 if not set
- Share with partner toggle is off by default

### AI Reflections
- Automatically generated after creating a trigger
- Can be regenerated manually via "Regenerate AI reflection" button
- May take 15-30 seconds to appear
- Timeout message appears after 15 seconds if still processing

### Empty States
- All views show friendly empty states with clear CTAs
- No confusing dead ends
- Empty states guide users to next actions

### Analytics
- Requires at least one trigger to show meaningful data
- Handles missing song/artist gracefully (shows "Unknown song"/"Unknown artist")
- Filters work with any number of triggers

## Areas Still Evolving

- **AI Reflection Quality**: The AI model and prompts are continuously being refined
- **Analytics Depth**: Additional analytics features may be added based on user feedback
- **Partner Experience**: Partner feed features may expand based on usage patterns
- **Performance**: Cache layer and query optimization are ongoing improvements

## Testing Notes

### Critical Flows to Test
1. **First Launch**: Verify onboarding appears
2. **Trigger Creation**: Create a trigger and verify AI reflection appears
3. **Share Toggle**: Toggle share with partner and verify persistence
4. **Partner Feed**: Verify only shared triggers appear
5. **Empty States**: Verify all empty states show appropriate CTAs
6. **Analytics**: Test with 1 trigger, multiple triggers, and missing data

### Edge Cases Verified
- ✅ Missing AI insight (shows friendly message)
- ✅ Missing song/artist (shows "Unknown song"/"Unknown artist")
- ✅ Empty partner feed (shows empty state with CTA)
- ✅ Polling timeout (shows "Still processing..." message)
- ✅ Network errors (shows friendly error messages)

## Debug Mode

When enabled in Settings:
- Shows last refresh time on list views
- Enables extra console logging
- Provides "Show onboarding again" button for testing

