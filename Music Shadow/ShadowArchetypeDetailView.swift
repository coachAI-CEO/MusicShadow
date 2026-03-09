import SwiftUI

/// Rich info for each archetype.
/// NOTE: uses your existing `ShadowArchetypeID` enum from PatternsView.
struct ShadowArchetypeInfo: Identifiable {
    let id = UUID()
    let archetypeID: ShadowArchetypeID
    let name: String
    let emoji: String
    let tagline: String
    let description: String
    let growthInvitation: String
    /// Optional image asset name (AI art etc). Safe if missing.
    let imageName: String
}

private let allArchetypeInfos: [ShadowArchetypeInfo] = [
    .init(
        archetypeID: .abandonedChild,
        name: "The Abandoned Child",
        emoji: "🧸",
        tagline: "Fears being left, unseen, or too much.",
        description: "This part carries old experiences of disconnection, rejection, or being emotionally alone. Spikes often show up around closeness, texting, plans changing, or feeling ‘too much’.",
        growthInvitation: "Offer reassurance, warmth, and clear communication. Practices around self-soothing, attachment repair, and asking for what you need are especially powerful here.",
        imageName: "archetype_abandoned_child"
    ),
    .init(
        archetypeID: .loneWolf,
        name: "The Lone Wolf",
        emoji: "🐺",
        tagline: "Handles everything alone to stay safe.",
        description: "This part learned that relying on others is risky. It prefers distance, self-reliance, and disappearing when things feel overwhelming or vulnerable.",
        growthInvitation: "Experiment with small doses of co-regulation and healthy dependency. Let trusted people in a little bit at a time.",
        imageName: "archetype_lone_wolf"
    ),
    .init(
        archetypeID: .overachiever,
        name: "The Overachiever",
        emoji: "🏅",
        tagline: "Tries to earn worth through doing and succeeding.",
        description: "This part is driven, hard-working, and terrified of ‘not enough’. Spikes often land around performance, feedback, and any sense of failure.",
        growthInvitation: "Practice resting on purpose, receiving appreciation without deflecting, and doing things badly on purpose to widen your window of safety.",
        imageName: "archetype_overachiever"
    ),
    .init(
        archetypeID: .invisibleOne,
        name: "The Invisible One",
        emoji: "👻",
        tagline: "Stays small to avoid being a burden.",
        description: "This part learned that blending in, staying quiet, or disappearing kept the peace. Spikes often show when you’re ignored, interrupted, or overlooked.",
        growthInvitation: "Experiment with taking up 5% more space: speaking first, sharing opinions, or correcting mis-understandings gently.",
        imageName: "archetype_invisible"
    ),
    .init(
        archetypeID: .protector,
        name: "The Protector",
        emoji: "🛡️",
        tagline: "Stays on guard, scanning for threat.",
        description: "This part steps in fast with anger, shutdown, or control when it senses danger. It’s usually protecting something very young and soft underneath.",
        growthInvitation: "Appreciate its job, then offer alternative protections: boundaries, slowing down, or stepping away before things boil over.",
        imageName: "archetype_protector"
    ),
    .init(
        archetypeID: .mask,
        name: "The Mask",
        emoji: "🎭",
        tagline: "Shows the acceptable self, hides the rest.",
        description: "This part manages image, likability, and approval. It can be charming, smooth, and exhausted from keeping everything ‘together’.",
        growthInvitation: "Let trusted people see 1–2% more truth at a time. Practice saying ‘actually…’ and naming your real preference.",
        imageName: "archetype_mask"
    ),
    .init(
        archetypeID: .performer,
        name: "The Performer",
        emoji: "🎤",
        tagline: "Wins love through doing, entertaining, and supporting.",
        description: "This part reads the room, takes care of everyone, and panics when the ‘audience’ disappears. It confuses being useful with being lovable.",
        growthInvitation: "Experiment with being present without fixing. Let others come toward you, and track who values you when you’re not ‘on’.",
        imageName: "archetype_performer"
    )
]

/// Overview of all archetypes (optional highlight by name). Single-archetype detail is in Views/ContentView.swift.
struct ShadowArchetypeOverviewView: View {
    /// Optional current archetype name to highlight.
    let currentName: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shadow archetypes")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("A playful map of the patterns your triggers tend to cluster around. These are lenses, not boxes.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 12)

                // Info cards
                ForEach(allArchetypeInfos) { info in
                    ArchetypeInfoCard(
                        info: info,
                        isCurrent: currentName == info.name
                    )
                }

                Text("These archetypes are not diagnoses. They’re a way to speak about repeating emotional patterns with more kindness and curiosity.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .padding(.bottom, 12)
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArchetypeInfoCard: View {
    let info: ShadowArchetypeInfo
    let isCurrent: Bool

    var body: some View {
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
                        .frame(width: 44, height: 44)

                    Text(info.emoji)
                        .font(.title2)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(info.name)
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text(info.tagline)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if !info.imageName.isEmpty {
                Image(info.imageName)        // add AI art with these names in Assets
                    .resizable()
                    .scaledToFill()
                    .frame(maxWidth: .infinity)
                    .frame(height: 160)
                    .clipped()
                    .cornerRadius(16)
            }

            Text(info.description)
                .font(.footnote)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 4) {
                Text("Growth invitation")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)

                Text(info.growthInvitation)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(isCurrent ? 0.09 : 0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(
                    isCurrent ? Color.purple.opacity(0.7) : MSTheme.cardStroke,
                    lineWidth: isCurrent ? 1.3 : 0.8
                )
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }
}
