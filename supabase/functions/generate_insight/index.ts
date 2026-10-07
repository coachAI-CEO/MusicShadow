// Music Shadow – generate_insight Edge Function
// Loads the activation, fetches lyrics at the spike time, and asks Gemini for a reflection that links song + lyrics to the activation.

import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { momentTailFor, systemPromptFor } from "./prompts.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

interface RequestBody {
  event_id: string;
  song_title?: string | null;
  artist?: string | null;
  lyrics_snippet?: string | null;
  timestamp_seconds?: number | null;
}

interface SongEventRow {
  id: string;
  user_id: string;
  song_title: string | null;
  artist: string | null;
  body_location: string | null;
  somatic_type: string | null;
  impulse: string | null;
  intensity: number | null;
  valence: string | null;
  body_report: string | null;
  impulse_report: string | null;
  block_report: string | null;
  echo_report: string | null;
  belief_report: string | null;
  pattern_report: string | null;
  interruption_directive: string | null;
  free_journal: string | null;
}

interface LrclibSearchResult {
  id: number;
  trackName: string;
  artistName: string;
  albumName?: string;
  duration?: number;
  syncedLyrics?: string | null;
  plainLyrics?: string | null;
}

/** Parse LRC line e.g. "[01:23.45] Text" -> { seconds: 83.45, text: "Text" } */
function parseLrcLine(line: string): { seconds: number; text: string } | null {
  const m = line.match(/^\[(\d+):(\d+)\.(\d+)\]\s*(.*)$/);
  if (!m) return null;
  const [, min, sec, centi, text] = m;
  const seconds = parseInt(min, 10) * 60 + parseInt(sec, 10) + parseInt(centi, 10) / 100;
  return { seconds, text: text.trim() };
}

/** Find the lyric line(s) at or just before timestamp_seconds from LRC synced lyrics */
function getLyricsAtTime(syncedLyrics: string, timestampSeconds: number): string {
  const lines = syncedLyrics.split("\n").filter((l) => l.trim());
  let best: { seconds: number; text: string } | null = null;
  let nextSeconds = Infinity;
  for (const line of lines) {
    const parsed = parseLrcLine(line);
    if (!parsed) continue;
    if (parsed.seconds <= timestampSeconds && parsed.seconds >= (best?.seconds ?? -1)) {
      best = parsed;
    }
    if (parsed.seconds > timestampSeconds && parsed.seconds < nextSeconds) {
      nextSeconds = parsed.seconds;
    }
  }
  const parts: string[] = [];
  if (best) parts.push(best.text);
  const nextLine = lines.find((l) => {
    const p = parseLrcLine(l);
    return p && p.seconds === nextSeconds;
  });
  if (nextLine) {
    const p = parseLrcLine(nextLine);
    if (p) parts.push(p.text);
  }
  return parts.length ? parts.join(" ") : "";
}

/** Fetch lyrics from LRCLIB (free, no key). Returns synced lyrics string or null. */
async function fetchLyricsFromLrclib(trackName: string, artistName: string): Promise<string | null> {
  const params = new URLSearchParams({
    track_name: trackName,
    artist_name: artistName,
  });
  const url = `https://lrclib.net/api/search?${params.toString()}`;
  try {
    const res = await fetch(url, {
      headers: { "User-Agent": "MusicShadow/1.0" },
    });
    if (!res.ok) return null;
    const data: LrclibSearchResult[] = await res.json();
    const first = data?.[0];
    if (!first?.syncedLyrics) return first?.plainLyrics ?? null;
    return first.syncedLyrics;
  } catch {
    return null;
  }
}

/** Format seconds as mm:ss */
function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = Math.floor(seconds % 60);
  return `${m}:${s.toString().padStart(2, "0")}`;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const authHeader = req.headers.get("Authorization");
    if (!authHeader) {
      return new Response(
        JSON.stringify({ error: "Missing authorization" }),
        { status: 401, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const body: RequestBody = await req.json();
    const eventId = body.event_id;
    if (!eventId) {
      return new Response(
        JSON.stringify({ error: "Missing event_id" }),
        { status: 400, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
    const supabaseServiceKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
    const supabase = createClient(supabaseUrl, supabaseServiceKey);

    const { data: event, error: eventError } = await supabase
      .from("song_events")
      .select(
        "id, user_id, song_title, artist, body_location, somatic_type, impulse, intensity, valence, body_report, impulse_report, block_report, echo_report, belief_report, pattern_report, interruption_directive, free_journal"
      )
      .eq("id", eventId)
      .single();

    if (eventError || !event) {
      return new Response(
        JSON.stringify({ error: "Event not found", detail: eventError?.message }),
        { status: 404, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const row = event as SongEventRow;
    const songTitle = body.song_title ?? row.song_title ?? "";
    const artist = body.artist ?? row.artist ?? "";
    const lyricsSnippet = body.lyrics_snippet?.trim() || null;
    const timestampSeconds = body.timestamp_seconds ?? null;

    let lyricsAtTime = "";
    if (songTitle && artist && timestampSeconds != null && timestampSeconds > 0) {
      const synced = await fetchLyricsFromLrclib(songTitle, artist);
      if (synced) {
        lyricsAtTime = getLyricsAtTime(synced, timestampSeconds);
      }
    }

    const timeLabel =
      timestampSeconds != null && timestampSeconds > 0
        ? `${timestampSeconds} seconds (about ${formatTime(timestampSeconds)})`
        : null;

    const journalParts: string[] = [];
    if (row.body_report) journalParts.push(`Body: ${row.body_report}`);
    if (row.impulse_report) journalParts.push(`Impulse: ${row.impulse_report}`);
    if (row.block_report) journalParts.push(`Block: ${row.block_report}`);
    if (row.echo_report) journalParts.push(`Echo: ${row.echo_report}`);
    if (row.belief_report) journalParts.push(`Belief: ${row.belief_report}`);
    if (row.pattern_report) journalParts.push(`Pattern: ${row.pattern_report}`);
    if (row.interruption_directive) journalParts.push(`Interruption: ${row.interruption_directive}`);
    if (row.free_journal) journalParts.push(`Free journal: ${row.free_journal}`);
    const journalBlob = journalParts.join("\n") || "(No journal provided)";

    const songContext: string[] = [];
    if (songTitle) songContext.push(`Song: "${songTitle}"${artist ? ` by ${artist}` : ""}`);
    if (timeLabel) songContext.push(`The activation spiked at ${timeLabel} into the track.`);
    if (lyricsAtTime) songContext.push(`Lyrics at that exact moment: «${lyricsAtTime}»`);
    if (lyricsSnippet) songContext.push(`The user also highlighted this line: «${lyricsSnippet}»`);
    const songContextBlock =
      songContext.length > 0
        ? `\n\n--- THE EXACT MOMENT IN THE SONG (use this in your reflection) ---\n${songContext.join("\n")}\n---${momentTailFor(row.valence)}`
        : "";

    const systemPrompt = systemPromptFor(row.valence);

    const userPrompt = `The user logged an activation with:
- Body location: ${row.body_location ?? "—"}
- Somatic type: ${row.somatic_type ?? "—"}
- Impulse: ${row.impulse ?? "—"}
- Intensity: ${row.intensity ?? "—"}/10
- Valence: ${row.valence ?? "—"}

Journal / reflection from the user:
${journalBlob}
${songContextBlock}

Produce the JSON reflection.`;

    const geminiKey = Deno.env.get("GEMINI_API_KEY");
    if (!geminiKey) {
      return new Response(
        JSON.stringify({ error: "GEMINI_API_KEY not set" }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    const modelPrimary = Deno.env.get("GEMINI_MODEL_PRIMARY") ?? "gemini-3-flash-preview";
    const modelFallback = Deno.env.get("GEMINI_MODEL_FALLBACK") ?? "gemini-2.5-flash";
    const models = [modelPrimary, modelFallback];

    const payload = {
      contents: [
        {
          role: "user",
          parts: [
            { text: systemPrompt },
            { text: userPrompt },
          ],
        },
      ],
      generationConfig: {
        temperature: 0.7,
        maxOutputTokens: 1024,
        responseMimeType: "application/json",
      },
    };

    let parsed: Record<string, string> | null = null;
    let lastError: { status: number; body: Record<string, unknown> } | null = null;

    for (const model of models) {
      const geminiUrl = `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${geminiKey}`;
      const geminiRes = await fetch(geminiUrl, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(payload),
      });

      if (!geminiRes.ok) {
        const errText = await geminiRes.text();
        lastError = { status: 502, body: { error: "Gemini API error", model, detail: errText } };
        continue;
      }

      const geminiData = await geminiRes.json();
      const candidate = geminiData?.candidates?.[0];
      const textPart = candidate?.content?.parts?.[0]?.text;
      const finishReason = candidate?.finishReason;

      if (!textPart) {
        const reason = finishReason === "SAFETY" ? " (blocked by safety filters)" : "";
        lastError = {
          status: 502,
          body: { error: "Empty Gemini response" + reason, model, finishReason: finishReason ?? null },
        };
        continue;
      }

      try {
        let cleaned = textPart.replace(/```json\s*|\s*```/g, "").trim();
        const jsonMatch = cleaned.match(/\{[\s\S]*\}/);
        if (jsonMatch) cleaned = jsonMatch[0];
        parsed = JSON.parse(cleaned) as Record<string, string>;
        break;
      } catch {
        lastError = {
          status: 502,
          body: { error: "Invalid JSON from Gemini", model, raw: textPart.slice(0, 500) },
        };
        continue;
      }
    }

    if (!parsed) {
      const { status, body } = lastError ?? { status: 502, body: { error: "All Gemini models failed" } };
      return new Response(JSON.stringify(body), {
        status,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const { error: insertError } = await supabase.from("shadow_insights").insert({
      id: crypto.randomUUID(),
      event_id: eventId,
      user_id: row.user_id,
      wound_type: parsed.wound_type ?? null,
      protector_mode: parsed.protector_mode ?? null,
      core_belief: parsed.core_belief ?? null,
      summary: parsed.summary ?? null,
      suggested_practice: parsed.suggested_practice ?? null,
    });

    if (insertError) {
      return new Response(
        JSON.stringify({ error: "Failed to save insight", detail: insertError.message }),
        { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
      );
    }

    return new Response(
      JSON.stringify({ ok: true }),
      { status: 200, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  } catch (e) {
    return new Response(
      JSON.stringify({ error: String(e) }),
      { status: 500, headers: { ...corsHeaders, "Content-Type": "application/json" } }
    );
  }
});
