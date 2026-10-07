# Phase 0: dumb send

**Status:** built, not yet run. Decided at the /autoplan final gate on 2026-10-07 (see `docs/send-receive-plan.md`, "Final gate overrides").
**Question it answers:** will people write a vulnerable note in their own words and send a song with it? The full pipeline (`docs/share-spec.md`) is built only after a go.

## What exists in the app
- **Send this song with a note** button on an activation's detail screen (`TriggerDetailView`).
- `SendSongSheet`, in two steps:
  1. **Compose:** note field (500 character cap, counted in Unicode scalars), five tap-to-insert starter prompts, an optional "Sign it" name (40 characters), a first-run explainer. The button says **Review**, not Send, because nothing is sent yet.
  2. **Review before sending:** four plain-language cards.
     - **What you're sharing:** the exact message string (note, optional signature, song title and artist, link). The same string is handed to the share sheet. A line says whether the link opens the exact song or searches Apple Music because there was no match.
     - **What stays private:** your AI reflection, journal entries, body and intensity ratings, and other songs never leave the app.
     - **When it goes:** nothing is sent yet; you pick who gets it in the share sheet and it goes only when you send it there.
     - **How long:** it is an ordinary message. It stays in their chat until they delete it, and you can't turn it off or take it back. The link doesn't expire, and it opens Apple Music, so Spotify users may not be able to play the full song.
     Buttons: **Choose who to send to** (opens the share sheet) and **Edit** (back to compose).
- On Review: iTunes Search finds the song (3 second timeout, falls back to an Apple Music search link). Then the iOS share sheet opens; the sender picks the person and the app.
- **Send log** (Settings > Send log): one row per *completed* share, stored on the phone only. The sender fills in what happened afterward.
- No server, no table, no web page, no account for the receiver.

## How to run the test
1. Recruit **5 to 10 pairs** (the sender uses the app, the receiver does not need to). The first pair is the founder and his wife.
2. Tell senders only: "open an activation, tap Send this song, write what you would say to them." Do not suggest what to write.
3. Run it for **3 to 5 days**.
4. After each send, the sender opens Settings > Send log and sets: what the receiver uses (Apple Music / Spotify / Other), "They responded", "It felt right to send".
5. At the end, each sender taps **Share this log** and sends you the text.

## Go / no-go (proposed defaults, confirm before running)
- At least **5 pairs** recruited.
- At least **60 percent** of invited senders send one or more notes without being prompted during the window.
- At least **1 receiver response** reported.
- Also read, not gated: how long the notes are, how many receivers use Spotify (decides whether universal links matter), how many sends had no song match, and how many senders said it did *not* feel right.

A **go** starts the pipeline in `docs/share-spec.md`. A **no-go** means the note-writing step itself needs work (prompts, the AI reflection as context, the framing), not infrastructure.

## Known limits
- The app cannot tell whether the receiver opened the message or played the song. Everything about the receiver is self-reported by the sender.
- Spotify receivers get an Apple Music link. Whether that blocks them is one of the things the log measures.
- The log lives in `UserDefaults`; deleting the app deletes it. Export it before reinstalling.
- iTunes Search can match a cover or remaster. The Phase 0 flow does not ask the sender to confirm the match (that comes with the picker in the pipeline).
