<!-- /autoplan restore point: "/Users/macbook/.gstack/projects/coachAI-CEO-MusicShadow/main-autoplan-restore-20261007-002230.md" -->
<!-- /autoplan restore point: "/Users/macbook/.gstack/projects/coachAI-CEO-MusicShadow/main-autoplan-restore-20261007-001653.md" -->
# Music Shadow: Send/Receive Loop Plan

**Date:** 2026-10-07
**Inputs:** `docs/office-hours-2026-10-06.md`, `docs/partner-feature-spec.md`, `NEXT_4_WEEKS.md`, `APP_MAP.md`
**Status:** Reviewed by /autoplan on 2026-10-07 and approved with overrides. **The authoritative build spec is `docs/share-spec.md`; Phase 0 (`docs/phase-0-dumb-send.md`) runs first.** The body below and its stacked amendments are history: where they disagree with the share spec, the share spec wins.

## Implementation plan

### Problem

People feel things through songs they cannot say out loud. Sending a bare link risks being misread, so they hold back. Music Shadow (iOS, SwiftUI + Supabase + Gemini) is a solo shadow-work journal today. The partner feature is about 20% built and nothing arrives at the partner. The reframe: Music Shadow is a vulnerability tool for two people. You understand what a song does to you (existing solo flow), then you send the song with your own words about it. The receiver sees what you meant.

### Product decisions already made (office hours, 2026-10-06)

1. Desperate user: romantic partners and close friends; wedge scenario is "saying what I can't say in words". First real user: the founder's wife.
2. Envelope: the sender writes a short note in their own words, informed by the AI insight (wound type, core belief, summary). The AI insight is context for the sender, not the payload.
3. Receive side: a private web link, no account and no app required. It shows the song, the sender's note, and a download CTA. This is both the cold-start bypass and the growth loop.
4. Receiver sees the sender's reflection only (not a two-way reply flow) in v1.
5. Moats: both sides reflected over time, and somatic + shadow-work grounding (Music Shadow's own archetype set).

### Current state (from code)

- `song_events`, `shadow_insights`, `partner_links` exist with owner-only RLS (3 migrations applied 2026-08-23).
- `partner_links`: one row per owner (UNIQUE `owner_user_id`), `partner_email`, free-text `status`.
- `song_events` has `share_with_partner`, `partner_share_level` (MINIMAL/SUMMARY/FULL), `valence`.
- Uncommitted: `supabase/migrations/20260823060001_partner_read_policy.sql` (adds partner SELECT policies on `song_events` and `shadow_insights`, enum CHECKs, and a `using (true)` SELECT policy on `auth.users` for role `authenticated`), edits to `PartnerFeedView.swift` and `SettingsView.swift`.
- One Edge Function: `generate_insight` (Gemini, lyrics via LRCLIB). Client auth is Supabase email+password.
- 51 production `song_events`, 0-1 `shadow_insights`. No other users yet.
- 10 archetypes, all shadow-framed. Positive-valence activations have no archetype and the AI prompt assumes a wound.

### Build items

#### 1. Partner link + read path (Migration 4)
- Review and apply the partner read policy migration. Replace the broad `auth.users` read policy with a narrower mechanism (security-definer function or JWT email claim) before applying.
- Add `partner_links.status` CHECK (`pending|active|revoked`).
- Partner invite RPC: owner submits partner email, row created `pending`; partner accepting flips to `active`.
- Wire `PartnerFeedView` to a real query and `SettingsView` to upsert/unlink `partner_links`.

#### 2. `song_shares` table (the send payload)
New table: `id uuid pk`, `sender_id uuid fk auth.users`, `event_id uuid fk song_events`, `song_title`, `artist`, `sender_note text` (the sender's own words), `share_token text unique` (random, 128-bit+, URL-safe), `recipient_hint text null` (optional name/email, display only), `created_at`, `revoked_at null`, optional `expires_at`.
RLS: sender can insert/select/update(revoke)/delete own rows. No public table access; the web page reads through a single Edge Function keyed by token.

#### 3. Send flow (iOS)
- After a trigger is logged and the AI insight arrives, show "Send this song". Sender sees the insight as context, writes a note (required, length-capped), taps send.
- App inserts a `song_shares` row and opens the iOS share sheet with `https://<domain>/s/<token>`.
- Sender can view and revoke past shares (list in Settings or Timeline).
- Archetype shown to the receiver is optional and off by default.

#### 4. Web receive page
- Supabase Edge Function `share_view` (GET `/s/<token>`) returns server-rendered HTML: song title/artist, sender's note, soft CTA to the App Store. Service-role lookup by token only; returns 404 for unknown, revoked, or expired tokens, identical response shape to avoid token probing.
- Page sets `noindex`, `Referrer-Policy: no-referrer`, no third-party scripts, no analytics beyond a view counter. OpenGraph preview shows song title only, never the note.
- Rate limit per IP on the function.

#### 5. Positive-valence branch
- Logging form asks whether the activation was a wound or a gift (maps to existing `valence`). *Correction 2026-10-07: already built (`NewTriggerView`: "Shadow spike" / "Positive hit", stored as `shadow` / `positive`); only the prompt branch was missing and it now ships.*
- `generate_insight` prompt branches on valence so positive songs get appreciative reflection, not wound language.
- Add four light archetypes (The Open Heart, The Free One, The Celebrant, The Connector), keyword scoring rebuilt around lived language. Icons generated from the brand prompt.

#### 6. Onboarding + positioning
- Rewrite onboarding around "understand yourself first, then share".
- Update App Store copy and marketing docs from "shadow work journal" to the send-a-song positioning.

#### 7. Cleanup that gates shipping
- Decide MusicKit: delete the stub or ship it.
- Pull-to-refresh and swipe actions on `AllTriggersView`.

### Sequencing

Week 1: item 1. Week 1-2: items 2 and 3. Week 2-3: item 4. Week 3: item 5 (valence branch first, archetypes after). Week 4: items 6 and 7. Phase 5 (Watch, widgets, Siri, ML, iCloud, iPad) deferred.

### NOT in scope

Two-way replies, in-app chat, notifications beyond the share sheet, Apple Watch/widgets/Siri, ML pattern prediction, iCloud sync, pagination.

### Open questions

- Bidirectional partner model now or later (current `partner_links` is one row per owner)?
- Vulnerability control: does the sender choose what the receiver sees beyond the note?
- Link lifetime: forever, expiring, or revocable only?
- Custom domain for share links vs the raw Supabase function URL.
- Is a web page enough for Android/non-iPhone recipients, and what should the CTA say for them?


<!-- autoplan-accepted:ceo -->
- The receive page must give the receiver a way to play the song (streaming link or deep link), not only title/artist. Verify: open a share URL on a phone with no app installed and reach playback in one tap.
- The share page HTML must be served from a host/domain that returns Content-Type text/html (Supabase default domain rewrites text/html to text/plain). Verify: curl -I on the public share URL shows text/html and a browser renders it.
- The send sheet offers optional starter prompts for the note; the note stays the sender's own words (no AI-written note). Prompts are an inline list of 5 to 8 short questions in the send view (for example "What did your body do?", "What do you wish they knew?"), written from the somatic wording already used in `SomaticPractice.swift`. Verify: UI test that the note field is empty by default and required.
- Playable link source (amends item 2 and item 4): `song_shares` gains `play_url text null` and `provider text null`. The iOS app fills `play_url` at send time from the Apple Music/MusicKit or iTunes Search match, with an Odesli/Songlink lookup as an optional upgrade; if no match is found it stays null and the page shows a "Search this song" link built from title and artist. The lookup is server-side or in-app only; the receive page loads no third-party scripts. Verify: sharing a song with no match still renders a working page.
- Hosting and route (amends item 4): `share_view` returns JSON `{title, artist, note, play_url}` (or 404) from a Supabase Edge Function; a static host on a custom domain (for example Cloudflare Pages or Vercel) serves `/s/<token>` HTML that fetches that JSON and renders it. The domain is decided in week 1 and the iOS share URL uses it. Verify: `curl -I https://<domain>/s/<token>` returns text/html.
- Rate limiting (amends item 4): per-IP limiting is enforced at the static host/CDN edge (Cloudflare rules) plus a small `share_view_hits` counter keyed by token hash for burst detection; identical 404 body and status for unknown, revoked and expired tokens. Verify: 100 unknown-token requests in a minute are throttled and all return the same body.
- Escaping and abuse (amends item 4): the note is rendered as text only (HTML-escaped, newlines preserved), length-capped at 500 characters on client and in a database CHECK. Verify: a note containing `<script>` renders literally.
- Lifetime and lifecycle (resolves open questions): links never expire by default; `expires_at` stays null unless the sender sets one; revoke is available any time. Deleting an account cascades to `song_shares` (FK on delete cascade). The view counter is a `view_count int` on `song_shares`, stored for operations and not shown to the sender in v1. Verify: deleting a test user removes its shares and the link returns 404.
- Send flow failure paths (amends item 3): if the insight is slow or fails the sender can still write a note without it; the `song_shares` row is created only when the user taps Send, and the share sheet reuses that row if the user cancels and taps again (no duplicates). Verify: cancel then resend yields one row.
- Receive CTA (resolves open question): iPhone visitors see an App Store link once a listing URL exists, and a "Coming soon" line before launch; non-iPhone visitors see the same page with the text "Available on iPhone". Verify: page renders correctly with iPhone and Android user agents.
- Deferred by taste (item 5): the four new light archetypes and their generated icons move to TODOS.md; the valence question and the `generate_insight` valence branch stay in scope and are sequenced before items 6 and 7. Verify: a positive-valence log produces appreciative wording, not wound language.
- CONSOLIDATED v1 SHARE SPEC (supersedes conflicting body text in items 2, 3, 4, 5, sequencing and open questions; spec-review round 2):
  - Schema, migration `20261007000001_song_shares.sql` (separate from the partner migration): `song_shares(id uuid pk default gen_random_uuid(), sender_id uuid not null references auth.users on delete cascade, event_id uuid references song_events on delete set null, song_title text not null check (char_length(song_title) between 1 and 200), artist text not null check (char_length(artist) between 1 and 200), sender_note text not null check (char_length(sender_note) between 1 and 500), share_token text not null unique, recipient_hint text null check (char_length(recipient_hint) <= 80), play_url text null check (play_url ~ '^https://(music\.apple\.com|open\.spotify\.com|song\.link|youtu\.be|www\.youtube\.com)/'), provider text null check (provider in ('apple','spotify','songlink','youtube')), view_count int not null default 0, created_at timestamptz not null default now(), revoked_at timestamptz null, expires_at timestamptz null)`. Owner-only RLS (insert/select/update/delete where sender_id = auth.uid()). Verify: inserting a `javascript:` play_url, a 501-char note, or a foreign sender_id fails.
  - Single request path: `https://<domain>/s/<token>` is served by a host-side function on the static host (for example a Cloudflare Pages Function) that calls the Supabase Edge Function `share_view` (`POST /functions/v1/share_view`, deployed with `--no-verify-jwt`, requires a shared secret header from the host, CORS closed) and renders the complete HTML on the server. This replaces client-side JSON rendering and makes the Open Graph tags (title only, never the note, with a generic image) visible to link-preview crawlers. The Edge Function sets `Cache-Control: no-store`; the host function sets `Cache-Control: no-store` on 404 and `private, max-age=0` on 200 so revoke takes effect immediately. Verify: crawler fetch shows og:title; revoke then reload returns 404 within seconds.
  - Page requirements (host function): `noindex`, `Referrer-Policy: no-referrer`, no third-party scripts, all dynamic fields (title, artist, note) HTML-escaped, play link rendered with `rel="noopener noreferrer"`, a "Report this message" mailto link in the footer, and the "Coming soon" or "Available on iPhone" CTA chosen by user agent. Verify: curl -I shows text/html and the headers; a note containing `<script>` renders literally.
  - Token probing and throttling: the Edge Function rejects requests lacking the host secret, so only the host edge is reachable; per-IP limiting is a host rule; throttled responses may return 429 and that is the only permitted difference from the identical 404 for unknown, revoked and expired tokens. The `share_view_hits` table is dropped; `view_count` on `song_shares` is the single counter and unknown tokens are not counted. Verify: direct call to the function without the secret returns the same 404; 100 unknown tokens in a minute are throttled.
  - Send flow: the app creates the `song_shares` row on first Send and keeps its `id` in the draft (persisted across relaunch); cancelling the share sheet and resending updates that row's note instead of inserting; archetype is not sent to the receiver in v1. `play_url` comes from the iTunes Search/Apple Music match at send time; the Odesli/Songlink "upgrade" is removed from v1. Verify: edit-after-cancel yields one row with the latest note.
  - Starter prompts (fixed list, inserted only on tap, never auto-filled): "What did your body do when it started?", "What does this song say that I can't?", "What do I wish you knew?", "What memory or moment is this?", "What do I want you to feel hearing it?". Verify: tapping inserts text the sender can edit; the empty note blocks Send.
  - Sequencing (replaces the Sequencing section): Week 1: domain, static host, Supabase `share_view` spike proving the HTML path, MusicKit-vs-iTunes decision (iTunes Search is the v1 source; MusicKit stays independent), and migration `song_shares`. Weeks 1-2: send flow. Weeks 2-3: receive page, OG, throttling, revoke list. Week 3: valence question and `generate_insight` valence branch. Week 4: item 6 onboarding only (App Store copy rewrite waits until after the first real sends) and item 7 polish. Success test: the founder's wife sends at least 3 real songs and at least 2 receivers reach playback. App Store submission must answer user-generated-content guideline 1.2 (report link, ability to revoke) and update the privacy policy and privacy labels for shared notes; host logs containing tokens have a 7-day retention.
  - Item 1 gate: the partner migration `20260823060001_partner_read_policy.sql` stays unapplied and item 1 work is gated on the Phase 4 User Challenge; items 2 to 4 proceed independently of it. If item 1 is kept, its SELECT policies must not expose `shadow_insights` or MINIMAL/SUMMARY/FULL content beyond what decisions 2 and 4 allow, and the invite flow adds no notifications beyond the share sheet.
  - Open questions reconciled: link lifetime (resolved: no expiry, revocable), custom domain (resolved: required), Android CTA (resolved: "Available on iPhone"), vulnerability control (resolved for v1: receiver sees title, artist, note and play link only), bidirectional partner model (deferred with item 1 and TODOS.md send-back).
- ROUND-3 ADDENDUM (applied after the third and final spec review; not re-reviewed). Authoritative over all earlier body text: where item 2 to 5, Sequencing or Open questions disagree with the CONSOLIDATED v1 SHARE SPEC or this addendum, the spec and addendum win and implementers must not build from the superseded text (GET `/s/<token>` Edge Function HTML, `share_view_hits`, client-side JSON rendering, archetypes sent to the receiver, four light archetypes, "Week 1: item 1").
  - Token: `share_token` is generated by the database as `encode(gen_random_bytes(16),'base64url')` (default), with `check (char_length(share_token) >= 22)`; the client never supplies it. Verify: a short or client-supplied token insert fails.
  - `play_url` allowlist also accepts `itunes.apple.com`; the app normalizes iTunes Search links to `music.apple.com` when possible and shows the matched title/artist for the sender to confirm or skip; offline or no match sends with `play_url` null. The fallback "Search this song" link goes to `https://music.apple.com/search?term=<title+artist>` and is built at render time, never stored. Playback means a store link or 30-second preview is acceptable for v1.
  - Update restriction: sender UPDATE is limited by a trigger or column privileges to `sender_note`, `revoked_at`, `expires_at`, `recipient_hint`; `share_token`, `view_count`, `sender_id`, `play_url` and `provider` cannot change after insert (play_url may be set once at insert). The note is locked after the share sheet reports a completed share; before that, resend updates the same row. The persisted draft id is discarded on logout, account switch, or if the row is revoked or deleted. Verify: update of `view_count` as the sender fails.
  - `view_count` is incremented atomically by the Edge Function (service role) on each successful 200 lookup; crawler and retry hits may inflate it and it is ops-only and approximate.
  - Error states: Edge Function 5xx or timeout renders a generic "Something went wrong, try again" page with `no-store` and status 503, never the 404 body. Both 200 and 404 from the host use `Cache-Control: no-store`. The host secret lives in host and Supabase function secrets and is rotated by redeploying both. Verify: stub the function to 500 and confirm the 503 page.
  - Revoke list (item 3 restated): Settings > "Shared songs" lists shares (title, artist, date, state); Revoke asks for confirmation, sets `revoked_at`, and shows an error with retry if offline; revoked shares stay listed as Revoked; delete removes the row. Verify: UI test of revoke offline and online.
  - Abuse: the report mailto goes to a monitored address; takedown is the operator setting `revoked_at` with the service role within 24 hours; sender display name is not shown in v1, and the sender may write their own name in the note. Host logs must not store tokens beyond what the host forces; no retention promise is made beyond the host's default and the privacy policy says so.
  - Schedule: Week 1 adds TestFlight build setup and a spike with explicit pass criteria (host function renders HTML with og:title and text/html, calls the secret-gated Edge Function, p95 under 1.5 s from a phone); if the spike fails or per-IP limiting is unavailable on the chosen host plan, fall back to an in-function limiter using a small Supabase table keyed by hashed IP. Cut line: item 7 polish, then the valence branch, slip before any share-loop work. Item 1 is unscheduled and blocked on the Phase 4 User Challenge. New migration versions sort after `20260823060001`, so the partner migration must be renumbered or applied with `--include-all` if it is ever applied. The success test is measured by the sender confirming playback with each receiver in person or by message; no page analytics are added.
  - CTA user agents: iPhone shows the App Store link or "Coming soon"; iPad, Mac and in-app browsers are treated as iPhone-capable; everything else shows "Available on iPhone".
- PHASE 1 AMENDMENTS (from the native CEO review; authoritative over earlier text): (a) Default link lifetime is 90 days (`expires_at` set at insert); the sender may choose 30 days, 90 days or no expiry in the send sheet, and revoke stays prominent. This replaces "links never expire by default". Verify: a new share has expires_at about 90 days out and the link returns the same 404 after it. (b) The abuse promise is "reviewed promptly" with a monitored report address, not a 24-hour SLA. (c) The receive page is a delivery channel in v1; the "growth loop" claim is dropped from v1 success criteria because the App Store CTA reads "Coming soon" until a listing exists. (d) The success test also records, per send, receiver platform (Apple Music vs Spotify vs other), whether the song matched, and whether the sender later reports that the receiver responded, so silence and match rate are measured rather than assumed. (e) The MusicKit decision in item 7 is reconciled: iTunes Search is the v1 source of play_url and MusicKit stays unshipped unless a later decision revives it. Verify: no MusicKit entitlement is required for the share flow.
<!-- /autoplan-accepted:ceo -->

<!-- autoplan-accepted:design -->
- Receive page order and copy: one-line framing ("Someone shared a song with you"), optional "From <name>", the note large with preserved line breaks and RTL support, song title and artist with one primary Play control, a small "Open in Apple Music" link, a line "You can reply to them directly.", and a muted "Report a problem" footer link; the "Coming soon" CTA line is omitted until an App Store URL exists. Verify: screenshot at 375 px and curl output match the order; the note is visually the largest text.
- In-page playback uses a native audio element with the iTunes 30-second `previewUrl`; add `preview_url text null` to `song_shares` with a CHECK limiting it to `https://audio-ssl.itunes.apple.com/` and `https://*.mzstatic.com/`; when null, Play is hidden and only the search link shows. This amends the earlier play_url allowlist note: `play_url` remains the store link. Verify: an iPhone with no Apple Music account plays the preview in one tap with no third-party script.
- OG preview: title "Someone sent you a song", neutral description, generic image; never the song title or the note. Verify: crawler output.
- Receive-page state table: ok, ok-without-preview, unavailable (human copy above, identical body for unknown/revoked/expired), 503 error, 429 throttled; all server-rendered with inline CSS and no blocking requests. Verify: stub each state and compare.
- Send sheet hierarchy: note field primary and focused; AI insight in a collapsed secondary card; starter prompts as chips that insert text at the cursor (single-use per tap, text remains editable); song match, expiry selector (30 days, 90 days default, no expiry) and Send below; Send is the only prominent button; 400-character counter appears from 400 and input hard-stops at 500 with truncation on paste. Verify: UI tests for chip insertion, counter and cap.
- Send-view states: insight loading/ready/failed, match searching/one/several/none/offline, note empty/valid/near cap/at cap/locked, send idle/creating/failed/created-not-shared/shared, "Draft restored" cue. Verify: each state reachable in a UI test or preview.
- Preview step: after the note, a "Preview as they'll see it" screen renders the real receive layout; Send on that screen is the final tap; copy states that the link can be turned off later but they may already have seen it. Verify: the preview uses the same renderer or markup as the page.
- Shared songs list: empty, loading, offline error, row states Active / Expires in N days / Expired / Revoked, Copy link and Share again for active shares, revoke and delete confirmations with honest copy. Verify: UI tests.
- Optional "From" display name in the send sheet (40 characters, escaped, shown as "From <name>"); stored in a new `sender_display_name text null` column with a 40-character CHECK. Verify: `<script>` in the name renders literally.
- First-run explainer: a single screen the first time the send sheet opens, saying what the receiver sees, that the link needs no account, and how to turn it off. Verify: appears once, not again after dismissal.
- Partner UI (PartnerFeedView entry points and Settings partner invite) is hidden behind a build flag in the v1 build until the item 1 decision. Verify: no partner screen reachable in the TestFlight build.
- Accessibility: Dynamic Type, 44 pt targets, VoiceOver labels (counter, chips, revoke), web `lang`, semantic landmarks, 4.5:1 contrast, `prefers-color-scheme`, reduced-motion respected. Verify: VoiceOver walkthrough and Lighthouse accessibility check.
<!-- /autoplan-accepted:design -->

<!-- autoplan-accepted:dx -->
- Flattened spec: before coding, create `docs/share-spec.md` as the single authoritative input (final `CREATE TABLE` with every column and CHECK: `preview_url`, `sender_display_name`, itunes.apple.com allowance, `expires_at default now() + interval '90 days'`; request path; page states; send flow; schedule; ops), grouped by area (data, host, iOS send, receive page, ops, App Store). The older text in this plan is marked superseded. Where the design phase's bullets conflict with earlier text, the design bullets win. Verify: an implementer can build the schema from that file alone.
- Edge Function contract table (15 lines or fewer): `POST /functions/v1/share_view`, secret header name, request body `{token}`, 200 body `{title, artist, note, play_url, preview_url, sender_display_name, expires_at}`, 404, 503, 429; field names pinned in Swift `CodingKeys`. Verify: contract test hits each status.
- Immutable columns are enforced by a BEFORE UPDATE trigger that raises on changes to `share_token`, `view_count`, `sender_id`, `play_url`, `preview_url`, `provider`, `song_title`, `artist`, and on `sender_note` after a completed share; column privileges are not used. Verify: SQL test per column.
- Operator observability: the Edge Function logs a reason code (`bad_secret`, `not_found`, `revoked`, `expired`, `disabled`) with a token hash prefix while returning identical bodies; `scripts/share-lookup` (service role, by share id or token hash) prints a share's state; a global kill switch `SHARE_DISABLED=1` on the Edge Function and host function returns the unavailable page for all tokens. Verify: bad secret logs `bad_secret`; kill switch test.
- Operator tooling: `scripts/seed-share` creates a test share and prints its URL; `scripts/verify-share.sh` exits nonzero unless text/html and headers are present, a `<script>` note renders literally, unknown/revoked/expired tokens return identical bodies, and a stubbed function failure yields the 503 page; `docs/share-runbook.md` covers takedown (`revoked_at` via service role), secret rotation (redeploy both), report inbox, kill switch; a "Share TTHW" section documents the setup sequence with a 30-minute estimated target. Verify: run the sequence once from a clean clone and record the time.
- Sender error table: note insert failure, `play_url` CHECK rejection (send continues with `play_url` null), paste over 500, deleted or revoked draft row ("This link was removed. Start a new one."), each with message and retry action. Verify: UI or unit test per row.
- iTunes match picker: show up to 3 results to pick from, or skip. Verify: UI test with a stubbed multiple-result response.
- Portability: the host function is a thin adapter (token, secret, call, respond) and the HTML renderer is a plain shared module also used by the iOS preview step. Verify: the same renderer output is used by both.
- The partner migration `20260823060001_partner_read_policy.sql` moves to `supabase/migrations_deferred/` so it cannot be applied by accident. Verify: `supabase db push --dry-run` does not list it.
<!-- /autoplan-accepted:dx -->

<!-- autoplan-accepted:eng -->
- Hard gate: write `docs/share-spec.md` before any code and mark the superseded text in this plan as dead; the flattened spec includes a conflict-resolution table whose rulings are: expiry default 90 days (not "never"); OG title "Someone sent you a song" with no song title; Report link text "Report a problem"; no "Coming soon" line; Edge Function returns the full contract (`title, artist, note, play_url, preview_url, sender_display_name, expires_at`); every response `Cache-Control: no-store` and `Vary: User-Agent`; design-phase bullets win over earlier text. Verify: a clean-room reader builds the schema and routes from that file only.
- Add `shared_at timestamptz null` to `song_shares`, set once by the client when the share sheet completes; the trigger blocks `sender_note` changes once it is non-null; documented as a UX guard, not a security boundary; `expires_at` stays sender-mutable (extending an expired link is allowed). Verify: SQL tests.
- Edge Function auth: constant-time secret comparison; accept a current and a next secret so rotation has no window; log reason codes with an 8-character token hash prefix only, never the raw token. Verify: Deno tests for missing, wrong, current, next.
- Limiter: the function-side limiter is the default, keyed by HMAC(client IP, server secret) in a small table with a 7-day purge; host-edge rules are defense in depth; a per-sender share-creation throttle of 50 per day is enforced by a DB trigger. Verify: tests exceed each limit.
- Response policy: all responses use `no-store` and `Vary: User-Agent`; one `unavailable()` builder serves unknown, revoked, expired and kill-switch cases; `scripts/verify-share.sh` asserts the four bodies and status are byte-identical; a CDN test fetches twice, revokes, refetches. Verify: the script.
- CSP on the page: `default-src 'none'; media-src https://audio-ssl.itunes.apple.com https://*.mzstatic.com; style-src 'sha256-<hash of the static stylesheet>'; img-src 'self' data:; base-uri 'none'; form-action 'none'`; audio `error` event hides Play and shows the store or search link; note element has `dir="auto"`. Verify: header check and a dead-URL test.
- CHECK regexes: `preview_url ~ '^https://(audio-ssl\.itunes\.apple\.com|[a-z0-9-]+\.mzstatic\.com)/'`; `play_url` allowlist as in the spec plus `itunes.apple.com`; SQL tests include `https://music.apple.com.evil.com/`, `https://music.apple.com@evil.com/` and `javascript:`; confirm live iTunes preview hosts before launch. Verify: pgTAP.
- Idempotent send: the client generates the share `id` (UUID) and upserts; a retry after a lost response creates one row; an upsert against another user's id fails cleanly with a mapped error row. Verify: unit and pgTAP tests.
- Expiry encoding: the app sends `expires_at` explicitly, including an explicit `null` for "no expiry" (custom encoder or RPC), never omitting the key. Verify: a unit test for each selector value.
- Length parity: the client counts Unicode scalars (`unicodeScalars.count`) to match Postgres `char_length`; tests include family emoji and combining marks.
- Renderer parity (TASTE, chosen): the iOS preview is a Swift renderer; golden-file fixtures run through both the host renderer and the Swift renderer and must match. Verify: fixture test in both runtimes.
- Event deletion: the delete-trigger confirmation says shares of that song remain unless revoked and offers "Also turn off links for this song". Verify: UI test.
- View counting: increments only on GET 200 and are non-blocking; HEAD and unfurl bots do not fail or count. Verify: Deno tests.
- Schedule: remove the MusicKit decision from week 1 (resolved); schedule about 2 days for tooling (`seed-share`, `verify-share.sh`, runbook with a SQL snippet in place of `share-lookup`); domain and DNS are a gating dependency started in week 1; the "30 minute Share TTHW" excludes DNS propagation. A down migration for `song_shares` is hand-written.
- Test infrastructure: add pgTAP (`supabase test db`), Deno tests for the Edge Function, the host runtime's test runner for the renderer, Swift Testing units and XCUITests for the send/revoke flows; the generate_insight valence change ships with a 10 gift / 10 wound golden set and a before/after check on stored wound insights. Verify: `supabase test db`, `deno test`, `xcodebuild test` all run in one documented command list.
- The deferred partner migration file gets a header comment: never apply as written (the `auth.users` `using (true)` policy exposes every email); partner UI is verified hidden by grepping the TestFlight build for reachable entry points; the uncommitted `PartnerFeedView.swift` and `SettingsView.swift` edits are committed behind the flag before send-flow work touches Settings. Verify: grep and a manual walkthrough.
- Audio preview URLs are fetched by the receiver's browser from Apple hosts; the privacy policy discloses this. Verify: policy text present before submission.
<!-- /autoplan-accepted:eng -->
## Review record

### CEO Step 0 (SELECTIVE EXPANSION, auto-decided)

**Premise challenge.**
- P1 Desperate user = romantic partners / close friends. Evidence: one user (founder's wife), not yet observed using it. ACCEPT (P6) but flag n=1; the 4-week plan has no gate that tests it before items 5-7 are built.
- P2 Receiver needs no account. ACCEPT; it is the strongest decision in the plan.
- P3 Item 1 (partner_links, invite RPC, auth.users policy, PartnerFeedView wiring) is still required. QUESTIONABLE: decision 3 makes the receive path a token link, so the email-matched RLS partner feed duplicates it and carries the only high-severity security item (cross-user SELECT on auth.users). Queued as User Challenge candidate for Phase 4 (original direction stands).
- P4 Seven items fit in four weeks for one builder. QUESTIONABLE: items 5, 6, 7 are not on the critical path to testing the wedge.
- Do-nothing cost: the wedge stays unvalidated and the app stays a solo journal with 51 events and no other users.

**Existing code leverage.** `song_events`, `shadow_insights`, `generate_insight` (Gemini, LRCLIB), owner-only RLS, PartnerFeedView/SettingsView partner UI (uncommitted), `valence` column, archetype assets pipeline. Rebuilt: nothing; `song_shares` is net-new and correctly separate from `partner_links`.

**Dream state.**
```
CURRENT                         THIS PLAN                          12-MONTH IDEAL
solo shadow journal   --->   send song + own note via link  --->  two-sided reflection over time,
51 events, 0 other users      receiver sees sender only            receivers become senders
```

**Alternatives.** A) plan as written (7 items). B) Thin slice first: items 2, 3, 4 only, hand it to the founder's wife, then decide 1/5/6/7. C) Replace the web page with an iMessage-native share (no backend). B is smallest and tests the premise; A is the stated direction. Close call, marked TASTE.

**Mode:** SELECTIVE EXPANSION (added capability, ~12 files). Auto-decided per autoplan override.

**Scope proposals (0G).**
| # | Proposal | Effort | Decision | Reasoning |
|---|----------|--------|----------|-----------|
| 1 | Receive page must let the receiver HEAR the song (universal streaming link via Odesli/Songlink or Apple Music/Spotify deep link) | S | ACCEPTED (gap, not expansion) | Page as specified shows title/artist only; a song-sharing page that cannot play the song fails the core job. In blast radius (P2). |
| 2 | Serve the share page from a host that renders HTML (custom domain or static host calling an Edge JSON endpoint) | S | ACCEPTED (feasibility) | Search evidence: Supabase rewrites text/html GET responses to text/plain on the default domain. Plan's open question on custom domain becomes a requirement. |
| 3 | Sender sees "opened" receipt | S | DEFERRED to TODOS | View counter already planned; exposing it to the sender can add pressure in a vulnerability tool. Taste. |
| 4 | One-tap "send one back" from receive page | M | DEFERRED to TODOS | Directly contradicts NOT in scope (two-way replies); validate one-way first. |
| 5 | Starter prompts for the sender note ("what did your body do?") drawn from existing somatic content | S | ACCEPTED (taste) | Keeps note in the sender's own words, reuses `SomaticPractice.swift`, blast radius = send sheet only. |
| 6 | Scheduled / delayed send | M | SKIPPED | No evidence of need. |

**Taste calibration.** Reference patterns: owner-only RLS migrations 1-3 (explicit, idempotent); `generate_insight` Edge Function structure. Avoid: migration 4's `using (true)` on `auth.users` and its "Applied" header on an untracked file.

**Landscape check (WebSearch, low confidence).** Search surfaced Love Letter (link-with-music letter app) and Sendthesong (song + note); sources were low quality, treat as indicative only. Layer 1: bare Spotify link plus text. Layer 2: note-with-song link pages exist. Layer 3: the differentiator is the self-understanding step before sending, which none of them have; the plan already says so.

**Spec review loop (0H).** Three launches, scores 5, 6, 7 of 10; cap reached. Final document approval auto-decided A (approve these document versions only) because the remaining issues are declared in Reviewer Concerns and the addendum; unresolved amendments and implementation stay unapproved. Metrics written to analytics/spec-review.jsonl.

**Temporal interrogation (0I).** Hour 1: domain and host choice, `song_shares` migration, DB-generated token. Hours 2-3: the host-function to Edge Function secret handshake and HTML escaping. Hours 4-5: iTunes Search matching (wrong-song risk), share sheet cancel/resend row reuse, draft persistence. Hour 6+: tests for revoke offline, XSS note, token probing, 503 vs 404, TestFlight build for the first real send. Effort: human ~3 weeks / CC+gstack ~3-4 days for items 2-4.

### CEO Phase 1: dual voices and review sections

**CEO DUAL VOICES - CONSENSUS TABLE** (outside voice N/A: Codex CLI not installed; native Claude pass completed)
```
  Dimension                             Claude  Codex  Consensus
  1. Premises valid?                    NO (n=1) N/A   N/A
  2. Right problem to solve?            YES      N/A   N/A
  3. Scope calibration correct?         NO       N/A   N/A
  4. Alternatives sufficiently explored? NO      N/A   N/A
  5. Competitive/market risks covered?  NO       N/A   N/A
  6. 6-month trajectory sound?          PARTLY   N/A   N/A
```
Native findings F1-F17 integrated: F7 (finite default lifetime) accepted as Phase 1 amendment (a); F9, F4, F5-measurement, F13 accepted as amendments (b)-(e); F8 (spec collapse) deferred to the end-of-pipeline rewrite offer; F1/F2/F12 (validate with a no-infra "dumb send" before building the pipeline) and F11 (choose link moat vs account moat) are strategic direction changes, queued as User Challenges (primary agrees: Step 0 alternative B). F14 competitive risk and F16 (gift song as first wedge) are TASTE items for the final gate. F17 keeps the partner migration unapplied.

**Section 1: Architecture.** Current scope: SELECTIVE EXPANSION; accepted additions are play_url, host-rendered HTML, starter prompts; item 1 pending User Challenge.
```
 iOS app (SwiftUI)                                  Supabase
  NewTriggerView -> generate_insight (existing) ---> Edge fn generate_insight -> Gemini/LRCLIB
  SendSheet (note, prompts, expiry) --insert/update--> song_shares (RLS owner-only, triggers)
  UIActivityViewController(https://<domain>/s/<tok>)
 Receiver browser/iMessage crawler
  GET /s/<tok> --> Static host function (CF Pages) --POST+secret--> Edge fn share_view --> song_shares (service role)
                       |  renders HTML (escaped, OG title only, no-store)      |  view_count++ (200 only)
                       +<--------------- JSON or 404/503 ----------------------+
 Partner path (item 1, gated): partner_links + email RLS on song_events/shadow_insights (unapplied migration)
```
Data flows: happy (Send -> row -> link -> HTML -> play link), nil (no insight: note still sendable; no play_url: search link), empty (empty note blocked client and CHECK), error (function 5xx -> 503 page, token wrong -> uniform 404, offline send -> row not created, retry). State machine for a share: `draft(client only) -> active -> {revoked | expired}`; invalid transitions (revoked -> active, note edit after completed share) are blocked by the update trigger. SPOFs: the host function and the single secret; the Supabase project; rollback: revoke all shares via SQL (`update song_shares set revoked_at=now()`), drop the host route (minutes). 10x: Edge Function cold start and view_count row contention are the first limits; both irrelevant at current scale.

**Section 2: Error and rescue (capability level, implementation-ready rows).**
| CODEPATH | FAILURE | RESCUED | ACTION | USER SEES |
|---|---|---|---|---|
| Send: insert song_shares | offline / RLS reject / CHECK violation | Y | keep draft, inline error, retry | "Couldn't create link, try again" |
| Send: iTunes Search match | timeout, no match, wrong song | Y | confirm-or-skip UI; null play_url | search link on page |
| generate_insight | slow, malformed JSON, refusal, empty | Y (existing; verify) | note flow does not wait | sender writes note anyway |
| share_view | unknown/revoked/expired token | Y | uniform 404 | generic "link unavailable" |
| share_view | 5xx/timeout | Y | 503 no-store page | "try again" (not 404) |
| host to function | missing/rotated secret | Y | 503 + alert | generic error |
| HTML render | note with markup | Y | escape | literal text |
| revoke | offline | Y | error + retry | message |
Gap: generate_insight malformed/refusal behavior is not specified in this plan; owner must verify the existing function handles distinct empty/invalid/refusal cases (valence branch adds a prompt path). No catch-alls specified.

**Section 3: Security and threat model.**
| Threat | L | I | Mitigated? |
|---|---|---|---|
| Token guessing | Low | High | Yes: 128-bit DB token, uniform 404, throttling |
| XSS via note/title/artist/play_url | Med | High | Yes: escape all, CHECK allowlist, noopener |
| Scraping of tokens from logs/referrers | Med | Med | Partly: no-referrer, no third-party scripts, host logs may hold tokens (policy states this) |
| Forwarded/screenshotted intimate notes | High | High | Partly: expiry default 90 days, revoke; irreducible |
| auth.users using(true) in partner migration | High if applied | High | Yes only while unapplied (hard gate) |
| Abuse/harassment via anonymous link | Med | Med | Partly: report link, takedown |
| Prompt injection via lyrics/note into generate_insight | Med | Low | Unspecified: owner must verify note is never fed to the LLM |
| Secret leakage (host secret) | Low | High | rotation by redeploy |
| Sender account deletion leaves content | Low | Med | Yes: cascade |
Audit logging: takedowns and revokes are timestamped (revoked_at); no further trail is specified (accepted for v1).

**Section 4: Data flow and interaction edge cases.**
| INTERACTION | EDGE CASE | HANDLED |
|---|---|---|
| Tap Send twice | duplicate rows | Y: client draft id, update-on-resend |
| Cancel share sheet then edit note | stale note | Y: note editable until completed share, then locked |
| Receiver opens revoked link | stale cache | Y: no-store both |
| Link preview crawler | counts as view | Accepted (ops-only) |
| Long note / emoji / RTL | CHECK 500 chars counts characters not bytes | Y; client counter must match Postgres char_length |
| Account switch with persisted draft | wrong sender | Y: draft discarded |
| Song with non-Latin title in search URL | encoding | Gap: URL-encode term (add to tests) |
Async ordering: revoke vs concurrent page fetch: invariant "revoked link never returns 200 after revoke commit"; `share_view` reads `revoked_at` in the same query that increments view_count, so there is no window beyond one in-flight request; a test with a paused fetch must show at most the already in-flight response.

**Section 5: Code quality.** New code is mostly outside the repo's existing patterns (host function, Edge fn). Reuse: `SupabaseClientManager`, existing theme and Settings structure; do not copy the Partner views' query patterns until item 1 is decided. Over-engineering: share_view_hits (dropped), Odesli (dropped). Under-engineering: no `ShareService` boundary specified; recommend one Swift type owning insert/update/revoke. Edge cases: nil/empty/boundary covered above.

**Section 6: Test review.**
```
 NEW THING                    TYPE        HAPPY            FAILURE                    EDGE
 song_shares CHECK/RLS        SQL test    insert ok        javascript: URL, 501 chars, foreign sender, token update   short token
 update trigger               SQL test    note/revoked ok  view_count/token change fails  lock after completed share
 share_view                   integration 200 JSON         404 uniform, 503, no secret    expired boundary
 host function HTML           integration og:title, headers script note renders literally  RTL/emoji
 send flow                    XCUITest    send, share sheet cancel+resend one row   offline  draft after relaunch
 revoke list                  XCUITest    revoke           offline retry              revoked listed
 iTunes match                 unit        match            no match, wrong song skip  non-Latin
 valence branch               prompt eval positive wording  refusal/empty             wound regression
```
Prompt/LLM change: the valence branch touches `generate_insight`; CLAUDE.md names no eval patterns, so the owner must add a small golden set (10 gift songs, 10 wound songs) as the baseline. Hostile-QA test: replay 1,000 random tokens. 2am-Friday test: revoke-then-reload returns 404. Chaos test: kill the Edge Function mid-request and confirm 503. Flakiness: any test using live iTunes/Gemini must be stubbed.

**Section 7: Performance.** One indexed lookup per view (`share_token` unique index); view_count update is a single-row write. Slowest paths: host to function hop (budget p95 1.5 s), iTunes Search at send (timeout 3 s then null), Gemini (existing). No N+1 or pooling concerns at this scale.

**Section 8: Observability.** Needed on day 1: Edge Function logs with token hash prefix (never the token), counts of 200/404/503/429, secret-mismatch alert, count of shares created per day, play_url null rate. Metric that says it works: shares created, receivers reaching playback (self-reported). Runbook: takedown = set revoked_at via service role; secret rotation = redeploy host and function. A bug reported 3 weeks later is reconstructable from share row timestamps and function logs only if logs are retained; accepted.

**Section 9: Deployment.** Migration is additive (new table); safe zero-downtime; deploy order: migration, Edge Function, host function, then app build via TestFlight. Rollback: revoke all shares, remove host route, app hides Send via a remote flag or build revert. Feature flag: recommend a simple server-side flag or build config so Send can ship dark in TestFlight. Smoke test after deploy: create share, curl page, revoke, curl 404.

**Section 10: Long-term trajectory.** Debt: stale superseded text in this document, partner moat undecided, no analytics by design (measurement is manual). Reversibility 4/5 (new table, new host; one-way part is the public URL domain, which every sent link embeds: choose a domain you will keep). Platform potential: tokens and a hosted page are the base for later reply/receipts. SELECTIVE retrospective: the accepted play_url and HTML-hosting items are load-bearing; deferred send-back is the likely first v2.

**Section 11: Design and UX (UI scope).**
| FEATURE | LOADING | EMPTY | ERROR | SUCCESS | PARTIAL |
|---|---|---|---|---|---|
| Send sheet | insight skeleton | prompts + empty note | inline retry | share sheet | no insight, no match |
| Receive page | n/a (server-rendered) | n/a | generic 404/503 | song, note, play | no play_url: search link |
| Shared songs list | spinner | "nothing shared yet" | retry | revoked state | offline |
Journey: the sender feels exposed at Send; the confirm step should read as a relief ("this is what you're saying") and the receive page must feel like a letter, not a product ad (CTA small). AI-slop risk: generic card layout; use the app palette (#0A0A19 to #1E0C3C gradient, #B478FF accent). Accessibility: Dynamic Type for the note, 44pt targets, VoiceOver order song then note then play. Responsive: mobile-first page. Run /plan-design-review (Phase 2 follows).

**NOT in scope (CEO).** Deferred (TODOS.md): sender opened receipt, send-back from receive page, four light archetypes and icons. Rejected: scheduled send; Odesli/Songlink in v1; `share_view_hits` table; account-based partner feed as a receive path (pending User Challenge).
**What already exists.** song_events/shadow_insights/partner_links + owner RLS; generate_insight; valence column; SomaticPractice content; theme; SupabaseClientManager; archetype pipeline; Partner views (uncommitted).
**Dream state delta.** Moves from solo journal to one-way send with a reflection; leaves two-sided history, receipts and reply for later; moat (insight-to-note scaffold) is real but not yet visible to the receiver.

**Error and Rescue Registry:** 8 rows above, 1 gap (generate_insight failure modes unverified), 0 critical.
**Failure Modes Registry**
| CODEPATH | FAILURE | RESCUED | TEST | USER SEES | LOGGED |
|---|---|---|---|---|---|
| share_view | host secret rotated mid-flight | Y | Y | 503 page | Y |
| revoke | CDN serves stale 200 | Y (no-store) | Y | 404 | n/a |
| send | iTunes wrong match | Y | Y | confirm/skip | n |
| generate_insight | refusal/empty (valence prompt) | unknown | N | unknown | unknown |
| platform | partner migration applied accidentally | N (process gate only) | N | all emails readable | n/a |
Critical gaps: 2 (generate_insight failure behavior unverified; accidental application of the auth.users policy has only a process gate). Mitigation for the second: rename the migration file to `.sql.disabled` or move it to docs until item 1 is decided.

**Decision Audit Trail**
| # | Phase | Decision | Class | Principle | Rationale | Rejected |
|---|---|---|---|---|---|---|
| 1 | CEO | Mode SELECTIVE EXPANSION | Mechanical | P6 | added capability | HOLD |
| 2 | CEO | Accept play_url + search fallback | Mechanical | P1 | core job gap | skip |
| 3 | CEO | HTML on static host | Mechanical | P1,P5 | Supabase text/plain rewrite | default domain |
| 4 | CEO | Starter prompts | Taste | P2 | tiny blast radius | none |
| 5 | CEO | Defer opened receipt, send-back, archetypes | Taste | P3 | not needed to test the wedge | add now |
| 6 | CEO | Default 90-day expiry | Taste | P1 | sensitive content | forever |
| 7 | CEO | Soften takedown SLA | Mechanical | P5 | solo operator | 24h |
| 8 | CEO | Spec review stopped at cap with addendum | Mechanical | rule | 3-launch cap | more rounds |
| 9 | CEO | Item 1 kept, queued as User Challenge | User Challenge | n/a | both voices doubt it | auto-remove |
| 10 | CEO | Thin-slice-first queued as User Challenge | User Challenge | n/a | native + primary agree | auto-resequence |

**Completion Summary (CEO).** Mode SELECTIVE EXPANSION; Step 0: 3 accepted, 3 deferred/skipped scope proposals plus 4 build-item dispositions; Sections: arch 3 issues, errors 8 paths/1 gap, security 9 threats/3 high residual, data/UX 7 edge cases/1 unhandled, quality 3, tests diagram + 1 gap (LLM eval), perf 0, observability 3 gaps, deploy 2 risks, trajectory reversibility 4/5, design 3 states tables; NOT in scope written; failure modes 5 rows/2 critical gaps; outside voice N/A (codex not installed); Lake Score N/A (no scored 0D questions answered by the user); Diagrams: architecture, state; Unresolved decisions: 2 User Challenges + 3 taste items for the final gate.

<!-- autoplan-accepted:ceo -->
- The receive page must give the receiver a way to play the song (streaming link or deep link), not only title/artist. Verify: open a share URL on a phone with no app installed and reach playback in one tap.
- The share page HTML must be served from a host/domain that returns Content-Type text/html (Supabase default domain rewrites text/html to text/plain). Verify: curl -I on the public share URL shows text/html and a browser renders it.
- The send sheet offers optional starter prompts for the note; the note stays the sender's own words (no AI-written note). Prompts are an inline list of 5 to 8 short questions in the send view (for example "What did your body do?", "What do you wish they knew?"), written from the somatic wording already used in `SomaticPractice.swift`. Verify: UI test that the note field is empty by default and required.
- Playable link source (amends item 2 and item 4): `song_shares` gains `play_url text null` and `provider text null`. The iOS app fills `play_url` at send time from the Apple Music/MusicKit or iTunes Search match, with an Odesli/Songlink lookup as an optional upgrade; if no match is found it stays null and the page shows a "Search this song" link built from title and artist. The lookup is server-side or in-app only; the receive page loads no third-party scripts. Verify: sharing a song with no match still renders a working page.
- Hosting and route (amends item 4): `share_view` returns JSON `{title, artist, note, play_url}` (or 404) from a Supabase Edge Function; a static host on a custom domain (for example Cloudflare Pages or Vercel) serves `/s/<token>` HTML that fetches that JSON and renders it. The domain is decided in week 1 and the iOS share URL uses it. Verify: `curl -I https://<domain>/s/<token>` returns text/html.
- Rate limiting (amends item 4): per-IP limiting is enforced at the static host/CDN edge (Cloudflare rules) plus a small `share_view_hits` counter keyed by token hash for burst detection; identical 404 body and status for unknown, revoked and expired tokens. Verify: 100 unknown-token requests in a minute are throttled and all return the same body.
- Escaping and abuse (amends item 4): the note is rendered as text only (HTML-escaped, newlines preserved), length-capped at 500 characters on client and in a database CHECK. Verify: a note containing `<script>` renders literally.
- Lifetime and lifecycle (resolves open questions): links never expire by default; `expires_at` stays null unless the sender sets one; revoke is available any time. Deleting an account cascades to `song_shares` (FK on delete cascade). The view counter is a `view_count int` on `song_shares`, stored for operations and not shown to the sender in v1. Verify: deleting a test user removes its shares and the link returns 404.
- Send flow failure paths (amends item 3): if the insight is slow or fails the sender can still write a note without it; the `song_shares` row is created only when the user taps Send, and the share sheet reuses that row if the user cancels and taps again (no duplicates). Verify: cancel then resend yields one row.
- Receive CTA (resolves open question): iPhone visitors see an App Store link once a listing URL exists, and a "Coming soon" line before launch; non-iPhone visitors see the same page with the text "Available on iPhone". Verify: page renders correctly with iPhone and Android user agents.
- Deferred by taste (item 5): the four new light archetypes and their generated icons move to TODOS.md; the valence question and the `generate_insight` valence branch stay in scope and are sequenced before items 6 and 7. Verify: a positive-valence log produces appreciative wording, not wound language.
- CONSOLIDATED v1 SHARE SPEC (supersedes conflicting body text in items 2, 3, 4, 5, sequencing and open questions; spec-review round 2):
  - Schema, migration `20261007000001_song_shares.sql` (separate from the partner migration): `song_shares(id uuid pk default gen_random_uuid(), sender_id uuid not null references auth.users on delete cascade, event_id uuid references song_events on delete set null, song_title text not null check (char_length(song_title) between 1 and 200), artist text not null check (char_length(artist) between 1 and 200), sender_note text not null check (char_length(sender_note) between 1 and 500), share_token text not null unique, recipient_hint text null check (char_length(recipient_hint) <= 80), play_url text null check (play_url ~ '^https://(music\.apple\.com|open\.spotify\.com|song\.link|youtu\.be|www\.youtube\.com)/'), provider text null check (provider in ('apple','spotify','songlink','youtube')), view_count int not null default 0, created_at timestamptz not null default now(), revoked_at timestamptz null, expires_at timestamptz null)`. Owner-only RLS (insert/select/update/delete where sender_id = auth.uid()). Verify: inserting a `javascript:` play_url, a 501-char note, or a foreign sender_id fails.
  - Single request path: `https://<domain>/s/<token>` is served by a host-side function on the static host (for example a Cloudflare Pages Function) that calls the Supabase Edge Function `share_view` (`POST /functions/v1/share_view`, deployed with `--no-verify-jwt`, requires a shared secret header from the host, CORS closed) and renders the complete HTML on the server. This replaces client-side JSON rendering and makes the Open Graph tags (title only, never the note, with a generic image) visible to link-preview crawlers. The Edge Function sets `Cache-Control: no-store`; the host function sets `Cache-Control: no-store` on 404 and `private, max-age=0` on 200 so revoke takes effect immediately. Verify: crawler fetch shows og:title; revoke then reload returns 404 within seconds.
  - Page requirements (host function): `noindex`, `Referrer-Policy: no-referrer`, no third-party scripts, all dynamic fields (title, artist, note) HTML-escaped, play link rendered with `rel="noopener noreferrer"`, a "Report this message" mailto link in the footer, and the "Coming soon" or "Available on iPhone" CTA chosen by user agent. Verify: curl -I shows text/html and the headers; a note containing `<script>` renders literally.
  - Token probing and throttling: the Edge Function rejects requests lacking the host secret, so only the host edge is reachable; per-IP limiting is a host rule; throttled responses may return 429 and that is the only permitted difference from the identical 404 for unknown, revoked and expired tokens. The `share_view_hits` table is dropped; `view_count` on `song_shares` is the single counter and unknown tokens are not counted. Verify: direct call to the function without the secret returns the same 404; 100 unknown tokens in a minute are throttled.
  - Send flow: the app creates the `song_shares` row on first Send and keeps its `id` in the draft (persisted across relaunch); cancelling the share sheet and resending updates that row's note instead of inserting; archetype is not sent to the receiver in v1. `play_url` comes from the iTunes Search/Apple Music match at send time; the Odesli/Songlink "upgrade" is removed from v1. Verify: edit-after-cancel yields one row with the latest note.
  - Starter prompts (fixed list, inserted only on tap, never auto-filled): "What did your body do when it started?", "What does this song say that I can't?", "What do I wish you knew?", "What memory or moment is this?", "What do I want you to feel hearing it?". Verify: tapping inserts text the sender can edit; the empty note blocks Send.
  - Sequencing (replaces the Sequencing section): Week 1: domain, static host, Supabase `share_view` spike proving the HTML path, MusicKit-vs-iTunes decision (iTunes Search is the v1 source; MusicKit stays independent), and migration `song_shares`. Weeks 1-2: send flow. Weeks 2-3: receive page, OG, throttling, revoke list. Week 3: valence question and `generate_insight` valence branch. Week 4: item 6 onboarding only (App Store copy rewrite waits until after the first real sends) and item 7 polish. Success test: the founder's wife sends at least 3 real songs and at least 2 receivers reach playback. App Store submission must answer user-generated-content guideline 1.2 (report link, ability to revoke) and update the privacy policy and privacy labels for shared notes; host logs containing tokens have a 7-day retention.
  - Item 1 gate: the partner migration `20260823060001_partner_read_policy.sql` stays unapplied and item 1 work is gated on the Phase 4 User Challenge; items 2 to 4 proceed independently of it. If item 1 is kept, its SELECT policies must not expose `shadow_insights` or MINIMAL/SUMMARY/FULL content beyond what decisions 2 and 4 allow, and the invite flow adds no notifications beyond the share sheet.
  - Open questions reconciled: link lifetime (resolved: no expiry, revocable), custom domain (resolved: required), Android CTA (resolved: "Available on iPhone"), vulnerability control (resolved for v1: receiver sees title, artist, note and play link only), bidirectional partner model (deferred with item 1 and TODOS.md send-back).
- ROUND-3 ADDENDUM (applied after the third and final spec review; not re-reviewed). Authoritative over all earlier body text: where item 2 to 5, Sequencing or Open questions disagree with the CONSOLIDATED v1 SHARE SPEC or this addendum, the spec and addendum win and implementers must not build from the superseded text (GET `/s/<token>` Edge Function HTML, `share_view_hits`, client-side JSON rendering, archetypes sent to the receiver, four light archetypes, "Week 1: item 1").
  - Token: `share_token` is generated by the database as `encode(gen_random_bytes(16),'base64url')` (default), with `check (char_length(share_token) >= 22)`; the client never supplies it. Verify: a short or client-supplied token insert fails.
  - `play_url` allowlist also accepts `itunes.apple.com`; the app normalizes iTunes Search links to `music.apple.com` when possible and shows the matched title/artist for the sender to confirm or skip; offline or no match sends with `play_url` null. The fallback "Search this song" link goes to `https://music.apple.com/search?term=<title+artist>` and is built at render time, never stored. Playback means a store link or 30-second preview is acceptable for v1.
  - Update restriction: sender UPDATE is limited by a trigger or column privileges to `sender_note`, `revoked_at`, `expires_at`, `recipient_hint`; `share_token`, `view_count`, `sender_id`, `play_url` and `provider` cannot change after insert (play_url may be set once at insert). The note is locked after the share sheet reports a completed share; before that, resend updates the same row. The persisted draft id is discarded on logout, account switch, or if the row is revoked or deleted. Verify: update of `view_count` as the sender fails.
  - `view_count` is incremented atomically by the Edge Function (service role) on each successful 200 lookup; crawler and retry hits may inflate it and it is ops-only and approximate.
  - Error states: Edge Function 5xx or timeout renders a generic "Something went wrong, try again" page with `no-store` and status 503, never the 404 body. Both 200 and 404 from the host use `Cache-Control: no-store`. The host secret lives in host and Supabase function secrets and is rotated by redeploying both. Verify: stub the function to 500 and confirm the 503 page.
  - Revoke list (item 3 restated): Settings > "Shared songs" lists shares (title, artist, date, state); Revoke asks for confirmation, sets `revoked_at`, and shows an error with retry if offline; revoked shares stay listed as Revoked; delete removes the row. Verify: UI test of revoke offline and online.
  - Abuse: the report mailto goes to a monitored address; takedown is the operator setting `revoked_at` with the service role within 24 hours; sender display name is not shown in v1, and the sender may write their own name in the note. Host logs must not store tokens beyond what the host forces; no retention promise is made beyond the host's default and the privacy policy says so.
  - Schedule: Week 1 adds TestFlight build setup and a spike with explicit pass criteria (host function renders HTML with og:title and text/html, calls the secret-gated Edge Function, p95 under 1.5 s from a phone); if the spike fails or per-IP limiting is unavailable on the chosen host plan, fall back to an in-function limiter using a small Supabase table keyed by hashed IP. Cut line: item 7 polish, then the valence branch, slip before any share-loop work. Item 1 is unscheduled and blocked on the Phase 4 User Challenge. New migration versions sort after `20260823060001`, so the partner migration must be renumbered or applied with `--include-all` if it is ever applied. The success test is measured by the sender confirming playback with each receiver in person or by message; no page analytics are added.
  - CTA user agents: iPhone shows the App Store link or "Coming soon"; iPad, Mac and in-app browsers are treated as iPhone-capable; everything else shows "Available on iPhone".
- PHASE 1 AMENDMENTS (from the native CEO review; authoritative over earlier text): (a) Default link lifetime is 90 days (`expires_at` set at insert); the sender may choose 30 days, 90 days or no expiry in the send sheet, and revoke stays prominent. This replaces "links never expire by default". Verify: a new share has expires_at about 90 days out and the link returns the same 404 after it. (b) The abuse promise is "reviewed promptly" with a monitored report address, not a 24-hour SLA. (c) The receive page is a delivery channel in v1; the "growth loop" claim is dropped from v1 success criteria because the App Store CTA reads "Coming soon" until a listing exists. (d) The success test also records, per send, receiver platform (Apple Music vs Spotify vs other), whether the song matched, and whether the sender later reports that the receiver responded, so silence and match rate are measured rather than assumed. (e) The MusicKit decision in item 7 is reconciled: iTunes Search is the v1 source of play_url and MusicKit stays unshipped unless a later decision revives it. Verify: no MusicKit entitlement is required for the share flow.
<!-- /autoplan-accepted:ceo -->

### Phase 2: Design review (UI scope; auto-decided)

**Step 0.** Initial design completeness 3/10: schema, security and lifecycle are specified; no surface has a layout, copy or full state set, and the emotional arc is unaddressed. A 10 has wireframe-level specs and exact copy for three surfaces (send sheet, receive page, Shared songs list) plus states, a11y and the palette. No DESIGN.md exists (gap; `THEME_REDESIGN.md` and `MusicShadowTheme.swift` are the de facto system; run /design-consultation later). Mockups: designer unavailable in this auto run, text review only.

**DESIGN OUTSIDE VOICES - LITMUS SCORECARD** (Codex N/A: not installed; native completed)
```
  Check                                   Claude  Codex  Consensus
  1. Brand unmistakable in first screen?   NOT SPEC'D  N/A  N/A
  2. One strong visual anchor?             YES (the note)  N/A  N/A
  3. Scannable by headlines only?          NOT SPEC'D  N/A  N/A
  4. Each section has one job?             NO (send sheet)  N/A  N/A
  5. Cards actually necessary?             NOT SPEC'D  N/A  N/A
  6. Motion improves hierarchy?            NOT SPEC'D  N/A  N/A
  7. Premium without decorative shadows?   NOT SPEC'D  N/A  N/A
  Hard rejections triggered: none known (nothing specified enough to reject)
```
Native findings F1-F18 (2 critical, 8 high, 8 medium). Dispositions: structural gaps auto-fixed (P5/P1); taste items marked TASTE; none is a User Challenge.

| Pass | Before | After | Notes |
|---|---|---|---|
| 1 Info architecture | 4 | 8 | receive page and send sheet order specified |
| 2 Interaction states | 3 | 8 | full state tables added |
| 3 Journey and emotional arc | 3 | 8 | preview step, honest revoke copy, receiver landing line |
| 4 AI slop risk | 5 | 7 | no cards, one anchor; typography choice left as TASTE |
| 5 Design system | 4 | 7 | no DESIGN.md; palette and tokens named |
| 6 Responsive and a11y | 3 | 8 | mobile-first, Dynamic Type, VoiceOver, contrast |
| 7 Decisions | | | 4 resolved, 3 TASTE for the gate |
Overall design score (lowest rated pass): 3 -> 7.

**Decisions made (auto).** (1) Receive page order: one-line framing, the note large, song + one primary Play control, quiet CTA, small footer. (2) Send sheet: note field is primary and focused; AI insight is a collapsed secondary card; prompts chips; match confirmation, expiry control and Send below; Send is the only prominent button. (3) "Preview as they'll see it" step before the share sheet. (4) Real one-tap playback via a native `<audio>` element using the iTunes 30-second `previewUrl`, with the store link as a secondary "Open in Apple Music" link; needs `preview_url` on `song_shares` and a CHECK allowing only `https://audio-ssl.itunes.apple.com/` and `https://*.mzstatic.com/` hosts. (5) Receive-page state table with human 404 copy. (6) Send-view state set, 400-char counter, hard stop at 500. (7) Shared songs list states and Copy link / Share again. (8) Optional "From" name, 40 chars, escaped. (9) OG title "Someone sent you a song", no song title in the preview. (10) Report is a small muted "Report a problem" link; the "Coming soon" line is omitted until a listing URL exists; the page tells the receiver they can reply to the sender directly. (11) Partner UI hidden behind a flag in the v1 build. (12) One-screen first-run explainer on the send sheet.
TASTE for the final gate: T1 typography and exact palette application on the web page (recommend system serif for the note on the app gradient #0A0A19 to #1E0C3C with accent #B478FF, light variant via prefers-color-scheme); T2 whether the insight card is collapsed or hidden entirely on positive valence; T3 a "From" name versus signing inside the note.

**UI spec (ASCII).**
```
 RECEIVE PAGE (mobile first, 1 column, max 36rem)       SEND SHEET
 +---------------------------------+                    +---------------------------------+
 | Someone shared a song with you  |                    | Send this song         (X)      |
 | From Alex  (only if provided)   |                    | [ note field, focused    ]      |
 |                                 |                    | [ 412 / 500 ]  chips: prompts   |
 |  "the note, large, preserved    |                    | > What this song did (insight)  |
 |   line breaks, wraps, RTL ok"   |                    | Song: Title - Artist [Change]   |
 |                                 |                    | Link lasts: (30d) (90d) (none)  |
 |  Title - Artist                 |                    | [ Preview as they'll see it ]   |
 |  [ > Play 30s preview ]         |                    +---------------------------------+
 |  Open in Apple Music (small)    |                    Preview screen -> [ Send ] [ Edit ]
 |                                 |
 |  You can reply to them directly.|
 |  Report a problem  (muted)      |
 +---------------------------------+
```
**Receive-page states.** ok; ok without preview (Play hidden, "Search this song" link only); unavailable (404/revoked/expired): "This link isn't available. It may have expired or been removed by the sender. If you were expecting something, ask them to send it again."; error 503: "Something went wrong. Try again in a moment."; throttled 429: same copy as 503; no-JS: fully server-rendered, inline CSS, no blocking requests, so it paints on first byte. **Send-view states.** insight loading / ready / failed ("No reflection yet, you can still write your own words"); match searching / one / several (pick) / none / offline ("Sending without a play link"); note empty / valid / near cap (counter from 400) / at cap (hard stop, paste over limit offers truncation) / locked after share ("This note was shared. Revoke the link to write a new one."); send idle / creating / failed (retry, draft kept) / created-not-shared ("Link ready, not shared yet") / shared. A restored draft shows "Draft restored". **Shared songs list.** empty ("Nothing shared yet"), loading, offline error, row = title, artist, date, state (Active, Expires in N days, Expired, Revoked), row actions Copy link and Share again for active shares, Revoke with confirm "They may have already seen it. Turning off the link stops anyone else from opening it.", Delete with confirm. **Accessibility.** Dynamic Type through the note and prompts, 44pt targets, VoiceOver labels for counter ("412 of 500 characters"), chips, revoke; web: semantic landmarks, `lang`, contrast 4.5:1, `prefers-color-scheme`, reduced motion respected, no motion beyond a 150 ms fade.
**NOT in scope (design).** Reply UI, receipts, theming per sender, animations beyond the fade, a DESIGN.md (deferred, recommend /design-consultation). **What already exists.** App theme (`MusicShadowTheme.swift`), Settings structure, `EmptyStateView`, `ErrorStateView`, `AccessibilityHelpers.swift`, brand assets in `docs/brand/`.

<!-- autoplan-accepted:design -->
- Receive page order and copy: one-line framing ("Someone shared a song with you"), optional "From <name>", the note large with preserved line breaks and RTL support, song title and artist with one primary Play control, a small "Open in Apple Music" link, a line "You can reply to them directly.", and a muted "Report a problem" footer link; the "Coming soon" CTA line is omitted until an App Store URL exists. Verify: screenshot at 375 px and curl output match the order; the note is visually the largest text.
- In-page playback uses a native audio element with the iTunes 30-second `previewUrl`; add `preview_url text null` to `song_shares` with a CHECK limiting it to `https://audio-ssl.itunes.apple.com/` and `https://*.mzstatic.com/`; when null, Play is hidden and only the search link shows. This amends the earlier play_url allowlist note: `play_url` remains the store link. Verify: an iPhone with no Apple Music account plays the preview in one tap with no third-party script.
- OG preview: title "Someone sent you a song", neutral description, generic image; never the song title or the note. Verify: crawler output.
- Receive-page state table: ok, ok-without-preview, unavailable (human copy above, identical body for unknown/revoked/expired), 503 error, 429 throttled; all server-rendered with inline CSS and no blocking requests. Verify: stub each state and compare.
- Send sheet hierarchy: note field primary and focused; AI insight in a collapsed secondary card; starter prompts as chips that insert text at the cursor (single-use per tap, text remains editable); song match, expiry selector (30 days, 90 days default, no expiry) and Send below; Send is the only prominent button; 400-character counter appears from 400 and input hard-stops at 500 with truncation on paste. Verify: UI tests for chip insertion, counter and cap.
- Send-view states: insight loading/ready/failed, match searching/one/several/none/offline, note empty/valid/near cap/at cap/locked, send idle/creating/failed/created-not-shared/shared, "Draft restored" cue. Verify: each state reachable in a UI test or preview.
- Preview step: after the note, a "Preview as they'll see it" screen renders the real receive layout; Send on that screen is the final tap; copy states that the link can be turned off later but they may already have seen it. Verify: the preview uses the same renderer or markup as the page.
- Shared songs list: empty, loading, offline error, row states Active / Expires in N days / Expired / Revoked, Copy link and Share again for active shares, revoke and delete confirmations with honest copy. Verify: UI tests.
- Optional "From" display name in the send sheet (40 characters, escaped, shown as "From <name>"); stored in a new `sender_display_name text null` column with a 40-character CHECK. Verify: `<script>` in the name renders literally.
- First-run explainer: a single screen the first time the send sheet opens, saying what the receiver sees, that the link needs no account, and how to turn it off. Verify: appears once, not again after dismissal.
- Partner UI (PartnerFeedView entry points and Settings partner invite) is hidden behind a build flag in the v1 build until the item 1 decision. Verify: no partner screen reachable in the TestFlight build.
- Accessibility: Dynamic Type, 44 pt targets, VoiceOver labels (counter, chips, revoke), web `lang`, semantic landmarks, 4.5:1 contrast, `prefers-color-scheme`, reduced-motion respected. Verify: VoiceOver walkthrough and Lighthouse accessibility check.
<!-- /autoplan-accepted:design -->

### Phase 2.5: DX review (auto-decided; scope note)

Applicability: the DX detector fired on the term "onboarding" (2 matches), a false positive for a consumer app. The plan does contain an internal developer surface (the `share_view` Edge Function contract, host function, migrations, secrets, runbooks), so the review ran as an **API/Service** review for the solo implementer-operator. Mode: DX POLISH. No public API, CLI, SDK or community exists; Passes 5 and 7 are scored on that basis. The Hall of Fame reference file was not loaded; scores use the rubric in the skill. No competitor measurements exist: all times below are estimates.

**Persona card.** Who: the founder (plus Claude agents) returning to this repo. Context: builds the share loop in weeks 1 to 3, operates it afterwards. Tolerance: about 30 minutes to a working end-to-end share before motivation drops. Expects: one spec, one command per step, a way to test without a phone.

**Empathy narrative (predicted, not observed).** I open `docs/send-receive-plan.md` and find four layers of text that disagree: the body still says the Edge Function returns HTML at GET `/s/<token>`, the addendum says the host renders it, and a later bullet adds columns I have to merge by hand. I create the table from the wrong one and the page returns text/plain. I deploy `share_view` with JWT checks on and get a 401 from the host with no hint why. When the founder's wife says her link is broken, every failure looks like the same 404, so I cannot tell a rotated secret from a revoked link. I wish for one spec, one verify script and one lookup command.

**Competitive benchmark (estimated, no measurements).**
| Tool | Start to result | Time and evidence | DX choice |
|---|---|---|---|
| Supabase Edge Function quickstart | clone to deployed function | ~10 min, estimated from docs, not measured | single CLI deploy |
| Cloudflare Pages Function quickstart | repo to live route | ~10 min, estimated | git push deploy |
| This plan, as written | clone to seeded share rendering as HTML | unknown, est. 90 min (no path, 4 layered texts, 6 manual steps) | none |
Target (auto, taste): under 30 minutes, estimated, from clone to `curl https://<domain>/s/<seeded token>` returning text/html with a seeded note. Tier: Competitive for a two-service setup.

**Magical moment.** The seeded share URL opening on the operator's phone and playing the preview in one tap; delivered by a `scripts/seed-share` command that prints a working URL (lowest-effort vehicle, within existing capabilities).

**Consensus table** (Codex N/A: not installed)
```
  Dimension                           Claude  Codex  Consensus
  1. Getting started < 5 min?          NO (not in the plan)  N/A  N/A
  2. API/CLI naming guessable?         PARTLY  N/A  N/A
  3. Error messages actionable?        PARTLY (receiver yes, operator no)  N/A  N/A
  4. Docs findable & complete?         NO  N/A  N/A
  5. Upgrade path safe?                YES (additive)  N/A  N/A
  6. Dev environment friction-free?    NO  N/A  N/A
```
Native findings F1-F18: 1 critical, 6 high, 11 medium. All auto-accepted as in-scope DX work except F17 (sender Extend control), recorded as intentionally out of v1 (TASTE).

**Developer journey map**
| Stage | Developer does | Friction | Status |
|---|---|---|---|
| Discover | reads the plan | four contradicting layers | fixed: flattened `docs/share-spec.md` |
| Install | link Supabase, set secrets, create host project | no sequence, secret in two places | fixed: Share TTHW README section |
| Hello world | deploy function + host, open a seeded link | no seed or verify command | fixed: seed and verify scripts |
| Real usage | iterate on page and send flow | no contract table, renderer duplicated between preview and page | fixed: contract table, shared renderer |
| Debug | a link "doesn't work" | identical 404s hide cause | fixed: server-side reason codes, operator lookup script |
| Upgrade | change the schema or secret | partner migration ordering trap, secret rotation by hand | fixed: deferred folder, runbook |

**First-time developer confusion log (predicted).** T+0:00 opens the plan, cannot tell which item 4 is current. T+0:30 builds the table from item 2 and misses `preview_url`. T+1:00 calls the function from the host and gets 401 (JWT on). T+2:00 sees text/plain from the default domain and rediscovers the Supabase limitation. T+3:00 asks for help. All five points are addressed by the accepted requirements below.

**DX scorecard**
| Dimension | Before | After |
|---|---|---|
| Getting started | 3 | 8 |
| API/CLI (function contract) | 4 | 8 |
| Error messages | 5 | 8 |
| Documentation | 3 | 7 |
| Upgrade path | 6 | 8 |
| Dev environment | 4 | 7 |
| Community | 5 | 5 (n/a: solo, private repo) |
| DX measurement | 4 | 7 |
TTHW (estimated): 90 min to 30 min. Competitive rank: Competitive after fixes. Magical moment: designed via seed script. Product type: API/Service (internal). Mode: DX POLISH. Overall DX: 4 to 7 (lowest scored pass 7, excluding the community row marked n/a).
**DX implementation checklist**
```
[ ] Clone to seeded share rendering as text/html in under 30 minutes (estimated; measure once)
[ ] One command seeds a share and prints its URL
[ ] share_view contract table exists and matches the Swift CodingKeys
[ ] Every operator error has problem + cause + fix
[ ] scripts/verify-share.sh passes (headers, escaping, uniform 404, 503 stub)
[ ] Runbook has takedown, secret rotation, SHARE_DISABLED kill switch
[ ] Partner migration moved out of the deploy path
[ ] Docs: one flattened spec, superseded text marked dead
```
**NOT in scope (DX).** Public API docs, SDKs, community channels, sender "Extend" control (F17), telemetry beyond view_count, Hall of Fame extras. **What already exists.** Supabase CLI and migration folder, `generate_insight` function and its EDGE_FUNCTION doc, `SMOKE_TEST_CHECKLIST.md`, `QA_NOTES.md`.

<!-- autoplan-accepted:dx -->
- Flattened spec: before coding, create `docs/share-spec.md` as the single authoritative input (final `CREATE TABLE` with every column and CHECK: `preview_url`, `sender_display_name`, itunes.apple.com allowance, `expires_at default now() + interval '90 days'`; request path; page states; send flow; schedule; ops), grouped by area (data, host, iOS send, receive page, ops, App Store). The older text in this plan is marked superseded. Where the design phase's bullets conflict with earlier text, the design bullets win. Verify: an implementer can build the schema from that file alone.
- Edge Function contract table (15 lines or fewer): `POST /functions/v1/share_view`, secret header name, request body `{token}`, 200 body `{title, artist, note, play_url, preview_url, sender_display_name, expires_at}`, 404, 503, 429; field names pinned in Swift `CodingKeys`. Verify: contract test hits each status.
- Immutable columns are enforced by a BEFORE UPDATE trigger that raises on changes to `share_token`, `view_count`, `sender_id`, `play_url`, `preview_url`, `provider`, `song_title`, `artist`, and on `sender_note` after a completed share; column privileges are not used. Verify: SQL test per column.
- Operator observability: the Edge Function logs a reason code (`bad_secret`, `not_found`, `revoked`, `expired`, `disabled`) with a token hash prefix while returning identical bodies; `scripts/share-lookup` (service role, by share id or token hash) prints a share's state; a global kill switch `SHARE_DISABLED=1` on the Edge Function and host function returns the unavailable page for all tokens. Verify: bad secret logs `bad_secret`; kill switch test.
- Operator tooling: `scripts/seed-share` creates a test share and prints its URL; `scripts/verify-share.sh` exits nonzero unless text/html and headers are present, a `<script>` note renders literally, unknown/revoked/expired tokens return identical bodies, and a stubbed function failure yields the 503 page; `docs/share-runbook.md` covers takedown (`revoked_at` via service role), secret rotation (redeploy both), report inbox, kill switch; a "Share TTHW" section documents the setup sequence with a 30-minute estimated target. Verify: run the sequence once from a clean clone and record the time.
- Sender error table: note insert failure, `play_url` CHECK rejection (send continues with `play_url` null), paste over 500, deleted or revoked draft row ("This link was removed. Start a new one."), each with message and retry action. Verify: UI or unit test per row.
- iTunes match picker: show up to 3 results to pick from, or skip. Verify: UI test with a stubbed multiple-result response.
- Portability: the host function is a thin adapter (token, secret, call, respond) and the HTML renderer is a plain shared module also used by the iOS preview step. Verify: the same renderer output is used by both.
- The partner migration `20260823060001_partner_read_policy.sql` moves to `supabase/migrations_deferred/` so it cannot be applied by accident. Verify: `supabase db push --dry-run` does not list it.
<!-- /autoplan-accepted:dx -->

### Phase 3: Eng review (auto-decided; runs last on the fully amended plan)

**Step 0 Scope Challenge: scope accepted as-is** (autoplan override: never reduce). Code read: `supabase/functions/generate_insight/index.ts` (334 lines; already reads `valence`, 401 on missing Authorization, 502 on Gemini errors), `SupabaseClientManager.swift` (singleton; has an in-flight dedupe pattern for insight generation that the send flow can mirror), `MusicSearchService.swift` (MusicKit search hard-disabled: `isMusicKitEnabled = false` "due to crashes"), `Music ShadowTests/Music_ShadowTests.swift` (empty stub; no real tests anywhere), CLAUDE.md (no Testing section). Findings: (1) MusicKit is dead code, which confirms iTunes Search as the play-link source and means a new `ITunesSearchService` is needed rather than reusing `MusicSearchService`; (2) there is no test infrastructure to extend, so test files are new; (3) the publishable Supabase key in source is expected to be public, no issue. Complexity: ~14 planned files (migration + trigger SQL, Edge Function, host function + renderer, deferred-folder move, Swift: ShareService, ITunesSearchService, SendSheet, PreviewView, SharedSongsView, first-run view, Settings entry; scripts and docs) and 3 new services (Edge Function, host function, ShareService), so the complexity gate trips; auto-decided: feature list kept (autoplan: never reduce), structure kept as "Original arrangement" because a smaller arrangement would drop the shared renderer or the verify tooling; recorded as `feature answers: auto-kept; structure: Original arrangement (auto, P3); accepted scope: all accepted amendments; pending remedies: none`.

**ENG DUAL VOICES - CONSENSUS TABLE** (Codex N/A: not installed)
```
  Dimension                           Claude  Codex  Consensus
  1. Architecture sound?               YES (thin adapter + gated function)  N/A  N/A
  2. Test coverage sufficient?         NO (none exists today)  N/A  N/A
  3. Performance risks addressed?      PARTLY (view_count write, fan-out)  N/A  N/A
  4. Security threats covered?         PARTLY (CSP, limiter default, compare)  N/A  N/A
  5. Error paths handled?              PARTLY (idempotency, null expiry)  N/A  N/A
  6. Deployment risk manageable?       PARTLY (week 1 overloaded, DNS)  N/A  N/A
```
Native findings 25 (6 P1-labelled, 13 P2, 6 P3): all accepted except #15 (response cache; recorded as off for v1) and #11 (renderer parity, TASTE: Swift renderer plus golden fixtures chosen over a bundled JS WKWebView).

**Section 1: Architecture.** Native tiebreak P5/P3 (explicit, pragmatic).
```
 iOS ShareService --(upsert id=client UUID, RLS)--> song_shares --(BEFORE UPDATE trigger, daily-create throttle)
   |  ITunesSearchService --> iTunes Search (play_url, preview_url)           ^
   |  SendSheet -> PreviewView (Swift renderer, golden fixtures vs host)     | service role
 Receiver --> host function (CF Pages: secret, call, respond) --POST+secret--> Edge fn share_view
                renderer module (HTML, CSP nonce/hash, no-store)                 | constant-time compare (current|next secret)
                                                                                 | function-side limiter (HMAC(IP) table, purge)
                                                                                 | fire-and-forget view_count++ (GET only, not HEAD)
 Partner path (item 1): unscheduled, deferred folder.
```
Findings: no new coupling to `song_events` beyond an FK with `on delete set null` (shares are snapshots; the delete-event copy must say so, with "also revoke shares of this song"); the function-side limiter becomes the default, host rules are defense in depth; single point of failure remains the host plus the function, covered by the 503 page and kill switch; rollback is revoke-all SQL, kill switch, then a down migration for `song_shares`.

**Section 2: Code quality.** Reuse: mirror `SupabaseClientManager.markInsightGenerationStarted` for an in-flight send guard; keep `ShareService` the single owner of insert/update/revoke; one `unavailable()` builder in the Edge Function and host (DRY, byte-identical bodies); one renderer module on the web side with Swift golden-fixture parity. Over-engineering avoided: no Odesli, no hits table, no `share-lookup` script (a runbook SQL snippet replaces it, saving about a day). Under-engineering fixed below: expiry encoding, idempotency, scalar-count parity. No ASCII diagrams exist in touched files that go stale.

**Section 3: Test review.** Test framework detection: Swift Testing + XCUITest targets exist as empty stubs; no CI, no SQL or Deno tests. Auto-decided (TASTE): adopt pgTAP via `supabase test db` for SQL, `deno test` for the Edge Function, and the host runtime's test runner for the renderer, plus Swift Testing for iOS units.
```
CODE PATHS                                                    USER FLOWS
[+] supabase/migrations/..._song_shares.sql                   [+] Send
  |- CHECKs (note/title/artist/hint/url/token)  [GAP][pgTAP]   |- [GAP][->E2E] log, note, match, preview, Send, receive
  |- BEFORE UPDATE trigger (immutables, shared_at) [GAP][pgTAP] |- [GAP] cancel sheet, edit, resend => one row
  |- RLS owner-only + client id upsert, foreign id [GAP][pgTAP] |- [GAP] lost response retry => one row
  |- daily create throttle                         [GAP][pgTAP]|- [GAP] offline send, insight failed, no match
[+] Edge function share_view                                   [+] Receive
  |- secret current/next, constant-time, missing    [GAP][deno] |- [GAP][->E2E] phone, no app, preview plays
  |- found/unknown/revoked/expired/disabled bytes   [GAP][deno] |- [GAP] dead preview => fallback link
  |- view_count++ GET only, HEAD/bots no            [GAP][deno] |- [GAP] revoked link through CDN twice
  |- limiter HMAC(IP) + purge                       [GAP][deno] |- [GAP] RTL, emoji, 500-char note
[+] host function + renderer                                   [+] Revoke / list
  |- CSP, headers, escaping, no-store, UA CTA       [GAP][int]  |- [GAP] revoke online/offline, delete, extend n/a
  |- 503 on function failure                        [GAP][int]  |- [GAP] account delete cascade
[+] Swift: ShareService, ITunesSearchService, expiry encoding [GAP][unit]  |- [GAP] draft discard on logout/switch
[+] generate_insight valence branch                           LLM: [GAP][->EVAL] 10 gift + 10 wound goldens
COVERAGE: 0/26 paths tested (0%); every path is a planned test. QUALITY: n/a (no existing tests).
GAPS: 26 (2 E2E, 1 eval, 5 pgTAP groups, 4 deno groups, 3 integration groups, 3 unit groups)
```
IRON RULE: no existing behavior is put at risk except `generate_insight` (valence branch edits the prompt): regression contract carried: "wound-valence output is unchanged for existing events", verified by the golden set comparing before/after on the 51 existing events' stored insights. Eval baselines: run the existing generate_insight on 10 stored wound events before editing and compare after. The Test Plan artifact is at `~/.gstack/projects/coachAI-CEO-MusicShadow/macbook-main-eng-review-test-plan-20261007-003710.md`.

**Section 4: Performance.** One indexed lookup on the unique token index; the `view_count` update is fire-and-forget so a burst on one token does not block responses; the 200/no-store policy means every hit reaches Supabase (a viral single link is the only load risk; scale unknown, current users 1; a few-second in-function cache is rejected for v1 because it delays revoke). Slow paths: host to function hop and cold start (spike target p95 1.5 s needs cold-start numbers), iTunes Search (3 s timeout), Gemini (existing). Limiter table: HMAC(IP) with server secret and a retention purge (7 days).

**Failure modes registry**
| CODEPATH | FAILURE | RESCUED | TEST | USER SEES | LOGGED |
|---|---|---|---|---|---|
| expiry encoding | Swift omits nil, "no expiry" becomes 90 days | Y (explicit null or RPC) | planned | correct expiry | n |
| send retry | response lost after commit | Y (client UUID upsert) | planned | one link | n |
| host secret rotation | mismatch window | Y (current+next) | planned | none | Y |
| preview URL rot | audio 404 | Y (error handler) | planned | search link | n |
| unavailable bodies | kill switch differs from 404 | Y (single builder, byte diff) | planned | same page | Y |
| generate_insight valence branch | refusal/empty/regression | partly | planned (eval) | unknown until verified | unknown |
| partner migration | applied by accident | Y (deferred folder + header) | process | n/a | n |
Critical gaps flagged: 1 (generate_insight valence branch lacks an eval baseline until the golden set exists; mitigated by the planned eval, remains a gap until written).

**NOT in scope (eng).** Response caching in the function, Odesli/Songlink, bundled-JS renderer, per-token analytics, down-migration automation beyond a hand-written file, multi-device draft sync. **What already exists.** `generate_insight` valence read, `SupabaseClientManager` in-flight pattern, `EmptyStateView`/`ErrorStateView`, Xcode test targets (empty), `MusicSearchService` (disabled, not reused), Supabase CLI migration workflow.
**Worktree parallelization.** Lane A: `supabase/` (migration, trigger, Edge function, pgTAP/deno tests). Lane B: web host (`web/` or host repo: renderer, host function). Lane C: iOS (`Music Shadow/`: ShareService, ITunesSearchService, views). Lane D: `generate_insight` valence branch + golden set (independent). Order: A first for the contract and schema, then B and C in parallel against the contract table, D any time; merge A+B+C, then verify scripts. Conflict flags: iOS Settings and the partner flag touch `SettingsView.swift` and `PartnerFeedView.swift` (uncommitted edits: commit behind the flag first). 4 lanes, 3 parallel after A / 1 sequential.
**Decision ledger.** Auto-decided rows E1-E19 (accept native findings #1-#10, #12-#14, #16-#24 as written; #11 TASTE; #15 deferred). Approval readiness: PASS for authorized auto-decisions; User Challenges and TASTE rows remain for the final gate.

<!-- autoplan-accepted:eng -->
- Hard gate: write `docs/share-spec.md` before any code and mark the superseded text in this plan as dead; the flattened spec includes a conflict-resolution table whose rulings are: expiry default 90 days (not "never"); OG title "Someone sent you a song" with no song title; Report link text "Report a problem"; no "Coming soon" line; Edge Function returns the full contract (`title, artist, note, play_url, preview_url, sender_display_name, expires_at`); every response `Cache-Control: no-store` and `Vary: User-Agent`; design-phase bullets win over earlier text. Verify: a clean-room reader builds the schema and routes from that file only.
- Add `shared_at timestamptz null` to `song_shares`, set once by the client when the share sheet completes; the trigger blocks `sender_note` changes once it is non-null; documented as a UX guard, not a security boundary; `expires_at` stays sender-mutable (extending an expired link is allowed). Verify: SQL tests.
- Edge Function auth: constant-time secret comparison; accept a current and a next secret so rotation has no window; log reason codes with an 8-character token hash prefix only, never the raw token. Verify: Deno tests for missing, wrong, current, next.
- Limiter: the function-side limiter is the default, keyed by HMAC(client IP, server secret) in a small table with a 7-day purge; host-edge rules are defense in depth; a per-sender share-creation throttle of 50 per day is enforced by a DB trigger. Verify: tests exceed each limit.
- Response policy: all responses use `no-store` and `Vary: User-Agent`; one `unavailable()` builder serves unknown, revoked, expired and kill-switch cases; `scripts/verify-share.sh` asserts the four bodies and status are byte-identical; a CDN test fetches twice, revokes, refetches. Verify: the script.
- CSP on the page: `default-src 'none'; media-src https://audio-ssl.itunes.apple.com https://*.mzstatic.com; style-src 'sha256-<hash of the static stylesheet>'; img-src 'self' data:; base-uri 'none'; form-action 'none'`; audio `error` event hides Play and shows the store or search link; note element has `dir="auto"`. Verify: header check and a dead-URL test.
- CHECK regexes: `preview_url ~ '^https://(audio-ssl\.itunes\.apple\.com|[a-z0-9-]+\.mzstatic\.com)/'`; `play_url` allowlist as in the spec plus `itunes.apple.com`; SQL tests include `https://music.apple.com.evil.com/`, `https://music.apple.com@evil.com/` and `javascript:`; confirm live iTunes preview hosts before launch. Verify: pgTAP.
- Idempotent send: the client generates the share `id` (UUID) and upserts; a retry after a lost response creates one row; an upsert against another user's id fails cleanly with a mapped error row. Verify: unit and pgTAP tests.
- Expiry encoding: the app sends `expires_at` explicitly, including an explicit `null` for "no expiry" (custom encoder or RPC), never omitting the key. Verify: a unit test for each selector value.
- Length parity: the client counts Unicode scalars (`unicodeScalars.count`) to match Postgres `char_length`; tests include family emoji and combining marks.
- Renderer parity (TASTE, chosen): the iOS preview is a Swift renderer; golden-file fixtures run through both the host renderer and the Swift renderer and must match. Verify: fixture test in both runtimes.
- Event deletion: the delete-trigger confirmation says shares of that song remain unless revoked and offers "Also turn off links for this song". Verify: UI test.
- View counting: increments only on GET 200 and are non-blocking; HEAD and unfurl bots do not fail or count. Verify: Deno tests.
- Schedule: remove the MusicKit decision from week 1 (resolved); schedule about 2 days for tooling (`seed-share`, `verify-share.sh`, runbook with a SQL snippet in place of `share-lookup`); domain and DNS are a gating dependency started in week 1; the "30 minute Share TTHW" excludes DNS propagation. A down migration for `song_shares` is hand-written.
- Test infrastructure: add pgTAP (`supabase test db`), Deno tests for the Edge Function, the host runtime's test runner for the renderer, Swift Testing units and XCUITests for the send/revoke flows; the generate_insight valence change ships with a 10 gift / 10 wound golden set and a before/after check on stored wound insights. Verify: `supabase test db`, `deno test`, `xcodebuild test` all run in one documented command list.
- The deferred partner migration file gets a header comment: never apply as written (the `auth.users` `using (true)` policy exposes every email); partner UI is verified hidden by grepping the TestFlight build for reachable entry points; the uncommitted `PartnerFeedView.swift` and `SettingsView.swift` edits are committed behind the flag before send-flow work touches Settings. Verify: grep and a manual walkthrough.
- Audio preview URLs are fetched by the receiver's browser from Apple hosts; the privacy policy discloses this. Verify: policy text present before submission.
<!-- /autoplan-accepted:eng -->

### Final gate overrides (user-approved on 2026-10-07; authoritative over everything above)

User answers at the Phase 4 gate: taste choices 1 to 5 confirmed as recommended (90-day expiry kept; 30-second preview plus store link with Swift renderer and golden fixtures; serif note, optional "From", collapsed insight card; pgTAP, Deno and golden fixtures adopted; deferrals confirmed). Three explicit overrides:

1. **Spotify link (Design amendment).** The receive page adds a small "Search on Spotify" link next to "Open in Apple Music", built at render time as `https://open.spotify.com/search/<url-encoded title and artist>`, never stored, `rel="noopener noreferrer"`, shown for every user agent. It is a plain navigation link: no API call, no third-party script, no CSP change. It lands on search results, not the exact track. Odesli/Songlink stays deferred. Verify: a rendered page contains both links with correctly encoded terms (including non-Latin titles); a title with `<`, quotes or `&` stays escaped.
2. **Challenge 1 resolved: build item 1 is unscheduled.** The partner read path is out of v1. `supabase/migrations/20260823060001_partner_read_policy.sql` moves to `supabase/migrations_deferred/` with the never-apply header, the partner UI stays hidden behind the build flag, and item 1 is revisited only after the first real sends. This replaces "gated on the Phase 4 User Challenge". The uncommitted partner edits in `PartnerFeedView.swift` and `SettingsView.swift` are committed behind the flag or stashed before send-flow work touches Settings.
3. **Challenge 2 resolved: dumb send first (new Phase 0, before Week 1).** A 3 to 5 day test with 5 to 10 real pairs: a minimal "Send this song" action in the app that opens the iOS share sheet with the song's existing store or search link plus the sender's note as message text, no `song_shares` table, no host, no Edge Function. Per send, record: sent or not, note length, receiver platform, whether the receiver responded, and whether the sender said it felt right. Proposed go/no-go defaults (confirm before running): at least 5 pairs recruited; at least 60 percent of invited senders send one or more notes without prompting during the window; at least 1 receiver response reported. Items 2 to 4 (table, send flow, host, page, limiter) start only after a go. Items independent of the pipeline may proceed during Phase 0: the valence question and `generate_insight` valence branch with its golden set, TestFlight setup, and moving the partner migration to the deferred folder. The earlier success test (3 real sends, 2 receivers reach playback) applies to the full pipeline after a go.

Not rerun: the CEO, Design and Eng phases were not re-run against these three overrides (the skill's rerun rule would re-run the affected phases, with Eng last). The changes are narrow and recorded here; re-run them if you want the full audit trail refreshed.

### Update 2026-10-07: light archetypes shipped
The four light archetypes (The Open Heart, The Free One, The Celebrant, The Connector) were built after the review deferred them. They are scored only from positive hits (insights from positive events never feed the shadow archetypes), shown as "What lifts you" / "Light archetypes", and are not sent to receivers. Icons are SF Symbols until brand art is added (`TODOS.md`).
