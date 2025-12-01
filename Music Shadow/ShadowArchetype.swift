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

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .abandonedChild: return "🧸"
        case .loneWolf:       return "🐺"
        case .overachiever:   return "🏅"
        case .invisibleOne:   return "👤"
        case .protector:      return "🛡️"
        case .mask:           return "🎭"
        case .performer:      return "🎤"
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
            return "This pattern jumps in to manage risk, anger, or chaos. It can shut feelings down fast to keep things under control."
        case .mask:
            return "This pattern curates what others see. Vulnerable parts stay behind a mask of ‘fine’, ‘together’, or ‘easygoing’."
        case .performer:
            return "This pattern reaches for charm, humour, or caretaking to stay liked and safe. Being deeply seen can feel exposing."
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

    static func scores(from insights: [ShadowInsight]) -> [ArchetypeScore] {
        guard !insights.isEmpty else { return [] }

        var buckets: [ShadowArchetype: Int] = [:]

        for insight in insights {
            let blob = [
                insight.wound_type,
                insight.protector_mode,
                insight.core_belief,
                insight.summary
            ]
            .compactMap { $0?.lowercased() }
            .joined(separator: " ")

            func bump(_ type: ShadowArchetype, by amount: Int = 1) {
                buckets[type, default: 0] += amount
            }

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
        }

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
                    Text(primary.archetype.emoji)
                        .font(.largeTitle)

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
