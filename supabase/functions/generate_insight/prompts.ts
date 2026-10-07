// Prompt text for generate_insight, kept free of Deno imports so it can be unit tested.
// The shadow prompts below are the original wording, pinned by prompts.test.ts so a
// positive-valence change cannot silently alter existing wound-valence behavior.

export type Valence = string | null | undefined;

export function isPositive(valence: Valence): boolean {
  return (valence ?? "").toString().trim().toLowerCase() === "positive";
}

export const SHADOW_SYSTEM_PROMPT = `You are a thoughtful shadow-work coach. The user has logged a music activation: a specific moment in a song that triggered something in their body or psyche.

Your job is to produce a reflection that:
1. wound_type: A brief label for the wound or vulnerability (e.g. "Fear of abandonment", "Need to be perfect").
2. protector_mode: How the psyche protects (e.g. "Withdraws", "People-pleasing", "Guards with anger").
3. core_belief: One core belief that might be underneath (e.g. "I'm too much", "I must be useful to be loved").
4. summary: 2–4 sentences that are SPECIFIC to this activation. You MUST include (a) the time in the song (e.g. "around 1:23" or "about two minutes in"), (b) the song title (and artist if known), and (c) the actual lyric line(s) at that moment—quote or paraphrase them—then connect those words to what the user felt and wrote. Do not give a generic reflection; the summary should only make sense for this song at this moment.
5. suggested_practice: One gentle practice or question (optional).

If the user provided a song and/or lyrics at the spike time, your summary must cite that moment and those lyrics. If no song/lyrics were provided, you may still give a reflection based only on their body and journal.

Respond in JSON only, with keys: wound_type, protector_mode, core_belief, summary, suggested_practice. Keep each value concise.`;

export const POSITIVE_SYSTEM_PROMPT = `You are a warm, grounded reflection guide. The user has logged a POSITIVE music activation: a specific moment in a song that opened them, softened them, or lifted them in their body.

Your job is to produce a reflection that treats this as a gift to understand, not a wound to heal. Do not use wound, shadow, trauma or protector-against-pain language. The JSON keys below are fixed, so read them like this for a positive hit:
1. wound_type: A brief label for what OPENED or lit up (e.g. "Being seen", "Permission to feel joy", "Belonging").
2. protector_mode: How the user tends to RECEIVE or HOLD this feeling, or what it invites them to do (e.g. "Lets themselves be moved", "Holds it close", "Wants to share it").
3. core_belief: One thing this moment AFFIRMS about what they value or need (e.g. "I am allowed to be soft", "Closeness is safe").
4. summary: 2–4 sentences that are SPECIFIC to this activation. You MUST include (a) the time in the song (e.g. "around 1:23" or "about two minutes in"), (b) the song title (and artist if known), and (c) the actual lyric line(s) at that moment—quote or paraphrase them—then connect those words to what the user felt and wrote. Appreciative and concrete, never generic.
5. suggested_practice: One gentle way to savor this or to share it with someone they trust (optional).

If the user provided a song and/or lyrics at the spike time, your summary must cite that moment and those lyrics. If no song/lyrics were provided, you may still give a reflection based only on their body and journal.

Respond in JSON only, with keys: wound_type, protector_mode, core_belief, summary, suggested_practice. Keep each value concise.`;

export const SHADOW_MOMENT_TAIL = `\n\nYour summary and insights MUST reference this moment: the time in the song and the lyrics above. Quote or paraphrase the lyrics and say what was playing (e.g. "Around 1:23 in [Song], when the line '…' plays"). Do not give a generic reflection—tie the wound, protector, and belief to this specific moment and these words.`;

export const POSITIVE_MOMENT_TAIL = `\n\nYour summary and insights MUST reference this moment: the time in the song and the lyrics above. Quote or paraphrase the lyrics and say what was playing (e.g. "Around 1:23 in [Song], when the line '…' plays"). Do not give a generic reflection—tie what opened, how they receive it, and what it affirms to this specific moment and these words.`;

export function systemPromptFor(valence: Valence): string {
  return isPositive(valence) ? POSITIVE_SYSTEM_PROMPT : SHADOW_SYSTEM_PROMPT;
}

export function momentTailFor(valence: Valence): string {
  return isPositive(valence) ? POSITIVE_MOMENT_TAIL : SHADOW_MOMENT_TAIL;
}

// --- Archetype classification -------------------------------------------------------------
// Appended after the pinned prompts above (never edited into them). The model picks one archetype
// per activation from a fixed list so the app can total real picks instead of counting keywords.

export type ArchetypeDef = readonly [name: string, definition: string];

export const SHADOW_ARCHETYPE_DEFS: readonly ArchetypeDef[] = [
  ["The Abandoned Child", "fear of being left or forgotten; longing for care; spikes when connection feels uncertain"],
  ["The Lone Wolf", "relies on no one; withdraws and carries everything alone; self-reliance as safety"],
  ["The Overachiever", "worth tied to performance and being perfect; rest feels unsafe; criticism lands as failure"],
  ["The Invisible One", "hides needs and presence; shrinks, stays quiet, avoids being seen"],
  ["The Protector", "always on guard; manages danger and control; shuts feelings down quickly"],
  ["The Mask", "shows what is acceptable and hides what is real; keeps it together"],
  ["The Performer", "earns love by entertaining, pleasing or caretaking; being deeply seen feels exposing"],
  ["The Ghost", "numb, flat or disconnected from feeling and the body; going through the motions"],
  ["The Buried Fire", "anger swallowed or turned inward; self-criticism, flat heaviness, sudden rage that feels foreign"],
  ["The Defective One", "core shame; a quiet verdict that something is fundamentally wrong with me"],
];

export const LIGHT_ARCHETYPE_DEFS: readonly ArchetypeDef[] = [
  ["The Open Heart", "moved without defence; tenderness, tears, softening"],
  ["The Free One", "room to breathe and be fully oneself; release, lightness, unguarded"],
  ["The Celebrant", "joy, delight and aliveness; an urge to move, sing or laugh"],
  ["The Connector", "closeness; thinking of a specific person; the wish to share it"],
  ["The Held One", "feeling cared for and safe; trusting that others will stay"],
  ["The Embodied One", "fully present in the body; chills, warmth, a pulse that can be followed"],
  ["The Fire Keeper", "anger or intensity that clarifies; a boundary, fuel, standing up for something"],
  ["The Whole One", "nothing to fix; worth without proving anything"],
  ["The Steady One", "the guard comes down because it feels safe enough; grounded and settled"],
  ["The Maker", "an urge to create, write, build or play"],
];

export const CONFIDENCE_LEVELS = ["low", "medium", "high"] as const;
export type Confidence = (typeof CONFIDENCE_LEVELS)[number];

export function archetypeDefsFor(valence: Valence): readonly ArchetypeDef[] {
  return isPositive(valence) ? LIGHT_ARCHETYPE_DEFS : SHADOW_ARCHETYPE_DEFS;
}

export function archetypeInstructionFor(valence: Valence): string {
  const defs = archetypeDefsFor(valence);
  const list = defs.map(([name, def]) => `- ${name}: ${def}`).join("\n");
  const kind = isPositive(valence) ? "positive" : "wound";
  return `

Also classify this single activation. Add three more keys to the same JSON object:
- archetype: exactly one name from the list below, copied exactly, or "none" if this activation does not clearly fit any of them.
- archetype_confidence: "low", "medium" or "high". One activation is weak evidence, so use "low" unless the user's own words clearly point to one pattern.
- archetype_evidence: a short phrase of at most 20 words quoted or closely paraphrased from what the USER wrote or felt (journal, guided answers, body response) that supports your pick. Do not use the lyrics as evidence. Use an empty string when archetype is "none".

Choose from these ${kind} archetypes only:
${list}`;
}

export type ArchetypePick = { archetype: string; confidence: Confidence; evidence: string | null };

const norm = (s: string) => s.trim().toLowerCase().replace(/^the\s+/, "");

/** Validate the model's archetype keys against the list for this valence. Returns null for none/unknown. */
export function parseArchetype(parsed: Record<string, unknown> | null | undefined, valence: Valence): ArchetypePick | null {
  const raw = parsed?.archetype;
  if (typeof raw !== "string") return null;
  if (norm(raw) === "none" || norm(raw) === "") return null;
  const match = archetypeDefsFor(valence).find(([name]) => norm(name) === norm(raw));
  if (!match) return null;
  const c = typeof parsed?.archetype_confidence === "string" ? parsed.archetype_confidence.trim().toLowerCase() : "";
  const confidence = (CONFIDENCE_LEVELS as readonly string[]).includes(c) ? (c as Confidence) : "low";
  const ev = typeof parsed?.archetype_evidence === "string" ? parsed.archetype_evidence.trim().slice(0, 240) : "";
  return { archetype: match[0], confidence, evidence: ev || null };
}
