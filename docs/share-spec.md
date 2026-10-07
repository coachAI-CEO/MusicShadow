# Share spec (v1 pipeline)

**Status:** authoritative. Supersedes the layered amendments in `docs/send-receive-plan.md` wherever they disagree. Built only after Phase 0 returns a **go** (`docs/phase-0-dumb-send.md`).
**Source:** the /autoplan review of 2026-10-07 (CEO, Design, DX, Eng phases) plus the final-gate overrides.
**Not in v1:** partner read path (build item 1), replies, receipts, Odesli/Songlink, response caching. See `TODOS.md`. (The four light archetypes shipped separately on 2026-10-07; they are not part of the share pipeline and are not sent to receivers.)

## 0. Rulings where earlier text disagreed

| Topic | Ruling |
|---|---|
| Link lifetime | Default 90 days. Sender may pick 30 days, 90 days or no expiry. Revoke any time. (Not "never expires".) |
| Edge Function response | JSON with the full contract in section 3. Never HTML. |
| Who renders HTML | A host-side function on a static host with a custom domain. Supabase's default domain rewrites `text/html` to `text/plain`. |
| Cache headers | `Cache-Control: no-store` and `Vary: User-Agent` on every response from both the Edge Function and the host. |
| OG preview | Title "Someone sent you a song", neutral description, generic image. Never the song title or the note. |
| Report link text | "Report a problem". Promise is "reviewed promptly", not a 24-hour SLA. |
| App Store CTA | No "Coming soon" line. The CTA appears only once an App Store URL exists. |
| Counters | `song_shares.view_count` is the only view counter. No hits table. |
| Rate limiting | Function-side limiter is the default; host rules are defense in depth. Table `share_view_rate` (not the dropped hits table). |
| Playback | 30-second iTunes preview in an `<audio>` element, plus "Open in Apple Music" and "Search on Spotify" links. |
| Renderer parity | Swift renderer for the in-app preview, host renderer for the page, golden fixtures must match. No bundled JS. |
| Odesli/Songlink | Deferred. |
| MusicKit | Not used. `MusicSearchService` stays disabled; `ITunesSearchService` is the play-link source. |
| Update restrictions | One BEFORE UPDATE trigger. Not column privileges. |
| Provider values | Only `apple` is stored in v1. Spotify links are built at render time and never stored. |
| Partner migration | Unscheduled, lives in `supabase/migrations_deferred/`, never apply as written. |
| Phase 0 | Runs first. Items below start only after a go. |

## 1. Data

Migration name: `20261007000001_song_shares.sql` (or later). Hand-write a down migration. If the deferred partner migration is ever revived it must be renumbered, since it sorts earlier than this file.

```sql
create table public.song_shares (
  id            uuid primary key,  -- client-generated UUID so a retried send is idempotent
  sender_id     uuid not null default auth.uid() references auth.users(id) on delete cascade,
  event_id      uuid references public.song_events(id) on delete set null,  -- shares are snapshots
  song_title    text not null check (char_length(song_title) between 1 and 200),
  artist        text not null default '' check (char_length(artist) <= 200),
  sender_note   text not null check (char_length(sender_note) between 1 and 500),
  sender_display_name text check (char_length(sender_display_name) <= 40),
  recipient_hint text check (char_length(recipient_hint) <= 80),
  share_token   text not null unique
                default rtrim(translate(encode(extensions.gen_random_bytes(16), 'base64'), '+/', '-_'), '=')
                check (char_length(share_token) >= 22),
  play_url      text check (play_url ~ '^https://(music\.apple\.com|itunes\.apple\.com)/'),
  preview_url   text check (preview_url ~ '^https://(audio-ssl\.itunes\.apple\.com|[a-z0-9-]+\.mzstatic\.com)/'),
  provider      text check (provider in ('apple')),
  view_count    integer not null default 0,
  created_at    timestamptz not null default now(),
  shared_at     timestamptz,                     -- set once when the share sheet completes
  revoked_at    timestamptz,
  expires_at    timestamptz default now() + interval '90 days'  -- explicit null = no expiry
);
alter table public.song_shares enable row level security;
-- owner-only: insert with check (sender_id = auth.uid()); select/update/delete using (sender_id = auth.uid())
```

Unverified, check in a dev database before relying on it: that `extensions.gen_random_bytes` is available on this project, and the exact host names Apple serves previews from today (a live check on 2026-10-07 returned `audio-ssl.itunes.apple.com`).

**BEFORE UPDATE trigger** raises when the sender changes: `share_token`, `view_count`, `sender_id`, `play_url`, `preview_url`, `provider`, `song_title`, `artist`, `created_at`; changes `sender_note` once `shared_at` is not null (a UX guard, not a security boundary); or sets `shared_at` more than once. Allowed: `sender_note` before `shared_at`, `sender_display_name`, `recipient_hint`, `revoked_at`, `expires_at` (extending an expired link is allowed), `shared_at` once.

**BEFORE INSERT trigger** rejects the 51st insert by one sender in 24 hours.

**Send is two statements, not an upsert:** `INSERT` with the client UUID; on unique violation (23505) the app does an `UPDATE` of the note. An upsert would fire the insert trigger on updates. An insert or update against another user's id fails cleanly and is mapped to a generic error.

**Limiter table:** `share_view_rate(ip_hash text, window_start timestamptz, hits int, primary key (ip_hash, window_start))`, RLS enabled with no policies (service role only). `ip_hash = HMAC(client IP, server secret)`. A scheduled purge deletes rows older than 7 days.

## 2. Edge Function `share_view`

`POST /functions/v1/share_view`, deployed with `--no-verify-jwt`, CORS closed. It is called only by the host function.

| Item | Value |
|---|---|
| Auth | Header `x-share-secret`. Constant-time compare against a *current* and a *next* secret (zero-downtime rotation). Missing or wrong returns the same 404 as an unknown token. |
| Request body | `{"token": "<exact string, case-sensitive>"}` |
| 200 | `{"title","artist","note","play_url","preview_url","sender_display_name","expires_at"}` |
| 404 | `{"error":"unavailable"}`. Byte-identical for: unknown token, revoked, expired, kill switch on, bad secret. One `unavailable()` builder produces it. |
| 429 | `{"error":"rate_limited"}` (the only allowed difference from the 404) |
| 503 | `{"error":"try_again"}` for upstream or internal failure. Never the 404 body. |
| Headers | `Cache-Control: no-store`, `Vary: User-Agent` |
| Counting | `view_count += 1` on a 200 for a GET-originated request, fire-and-forget, never blocking the response. HEAD and unfurl bots are not counted. Approximate by design. |
| Logging | Reason codes `bad_secret`, `not_found`, `revoked`, `expired`, `disabled`, `rate_limited` with an 8-character token-hash prefix. Never the raw token. |
| Kill switch | Env `SHARE_DISABLED=1` on the function and the host: every token returns the 404. |
| Time | Expiry is judged with database time only. |

## 3. Host function and page

The host (for example a Cloudflare Pages Function) is a thin adapter: take the token from `/s/<token>`, call `share_view` with the secret, render with the shared renderer module, respond. The host and Supabase each hold the secret; rotate by setting `next`, deploying both, then promoting.

`GET /s/<token>` (token used exactly as received; no lowercasing, no trailing-slash tricks) and `HEAD`.

Response headers: `Content-Type: text/html; charset=utf-8`, `Cache-Control: no-store`, `Vary: User-Agent`, `X-Robots-Tag: noindex`, `Referrer-Policy: no-referrer`, `X-Content-Type-Options: nosniff`, and

`Content-Security-Policy: default-src 'none'; media-src https://audio-ssl.itunes.apple.com https://*.mzstatic.com; style-src 'sha256-<hash of the static stylesheet>'; img-src 'self' data:; base-uri 'none'; form-action 'none'`

Page order (mobile first, one column, max about 36rem, `lang` set, `prefers-color-scheme`, reduced motion respected, no scripts):

1. "Someone shared a song with you"; "From {name}" only if `sender_display_name` is set
2. The note, largest text on the page, line breaks preserved, `dir="auto"`
3. Song title and artist, one primary **Play 30s preview** control (native `<audio>`; an `error` event hides it)
4. Small links: **Open in Apple Music** (if `play_url`), **Search on Spotify** (`https://open.spotify.com/search/<url-encoded title and artist>`, built at render time, never stored), both `rel="noopener noreferrer"`. With no `play_url`, Apple Music link becomes a search link.
5. "You can reply to them directly."
6. Footer: a muted **Report a problem** mailto link. App Store CTA only when a URL exists ("Available on iPhone" text for non-iPhone user agents).

All dynamic fields (title, artist, note, display name) are HTML-escaped. Unavailable page: "This link isn't available. It may have expired or been removed by the sender. If you were expecting something, ask them to send it again." 503/429 page: "Something went wrong. Try again in a moment."

Open Graph: title "Someone sent you a song", description "Open to hear it and read their note.", a generic image. Crawlers see these because the page is server-rendered.

Third-party requests: the receiver's browser fetches the audio from Apple hosts (this leaks their IP to Apple; the privacy policy says so). No scripts.

## 4. iOS send flow

Entry: "Send this song with a note" on an activation. Pieces: `ShareService` (single owner of insert, update, revoke), `ITunesSearchService`, `SendSongSheet`, a preview screen, Shared songs list in Settings, a first-run explainer. The Phase 0 files already exist (`Music Shadow/Services/ShareHelpers.swift`, `ITunesSearchService.swift`, `Views/SendSongSheet.swift`).

- **Send sheet:** note field is primary and focused; AI reflection is a collapsed secondary card; five starter prompts inserted on tap (single use, editable, appended); song match with up to 3 results to pick from or skip; "From" name (optional, 40 characters); expiry selector 30 / 90 (default) / no expiry; Send is the only prominent button. Counter appears from 400, hard stop at 500 counted in Unicode scalars, truncation on paste.
- **Preview step:** "Preview as they'll see it" renders the receive layout with the Swift renderer. Send on that screen is the final tap. Copy: "You can turn off the link later. They may already have seen it."
- **Identity of a send:** the app generates the UUID, keeps it in a draft that survives relaunch, discards it on logout, account switch, or if the row is revoked or deleted. First Send inserts; cancel then edit then Send again updates the same row until `shared_at` is set. `shared_at` is set when the share sheet reports completion.
- **Expiry encoding:** the app sends `expires_at` explicitly, including an explicit JSON `null` for no expiry. Omitting the key silently means 90 days. Unit test each selector value.
- **States:** insight loading / ready / failed ("No reflection yet, you can still write your own words"); match searching / one / several / none / offline ("Sending without a play link"); note empty / valid / near cap / at cap / locked ("This note was shared. Turn off the link to write a new one."); send idle / creating / failed (retry, draft kept) / created-not-shared / shared; "Draft restored" cue.
- **Sender errors:** note insert failure; `play_url` CHECK rejection (send continues without it); paste over 500; deleted or revoked draft ("This link was removed. Start a new one."); foreign-id conflict (generic error).
- **Shared songs list:** empty ("Nothing shared yet"), loading, offline error, rows with Active / Expires in N days / Expired / Revoked, **Copy link** and **Share again** for active shares, Revoke with confirm ("They may have already seen it. Turning off the link stops anyone else from opening it."), Delete with confirm.
- **Event deletion:** the confirm says shares of that song remain unless turned off and offers "Also turn off links for this song".
- **Partner UI** stays hidden behind `FeatureFlags.partnerEnabled`.
- **Accessibility:** Dynamic Type, 44 pt targets, VoiceOver labels for the counter, prompts and revoke, 4.5:1 contrast.

## 5. Valence (shipped)

The logging form already asks "Shadow spike" or "Positive hit" and stores `valence` as `shadow` or `positive`. `generate_insight` now branches on it (`supabase/functions/generate_insight/prompts.ts`). Positive hits get an appreciative reflection under the same JSON keys; the detail screen labels them Opened / Receives it as / Affirms. The shadow prompt is pinned byte-for-byte by `prompts.test.ts`. The 20-case golden set is `docs/evals/valence-golden.json`; running it against Gemini needs the deployed function and a key.

## 6. Operations

- `scripts/seed-share` creates a test share and prints its URL.
- `scripts/verify-share.sh` exits nonzero unless: `text/html` and all headers present; a `<script>` note renders literally; unknown, revoked, expired and kill-switch responses are byte-identical; a stubbed function failure gives the 503 page; fetching twice, revoking, and refetching returns the unavailable page.
- `docs/share-runbook.md`: takedown (`update song_shares set revoked_at = now() where ...` with the service role, reviewed promptly), secret rotation, the report inbox, the kill switch, and a SQL snippet to look up a share by id or token hash (instead of a lookup script).
- "Share TTHW" section: clone to a seeded share rendering as `text/html`, estimated 30 minutes excluding DNS propagation. Measure once and record the number.

## 7. Tests

pgTAP via `supabase test db` (CHECKs, trigger, RLS, throttle, foreign id), function tests for `share_view` (secret current/next/missing/wrong, the five 404 cases byte-identical, GET-only counting, limiter), renderer tests plus golden fixtures run through both the host renderer and the Swift renderer, Swift Testing units, XCUITests for send and revoke. Value cards and the full list are in `~/.gstack/projects/coachAI-CEO-MusicShadow/macbook-main-eng-review-test-plan-20261007-003710.md`. Include `https://music.apple.com.evil.com/`, `https://music.apple.com@evil.com/`, `javascript:`, family emoji, combining marks, RTL, trailing slash, uppercase paths, HEAD requests, concurrent revoke versus view.

## 8. Schedule (after a Phase 0 go)

- **Week 1:** domain and static host (start DNS now; it gates everything), Supabase `share_view` spike with pass criteria (host renders HTML with og:title and `text/html`, calls the secret-gated function, p95 under 1.5 seconds from a phone, including cold start), TestFlight setup, `song_shares` migration and tests, scripts.
- **Weeks 1-2:** send flow, picker, preview step, expiry encoding.
- **Weeks 2-3:** receive page, OG, limiter, shared songs list.
- **Week 4:** onboarding reframe, then polish. App Store copy rewrite waits until after real sends.
- **Cut line:** polish slips first, then anything not on the share path.
- **Success test:** the founder's wife sends 3 real songs and at least 2 receivers reach playback (self-reported). Record receiver platform, whether the song matched, and whether the receiver responded.

## 9. App Store and privacy

Guideline 1.2 (user-generated content): report link, ability to turn a link off, a monitored contact address. Update the privacy policy and privacy labels for shared notes and for the receiver's browser fetching audio from Apple. Hosting logs may contain tokens; minimize logging and say so in the policy.
