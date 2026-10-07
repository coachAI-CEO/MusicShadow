# TODOS

Deferred by /autoplan review of `docs/send-receive-plan.md` (2026-10-07).

## Sender "opened" receipt
- **What:** Show the sender when the receiver opened the link.
- **Why:** Closes the loop for the sender.
- **Pros:** Reassurance, retention. **Cons:** In a vulnerability tool a "seen, no reply" signal can add pressure.
- **Context:** `song_shares.view_count` is stored in v1 for operations only. Revisit after the first real sends.
- **Effort:** human S / CC S. **Priority:** P3. **Depends on:** `song_shares` shipped.

## One-tap "send one back" from the receive page
- **What:** Receiver replies with a song and note from the web page, no account.
- **Why:** Turns receivers into senders (the second moat).
- **Pros:** Growth loop, two-sided reflection. **Cons:** Contradicts v1 NOT in scope (two-way replies); needs abuse handling.
- **Context:** Validate one-way sends first.
- **Effort:** human M / CC S. **Priority:** P2. **Depends on:** receive page live, at least a few real sends.

## Brand art for the four light archetypes
- **What:** Icons for The Open Heart, The Free One, The Celebrant, The Connector, matching the existing archetype art (white emblem on the app gradient).
- **Why:** The archetypes shipped on 2026-10-07 using SF Symbols (heart.circle, bird, sparkles, person.2.circle) because there was no way to generate brand images in that session. They read as a different style next to the shadow art.
- **How:** Add image sets named `ArchetypeOpenHeart`, `ArchetypeFreeOne`, `ArchetypeCelebrant`, `ArchetypeConnector` to `Music Shadow/Assets.xcassets`. `ArchetypeIcon` uses an asset automatically when one with that name exists, so no code change is needed.
- **Effort:** human M / CC S. **Priority:** P2.

## Response caching for share_view
- **What:** Short in-function cache keyed by token hash.
- **Why:** A single viral link sends every hit to Postgres.
- **Pros:** Absorbs bursts. **Cons:** Delays revoke by the cache TTL; not needed at one user.
- **Context:** v1 uses no-store everywhere. Revisit if hits per token exceed what the limiter handles.
- **Effort:** human S / CC S. **Priority:** P3. **Depends on:** real traffic.

## Odesli/Songlink universal links
- **What:** Server-side lookup for a platform-neutral link.
- **Why:** Spotify receivers get an Apple link in v1.
- **Pros:** Better match for non-Apple receivers. **Cons:** Third-party dependency; timeouts and fallbacks.
- **Context:** Measure receiver platform in the success test first.
- **Effort:** human M / CC S. **Priority:** P2. **Depends on:** success-test data.

## Block/abuse tooling for shared notes
- **What:** Sender blocking, report triage queue, repeat-abuser flags.
- **Why:** Anonymous links carry free text to third parties.
- **Pros:** App Store 1.2 posture. **Cons:** Operational load for a solo founder.
- **Context:** v1 has a report mailto, takedown by `revoked_at`, and a 50/day creation throttle.
- **Effort:** human M / CC M. **Priority:** P2. **Depends on:** public App Store release.
