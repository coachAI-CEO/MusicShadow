// Run: bun test supabase/functions/generate_insight   (pure module, no Deno needed)
import { describe, expect, test } from "bun:test";
import { createHash } from "node:crypto";
import {
  POSITIVE_MOMENT_TAIL,
  POSITIVE_SYSTEM_PROMPT,
  SHADOW_MOMENT_TAIL,
  SHADOW_SYSTEM_PROMPT,
  isPositive,
  momentTailFor,
  systemPromptFor,
} from "./prompts.ts";

const sha = (s: string) => createHash("sha256").update(s).digest("hex");

describe("regression: wound-valence prompts are unchanged", () => {
  // Hashes of the original prompt text from index.ts before the valence branch (commit 9db08c4).
  test("shadow system prompt is byte-identical to the original", () => {
    expect(sha(SHADOW_SYSTEM_PROMPT)).toBe("d472b85713b773676ea995d2c12d901f62eeb023453ea794054cf96ee9e7b2f0");
  });
  test("shadow moment tail is byte-identical to the original", () => {
    expect(sha(SHADOW_MOMENT_TAIL)).toBe("4f4050298be326edbe1e42f60b6d48ce2f8941589dbe424d9c9a8eb566becb27");
  });
});

describe("valence routing", () => {
  test("positive uses the appreciative prompt", () => {
    expect(systemPromptFor("positive")).toBe(POSITIVE_SYSTEM_PROMPT);
    expect(momentTailFor("positive")).toBe(POSITIVE_MOMENT_TAIL);
    expect(systemPromptFor(" Positive ")).toBe(POSITIVE_SYSTEM_PROMPT);
  });
  test.each([["shadow"], [null], [undefined], [""], ["unknown"]])("%p falls back to the shadow prompt", (v) => {
    expect(systemPromptFor(v as string | null | undefined)).toBe(SHADOW_SYSTEM_PROMPT);
    expect(momentTailFor(v as string | null | undefined)).toBe(SHADOW_MOMENT_TAIL);
  });
  test("isPositive", () => {
    expect(isPositive("positive")).toBe(true);
    expect(isPositive("shadow")).toBe(false);
  });
});

describe("positive prompt content", () => {
  test("keeps the JSON contract the app and database expect", () => {
    for (const key of ["wound_type", "protector_mode", "core_belief", "summary", "suggested_practice"]) {
      expect(POSITIVE_SYSTEM_PROMPT).toContain(key);
    }
    expect(POSITIVE_SYSTEM_PROMPT).toContain("Respond in JSON only");
  });
  test("asks for song time, title and lyrics like the shadow prompt", () => {
    expect(POSITIVE_SYSTEM_PROMPT).toContain("the time in the song");
    expect(POSITIVE_SYSTEM_PROMPT).toContain("lyric line");
  });
  test("tells the model not to use wound language", () => {
    expect(POSITIVE_SYSTEM_PROMPT).toContain("Do not use wound, shadow, trauma");
    expect(POSITIVE_SYSTEM_PROMPT).not.toContain("shadow-work coach");
    expect(POSITIVE_MOMENT_TAIL).not.toContain("the wound, protector, and belief");
  });
});

import {
  LIGHT_ARCHETYPE_DEFS,
  SHADOW_ARCHETYPE_DEFS,
  archetypeInstructionFor,
  parseArchetype,
} from "./prompts.ts";

describe("archetype classification", () => {
  test("shadow instruction lists only the ten shadow archetypes", () => {
    const t = archetypeInstructionFor("shadow");
    for (const [name] of SHADOW_ARCHETYPE_DEFS) expect(t).toContain(`- ${name}:`);
    for (const [name] of LIGHT_ARCHETYPE_DEFS) expect(t).not.toContain(`- ${name}:`);
    expect(SHADOW_ARCHETYPE_DEFS.length).toBe(10);
  });
  test("positive instruction lists only the ten light archetypes", () => {
    const t = archetypeInstructionFor("positive");
    for (const [name] of LIGHT_ARCHETYPE_DEFS) expect(t).toContain(`- ${name}:`);
    for (const [name] of SHADOW_ARCHETYPE_DEFS) expect(t).not.toContain(`- ${name}:`);
    expect(LIGHT_ARCHETYPE_DEFS.length).toBe(10);
  });
  test("asks for the three keys and says one hit is weak evidence", () => {
    const t = archetypeInstructionFor(null);
    for (const k of ["archetype:", "archetype_confidence:", "archetype_evidence:"]) expect(t).toContain(k);
    expect(t).toContain("weak evidence");
  });
  test("accepts a valid pick, normalising case and the leading 'The'", () => {
    expect(parseArchetype({ archetype: "ghost", archetype_confidence: "HIGH", archetype_evidence: " felt nothing " }, "shadow"))
      .toEqual({ archetype: "The Ghost", confidence: "high", evidence: "felt nothing" });
  });
  test("none, missing and non-string values give null", () => {
    expect(parseArchetype({ archetype: "none" }, "shadow")).toBeNull();
    expect(parseArchetype({ archetype: "" }, "shadow")).toBeNull();
    expect(parseArchetype({}, "shadow")).toBeNull();
    expect(parseArchetype({ archetype: 7 }, "shadow")).toBeNull();
    expect(parseArchetype(null, "shadow")).toBeNull();
  });
  test("rejects an archetype from the other set", () => {
    expect(parseArchetype({ archetype: "The Open Heart" }, "shadow")).toBeNull();
    expect(parseArchetype({ archetype: "The Ghost" }, "positive")).toBeNull();
  });
  test("missing or invalid confidence falls back to low; evidence is capped", () => {
    expect(parseArchetype({ archetype: "The Maker", archetype_confidence: "certain" }, "positive")?.confidence).toBe("low");
    const long = "x".repeat(400);
    expect(parseArchetype({ archetype: "The Maker", archetype_evidence: long }, "positive")?.evidence?.length).toBe(240);
  });
  test("the pinned prompts are untouched by this addition", () => {
    expect(SHADOW_SYSTEM_PROMPT).not.toContain("archetype");
    expect(POSITIVE_SYSTEM_PROMPT).not.toContain("archetype");
  });
});
