import Foundation
import SwiftUI



// MARK: - Core Archetypes

enum ShadowArchetype: String, CaseIterable, Identifiable {
    case abandonedChild = "The Abandoned Child"
    case loneWolf       = "The Lone Wolf"
    case overachiever   = "The Overachiever"
    case invisibleOne   = "The Invisible One"
    case protector      = "The Protector"
    case mask           = "The Mask"
    case performer      = "The Performer"
    // --- New archetypes (Phase 5) ---
    case ghost          = "The Ghost"
    case buriedFire     = "The Buried Fire"
    case defectiveOne   = "The Defective One"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .abandonedChild: return "ArchetypeAbandonedChild"
        case .loneWolf:       return "ArchetypeLoneWolf"
        case .overachiever:   return "ArchetypeOverachiever"
        case .invisibleOne:   return "ArchetypeInvisibleOne"
        case .protector:      return "ArchetypeProtector"
        case .mask:           return "ArchetypeMask"
        case .performer:      return "ArchetypePerformer"
        case .ghost:          return "ArchetypeGhost"
        case .buriedFire:     return "ArchetypeBuriedFire"
        case .defectiveOne:   return "ArchetypeDefectiveOne"
        }
    }
    
    // Keep emoji as fallback for backwards compatibility
    var emoji: String {
        switch self {
        case .abandonedChild: return "🧸"
        case .loneWolf:       return "🐺"
        case .overachiever:   return "🏅"
        case .invisibleOne:   return "👤"
        case .protector:      return "🛡️"
        case .mask:           return "🎭"
        case .performer:      return "🎤"
        case .ghost:          return "🌫️"
        case .buriedFire:     return "🌋"
        case .defectiveOne:   return "🪞"
        }
    }

    /// Short 1-liner under the title
    var tagline: String {
        switch self {
        case .abandonedChild:
            return "Longing for care, bracing for being left."
        case .loneWolf:
            return "I’m safest when I rely on no one."
        case .overachiever:
            return "If I’m perfect, I might be enough."
        case .invisibleOne:
            return "If no one sees me, I can’t be hurt."
        case .protector:
            return "Always on guard, always managing danger."
        case .mask:
            return "I show what’s acceptable, hide what’s real."
        case .performer:
            return "I earn love by entertaining and pleasing."
        case .ghost:
            return "If I can’t feel it, I can’t be hurt by it."
        case .buriedFire:
            return "My anger was too dangerous to feel, so I swallowed it."
        case .defectiveOne:
            return "Something is fundamentally wrong with me that others can’t see yet."
        }
    }

    /// A little more depth for the card body
    var longDescription: String {
        switch self {
        case .abandonedChild:
            return "This pattern centres around loneliness, fear of being left, and spikes when connection feels uncertain. The nervous system expects abandonment and braces for it."
        case .loneWolf:
            return "This pattern carries self-reliance and emotional distance. It’s hard to trust that others will really be there, so you carry everything alone."
        case .overachiever:
            return "This pattern ties worth to performance. Rest feels unsafe, and criticism can land like proof that you’re failing at being ‘enough’."
        case .invisibleOne:
            return "This pattern hides needs, emotions, and even presence. Blending in or disappearing has felt safer than taking up space."
        case .protector:
            return "This pattern jumps in to manage risk, anger, or chaos — often by shutting feelings down quickly to keep control."
        case .mask:
            return "This pattern curates what others see. Vulnerable parts stay behind a mask of ‘fine’, ‘together’, or ‘easygoing’."
        case .performer:
            return "This pattern reaches for charm, humour, or caretaking to stay liked and safe. Being deeply seen can feel exposing."
        case .ghost:
            return "At some point, feeling became too dangerous — so the body learned to go quiet. Music that once moved you lands flat. Aliveness feels foreign, even threatening. The disconnection isn’t weakness; it was survival."
        case .buriedFire:
            return "Anger was punished, shamed, or felt too destructive to express — so it went underground. It surfaces as depression, sharp self-criticism, or sudden explosions that feel foreign to who you think you are. The fire didn’t disappear. It turned inward."
        case .defectiveOne:
            return "Beneath the surface runs a quiet verdict: something is fundamentally wrong with me. Not something I did — something I am. This core shame pre-dates memory and shapes everything, from how compliments land to how much intimacy feels safe."
        }
    }

    /// Underlying story this pattern is protecting
    var coreWound: String {
        switch self {
        case .abandonedChild:
            return "Fear of being left, forgotten, or too much to stay with."
        case .loneWolf:
            return "Belief that others can’t truly be trusted or depended on."
        case .overachiever:
            return "Feeling only achievements make you worthy of care or safety."
        case .invisibleOne:
            return "Sense that your needs, voice, or presence don’t really matter."
        case .protector:
            return "Expectation that things can turn unsafe quickly if you relax."
        case .mask:
            return "Fear that your real feelings or self will be rejected or shamed."
        case .performer:
            return "Belief that you must keep others happy to avoid being dropped."
        case .ghost:
            return "Early pain required complete dissociation from the body and feeling. Aliveness became synonymous with danger."
        case .buriedFire:
            return "Rage was punished or caused harm — so it was turned inward or suppressed entirely, leaving no safe place for anger to live."
        case .defectiveOne:
            return "Toxic shame — the internalized conviction of being inherently broken, unlovable, or defective at the core. Not ‘I did something bad’ but ‘I am bad.’"
        }
    }

    /// Typical nervous system pattern / activation style
    var nervousSystemPattern: String {
        switch self {
        case .abandonedChild:
            return "Surges of panic or collapse when connection feels wobbly or distant."
        case .loneWolf:
            return "Numbing out, pulling away, or going hyper-independent under stress."
        case .overachiever:
            return "Driven, wired, and restless; hard time slowing down without guilt."
        case .invisibleOne:
            return "Shrink, freeze, or go blank; body wants to disappear from view."
        case .protector:
            return "Quick to tighten, brace, or go into fight / control mode."
        case .mask:
            return "Smooth on the outside while tension builds under the surface."
        case .performer:
            return "Alert to other people’s moods; body revs up to ‘fix’ the vibe."
        case .ghost:
            return "Chronic flatness, dissociation, or depersonalisation. Aliveness feels unfamiliar or threatening. Music may land without resonance — or pierce the numbness suddenly and overwhelmingly."
        case .buriedFire:
            return "Chronic low-grade depression, sudden rage that feels alien, or compulsive self-criticism — anger recycled inward because outward expression never felt safe."
        case .defectiveOne:
            return "Hypervigilance about being ‘found out’; preemptive self-attack before others can criticise; profound difficulty receiving care, love, or genuine compliments."
        }
    }

    /// Core direction for healing / growth work
    var growthInvitation: String {
        switch self {
        case .abandonedChild:
            return "Practising safe dependence: letting trusted people in and soothing the fear of being left."
        case .loneWolf:
            return "Experimenting with small, safe forms of support and co-regulation."
        case .overachiever:
            return "Letting rest, imperfection, and limits exist without making them a verdict on your worth."
        case .invisibleOne:
            return "Taking up a little more space—voice, needs, preferences—in low-risk contexts."
        case .protector:
            return "Letting the guard soften when there’s enough safety — allowing feeling instead of managing."
        case .mask:
            return "Showing tiny pieces of the real you to people who have earned your trust."
        case .performer:
            return "Letting yourself be held, not just helpful, and tolerating moments where you’re not ‘on’."
        case .ghost:
            return "Gentle re-entry into body sensation — micro-doses of pleasure, movement, and breath. Learning that the body can be a home again, not a place to escape."
        case .buriedFire:
            return "Locating the anger as information — what boundary was crossed, what mattered? — rather than as threat. Finding safe channels for the fire before it turns inward again."
        case .defectiveOne:
            return "Separating shame from guilt. Tracing the verdict to its origin. Building — slowly — a felt sense of inherent worth that doesn’t depend on performance or approval."
        }
    }
}

// MARK: - Score wrapper

struct ArchetypeScore: Identifiable {
    let id = UUID()
    let archetype: ShadowArchetype
    let score: Int
}

// MARK: - Scoring Engine

struct ArchetypeEngine {

    /// Single canonical scoring used by both ContentView (hero card) and PatternsView (Archetypes tab).
    static func scores(from insights: [ShadowInsight], events: [SongEvent] = []) -> [ArchetypeScore] {
        var buckets: [ShadowArchetype: Int] = [:]
        func bump(_ type: ShadowArchetype, by amount: Int = 1) {
            buckets[type, default: 0] += amount
        }

        // 1) AI insights (same logic as PatternsView for consistency)
        for insight in insights {
            let blob = [
                insight.wound_type,
                insight.protector_mode,
                insight.core_belief,
                insight.summary
            ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

            // Abandoned Child
            if blob.containsAny(of: ["abandon", "left", "alone", "lonely", "rejected", "unwanted"]) {
                bump(.abandonedChild, by: 2)
            }
            if blob.containsAny(of: ["unworthy of love", "not lovable", "too much", "not enough"]) {
                bump(.abandonedChild, by: 1)
            }

            // Lone Wolf
            if blob.containsAny(of: ["can only rely on myself", "others are unsafe", "don’t need anyone", "better alone"]) {
                bump(.loneWolf, by: 2)
            }
            if blob.containsAny(of: ["distance", "shut down", "withdraw", "pull away"]) {
                bump(.loneWolf, by: 1)
            }

            // Overachiever
            if blob.containsAny(of: ["perform", "achieve", "perfect", "high standards", "failure is not allowed"]) {
                bump(.overachiever, by: 2)
            }
            if blob.containsAny(of: ["if i don’t", "need to prove", "never enough"]) {
                bump(.overachiever, by: 1)
            }

            // Invisible One
            if blob.containsAny(of: ["invisible", "not seen", "ignored", "overlooked", "fade into the background"]) {
                bump(.invisibleOne, by: 2)
            }
            if blob.containsAny(of: ["don’t take up space", "don’t want to bother", "stay quiet"]) {
                bump(.invisibleOne, by: 1)
            }

            // Protector
            if blob.containsAny(of: ["protector", "protect", "guard", "keep control", "shut it down"]) {
                bump(.protector, by: 2)
            }
            if blob.containsAny(of: ["fight", "freeze", "contain feelings"]) {
                bump(.protector, by: 1)
            }

            // Mask
            if blob.containsAny(of: ["hide feelings", "hide myself", "put on a face", "mask", "pretend"]) {
                bump(.mask, by: 2)
            }
            if blob.containsAny(of: ["people pleasing", "don’t show weakness", "keep it together"]) {
                bump(.mask, by: 1)
            }

            // Performer
            if blob.containsAny(of: ["performer", "entertainer", "make others laugh", "keep everyone happy"]) {
                bump(.performer, by: 2)
            }
            if blob.containsAny(of: ["fix the mood", "take care of everyone", "be the strong one"]) {
                bump(.performer, by: 1)
            }

            // Ghost
            if blob.containsAny(of: ["numb", "disconnected", "dissociat", "nothing lands", "can't feel", "frozen inside", "detached", "blank", "empty inside", "going through the motions"]) {
                bump(.ghost, by: 2)
            }
            if blob.containsAny(of: ["flat", "shut down", "switched off", "no feeling", "hollow", "not present", "checked out"]) {
                bump(.ghost, by: 1)
            }

            // Buried Fire
            if blob.containsAny(of: ["rage", "anger is dangerous", "can't be angry", "swallowed my anger", "buried anger", "suppressed rage", "anger turned inward", "fury"]) {
                bump(.buriedFire, by: 2)
            }
            if blob.containsAny(of: ["boiling", "explosion", "self-blame", "depression as anger", "no right to be angry", "punished for anger", "too much anger"]) {
                bump(.buriedFire, by: 1)
            }

            // Defective One
            if blob.containsAny(of: ["something wrong with me", "fundamentally broken", "unlovable", "defective", "if they knew the real me", "toxic shame", "inherently bad", "shameful at core"]) {
                bump(.defectiveOne, by: 2)
            }
            if blob.containsAny(of: ["shame", "not enough", "too much", "found out", "fraud", "worthless", "wrong with me", "damaged"]) {
                bump(.defectiveOne, by: 1)
            }
        }

        // 2) Raw impulses / sensations from events (same as PatternsView)
        let impulses = events.compactMap { $0.impulse?.lowercased() }
        let sensations = events.compactMap { $0.somatic_type?.lowercased() }
        let impulseCounts = Dictionary(grouping: impulses, by: { $0 }).mapValues { $0.count }
        let sensationCounts = Dictionary(grouping: sensations, by: { $0 }).mapValues { $0.count }
        if (impulseCounts["cry"] ?? 0) > 0 || (sensationCounts["tight"] ?? 0) > 0 { bump(.abandonedChild) }
        if (impulseCounts["disappear"] ?? 0) > 0 || (impulseCounts["hide"] ?? 0) > 0 { bump(.invisibleOne) }
        if (impulseCounts["attack"] ?? 0) > 0 { bump(.protector) }
        if (impulseCounts["cling"] ?? 0) > 0 { bump(.abandonedChild) }
        return buckets
            .map { ArchetypeScore(archetype: $0.key, score: $0.value) }
            .sorted { $0.score > $1.score }
    }
}

// MARK: - String helper

private extension String {
    func containsAny(of needles: [String]) -> Bool {
        let lower = self.lowercased()
        return needles.contains(where: { lower.contains($0) })
    }
}

// MARK: - UI Card

struct ShadowArchetypeCard: View {
    let primary: ArchetypeScore?
    let secondary: ArchetypeScore?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shadow archetype")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Music Shadow’s best guess at the pattern your triggers are orbiting around. It will update as you log more.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            if let primary {
                HStack(spacing: 12) {
                    Image(primary.archetype.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(MSTheme.primaryText)
                        .scaledToFit()
                        .frame(width: 52, height: 52)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(primary.archetype.rawValue)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        Text(primary.archetype.tagline)
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text(primary.archetype.longDescription)
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 4)
            } else {
                Text("Log a few triggers with reflections to unlock your archetype.")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .padding(.top, 4)
            }

            if let secondary {
                Divider()
                    .background(MSTheme.cardStroke)

                HStack(spacing: 6) {
                    Text("Secondary pattern:")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text(secondary.archetype.rawValue)
                        .font(.caption)
                        .foregroundColor(MSTheme.primaryText)

                    Spacer()
                }
            }
        }
        .shadowCard()
    }
}
