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

    /// Short paragraph for summary card
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

// MARK: - Rich details for the full-page view

struct ShadowArchetypeDetail: Identifiable {
    let id = UUID()
    let archetype: ShadowArchetype
    let growthInvitation: String
    let deeperDescription: String
    let typicalSpikes: String
}

extension ShadowArchetypeDetail {
    static let all: [ShadowArchetypeDetail] = [
        .init(
            archetype: .abandonedChild,
            growthInvitation: "Offer reassurance, warmth, and clear communication. Practices around self-soothing, attachment repair, and asking for what you need are especially powerful here.",
            deeperDescription: "This part carries old experiences of disconnection, rejection, or being emotionally alone. Spikes often show up around closeness, texting, plans changing, or feeling ‘too much’.",
            typicalSpikes: "Messages left on read, cancellations, someone seeming distant, or feeling like you’re not a priority."
        ),
        .init(
            archetype: .loneWolf,
            growthInvitation: "Experiment with letting trusted people in a little more. Tiny acts of asking for help, sharing feelings, or staying present when you want to bolt are big wins.",
            deeperDescription: "This pattern learned that relying on others can be risky. Independence became armour. It often shows up as pulling away when things get vulnerable.",
            typicalSpikes: "Conflict, expectations from others, needing to depend on someone, or feeling smothered."
        ),
        .init(
            archetype: .overachiever,
            growthInvitation: "Practice ‘good enough’ instead of perfect. Schedule rest on purpose, celebrate effort over outcome, and notice the part of you that is worthy even when you’re not producing.",
            deeperDescription: "This pattern ties safety to doing and achieving. It tracks mistakes closely and can’t relax when there’s more to do.",
            typicalSpikes: "Feedback, feeling behind, comparing yourself to others, or any sense of ‘failing’."
        ),
        .init(
            archetype: .invisibleOne,
            growthInvitation: "Play with taking up a tiny bit more space — sharing an opinion, asking for a preference, or letting your feelings be known to safe people.",
            deeperDescription: "This pattern learned that being small or quiet was safer. It keeps needs hidden so you don’t become ‘too much’ or a burden.",
            typicalSpikes: "Being talked over, not being invited, feeling forgotten, or watching others get attention."
        ),
        .init(
            archetype: .protector,
            growthInvitation: "Instead of fighting this part, thank it for trying to keep you safe. Then gently explore what it’s afraid would happen if it relaxed 5% today.",
            deeperDescription: "This is your inner bodyguard. It’s scanning for danger and ready to shut feelings down or go on the offensive.",
            typicalSpikes: "Criticism, perceived disrespect, chaos, or any hint that someone might hurt you or people you love."
        ),
        .init(
            archetype: .mask,
            growthInvitation: "Experiment with safe, tiny doses of realness — sharing one honest sentence more than usual or letting someone see you when you’re not ‘together’.",
            deeperDescription: "This pattern curates what is shown and what is hidden. It protects softer parts from shame, judgement, or rejection.",
            typicalSpikes: "High-stakes social situations, new groups, or any time you fear being judged."
        ),
        .init(
            archetype: .performer,
            growthInvitation: "Practice being valued just for existing, not for entertaining or fixing. Let yourself be quiet or messy with safe people.",
            deeperDescription: "This pattern keeps things light, fun, or helpful so you stay appreciated and safe. Underneath, there’s often a fear of being boring, needy, or ‘too much’.",
            typicalSpikes: "Tension in the room, someone else being upset, or silence where you’re not sure if you’re wanted."
        )
    ]
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
            if blob.containsAny(of: ["can only rely on myself", "others are unsafe", "don’t need anyone", "dont need anyone", "better alone"]) {
                bump(.loneWolf, by: 2)
            }
            if blob.containsAny(of: ["distance", "shut down", "withdraw", "pull away"]) {
                bump(.loneWolf, by: 1)
            }

            // Overachiever
            if blob.containsAny(of: ["perform", "achieve", "perfect", "high standards", "failure is not allowed"]) {
                bump(.overachiever, by: 2)
            }
            if blob.containsAny(of: ["if i don’t", "if i dont", "need to prove", "never enough"]) {
                bump(.overachiever, by: 1)
            }

            // Invisible One
            if blob.containsAny(of: ["invisible", "not seen", "ignored", "overlooked", "fade into the background"]) {
                bump(.invisibleOne, by: 2)
            }
            if blob.containsAny(of: ["don’t take up space", "dont take up space", "don’t want to bother", "dont want to bother", "stay quiet"]) {
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
            if blob.containsAny(of: ["people pleasing", "people-pleasing", "don’t show weakness", "keep it together"]) {
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

// MARK: - Home Card (summary)

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

            // Learn more button → full archetype page
            NavigationLink {
                ShadowArchetypesView()
            } label: {
                HStack(spacing: 6) {
                    Text("Explore all shadow archetypes")
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .shadowCard()
    }
}

// MARK: - Full Archetypes Page

struct ShadowArchetypesView: View {
    @State private var selectedArchetypeID: ShadowArchetype.ID?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Hero
                VStack(alignment: .leading, spacing: 6) {
                    Text("Shadow archetypes")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("A playful map of the patterns your triggers tend to cluster around. These are lenses, not boxes.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)

                // Science section
                VStack(alignment: .leading, spacing: 8) {
                    Text("The science behind archetypes")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("""
These patterns are inspired by depth psychology (Carl Jung), parts-based models like Internal Family Systems (IFS), and modern nervous-system science.

Instead of “who you are”, they describe how your system tends to protect you when it feels threatened or vulnerable.
""")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // Which one feels most like you?
                VStack(alignment: .leading, spacing: 8) {
                    Text("Which one feels most like you lately?")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("There’s no right answer. Let your body react — which card gives you a little pang of “ugh… that’s me”?")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    if let selected = selectedArchetypeDetail {
                        HStack(spacing: 8) {
                            Text(selected.archetype.emoji)
                            Text("You chose: \(selected.archetype.rawValue)")
                                .font(.caption.weight(.semibold))
                            Spacer()
                        }
                        .padding(8)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.06))
                        )
                    }
                }

                // Archetype cards
                VStack(spacing: 16) {
                    ForEach(ShadowArchetypeDetail.all) { detail in
                        ArchetypeDetailCard(
                            detail: detail,
                            isSelected: detail.archetype.id == selectedArchetypeID
                        ) {
                            selectedArchetypeID = detail.archetype.id
                        }
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }

    private var selectedArchetypeDetail: ShadowArchetypeDetail? {
        ShadowArchetypeDetail.all.first { $0.archetype.id == selectedArchetypeID }
    }
}

// MARK: - Detail Card

private struct ArchetypeDetailCard: View {
    let detail: ShadowArchetypeDetail
    let isSelected: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 46, height: 46)

                        Text(detail.archetype.emoji)
                            .font(.title2)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(detail.archetype.rawValue)
                            .font(.headline)
                            .foregroundColor(MSTheme.primaryText)

                        Text(detail.archetype.tagline)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    Spacer()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.deeperDescription)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Typical spikes")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text(detail.typicalSpikes)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Growth invitation")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 4)

                    Text(detail.growthInvitation)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 26, style: .continuous)
                            .stroke(
                                isSelected ? Color.purple.opacity(0.9) : MSTheme.cardStroke,
                                lineWidth: isSelected ? 1.6 : 0.9
                            )
                    )
            )
        }
        .buttonStyle(.plain)
    }
}
