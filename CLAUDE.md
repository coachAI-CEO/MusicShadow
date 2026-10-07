## Skill routing

When the user's request matches an available skill, invoke it via the Skill tool. Route only to skills in the session's available-skills list; answer directly for quick questions or small scoped edits.

Key routing rules:
- Product ideas/brainstorming → invoke /office-hours
- Strategy/scope → invoke /plan-ceo-review
- Architecture → invoke /plan-eng-review
- Design system/plan review → invoke /design-consultation or /plan-design-review
- Full review pipeline → invoke /autoplan
- Bugs/errors → invoke /investigate
- QA/testing site behavior → invoke /qa or /qa-only
- Code review/diff check → invoke /review
- Visual polish → invoke /design-review
- Ship/deploy/PR → invoke /ship or /land-and-deploy
- Save progress → invoke /context-save
- Resume context → invoke /context-restore
- Author a backlog-ready spec/issue → invoke /spec

## Testing

- Swift unit tests (Swift Testing): `xcodebuild test -project "Music Shadow.xcodeproj" -scheme "Music Shadow" -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:"Music ShadowTests" CODE_SIGNING_ALLOWED=NO`
- UI tests (send sheet runs without an account via the debug-only `-uiTestSendSheet` launch argument): same command with `-only-testing:"Music ShadowUITests"`.
- Edge Function prompt tests (pure module, no Deno needed): `bun test supabase/functions/generate_insight`
- Debug-only launch routes (DEBUG builds): `-uiTestSendSheet` shows the send sheet, `-uiTestArchetypes` shows the archetypes screen with sample data. Both skip sign-in.
- Prompt/LLM changes: any edit to `supabase/functions/generate_insight/` must keep `prompts.test.ts` green (it pins the shadow prompt byte-for-byte) and should be checked against `docs/evals/valence-golden.json`.
- Planned (not set up yet): pgTAP via `supabase test db` and `share_view` function tests when the share pipeline is built (`docs/share-spec.md`, section 7).

