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
