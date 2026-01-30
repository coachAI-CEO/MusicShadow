# generate_insight Edge Function – payload and prompt

The iOS app calls the `generate_insight` Supabase Edge Function so the AI reflection can **look up the song lyrics, find the lyrics at the activation’s time in the track, and give insights that link that moment to the activation**.

---

## Environment / Secrets (Supabase Dashboard → Edge Functions → generate_insight → Secrets)

| Secret | Required | Description |
|--------|----------|-------------|
| **GEMINI_API_KEY** | Yes | Google AI API key for Gemini. |
| **GEMINI_MODEL_PRIMARY** | No | Model to try first. Default: `gemini-3-flash-preview`. |
| **GEMINI_MODEL_FALLBACK** | No | Model to try if primary fails (API error, empty, or invalid JSON). Default: `gemini-2.5-flash`. |

---

## Request body (POST)

```json
{
  "event_id": "uuid-of-the-saved-activation",
  "song_title": "Song Title",
  "artist": "Artist Name",
  "lyrics_snippet": "Optional line or snippet the user pasted",
  "timestamp_seconds": 83
}
```

| Field | Type | Description |
|-------|------|-------------|
| **event_id** | UUID (required) | Row in `song_events`; use it to load the event and journal fields. |
| **song_title** | string (optional) | Song title from the form. Use to fetch lyrics and name the song in the reflection. |
| **artist** | string (optional) | Artist name. Use to fetch lyrics and in the reflection. |
| **lyrics_snippet** | string (optional) | User-pasted line or snippet. Use in the prompt if you don’t have full lyrics, or to reinforce what the user highlighted. |
| **timestamp_seconds** | number (optional) | Seconds into the song when the activation spiked (e.g. 83 = 1:23). Use to find the lyric line(s) at that moment. |

---

## Recommended flow in the Edge Function

1. **Load the event** – Use `event_id` to load the activation (body report, impulse, journal, etc.) from `song_events`.
2. **Resolve song + time** – From the payload (or event): `song_title`, `artist`, `timestamp_seconds`. If the user set a “spike time”, `timestamp_seconds` is the exact moment in the track.
3. **Look up lyrics** – Call a lyrics API (see below) with `song_title` and `artist` to get:
   - **Full lyrics**, and ideally
   - **Timestamped lyrics** (e.g. LRC format: `[mm:ss.xx] Line of lyrics`) so you can map `timestamp_seconds` to the right line(s).
4. **Find lyrics at that time** – Using `timestamp_seconds`, pick the line(s) that play at that moment (e.g. 83 seconds → ~1:23). If the API doesn’t give timestamps, you can still send full lyrics and mention “The user’s activation spiked around {timestamp_seconds} seconds in.”
5. **Build the prompt** – Include in the Gemini prompt:
   - Song and artist.
   - The lyrics at (or around) that time: “At {timestamp_seconds} seconds (about {mm:ss}) in the song, the lyrics are: «…».”
   - Optional: user’s `lyrics_snippet` if provided.
   - Instruction: “Use this moment in the song and these lyrics to link your reflection to what’s actually playing when the activation happened.”

---

## Lyrics APIs (for “look for the song lyrics”)

- **Genius** – `https://docs.genius.com/` – Search by song + artist, get lyrics (and sometimes sections). No built-in timestamps; you can still send full lyrics + `timestamp_seconds`.
- **Musixmatch** – `https://developer.musixmatch.com/` – Lyrics + optional “snippet” by time; good for matching a time window.
- **LRCLIB** – `https://lrclib.net/` – Free, no key; returns LRC (timestamped lines). Search by artist + title, then find the line where `[mm:ss]` ≤ `timestamp_seconds` ≤ next line.
- **LRC format** – Many sources provide LRC: `[01:23.45] Line of lyrics`. Parse and find the line(s) that contain `timestamp_seconds` (e.g. 83 → 1:23).

If you can’t add an API yet, use **lyrics_snippet** from the app and still pass **timestamp_seconds** so the prompt can say “The activation was at about {mm:ss} in the song; the user highlighted this lyric: «lyrics_snippet».”

---

## Prompt guidance (concise)

1. **Song and artist** – “The activation is for **{song_title}** by **{artist}**.”
2. **Time in the song** – “The activation spiked at **{timestamp_seconds}** seconds (about **{mm:ss}**) into the track.”
3. **Lyrics at that time** – “The lyrics at that moment in the song are: «…».” (from your lyrics lookup + time mapping, or from `lyrics_snippet` if no API.)
4. **Instruction** – “Use the song, the lyrics at this time, and the user’s body/journal description to give an insight that links what’s happening in the song at that moment to the wound, protector mode, or core belief you identify.”
5. Keep your existing instructions (body report, impulse, journal, etc.); the above adds **lyrics + time frame** so the reflection is tied to the actual moment in the song.

---

## Backward compatibility

All new fields are optional. If the Edge Function only reads `event_id`, behavior is unchanged. Adding lyrics lookup and `timestamp_seconds` improves insights by tying them to the exact moment and lyrics in the song.
