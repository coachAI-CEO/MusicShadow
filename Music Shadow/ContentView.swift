import SwiftUI
import Supabase

struct ContentView: View {

    // MARK: - Data
    @State private var events: [SongEvent] = []
    @State private var insights: [ShadowInsight] = []

    // MARK: - UI State
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // HERO
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Music Shadow")
                            .font(.largeTitle.bold())
                            .foregroundColor(MSTheme.primaryText)

                        Text("Your inner world is in motion.")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                    .padding(.top, 12)

                    if isLoading {
                        ProgressView("Loading your shadow patterns…")
                            .foregroundColor(.white)
                            .padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        // MARK: 1. Shadow weather
                        if let weather = shadowWeatherSnapshot {
                            ShadowWeatherCard(snapshot: weather)
                        }

                        // MARK: 2. Patterns at a glance (+ archetype)
                        let snapshot = patternsGlanceSnapshot
                        if snapshot.topBody != nil ||
                            snapshot.topImpulse != nil ||
                            snapshot.topSomatic != nil ||
                            snapshot.archetype != nil {
                            PatternsGlanceCard(snapshot: snapshot)
                        }

                        // MARK: 3. Today’s shadow practice
                        TodayPracticeCard(latestInsight: insights.first)

                        // MARK: 4. Latest reflection
                        LatestReflectionCard(latestInsight: insights.first)

                        // MARK: 5. Why this works
                        WhyItWorksCard()
                    }

                    // MARK: 6. Primary actions
                    VStack(spacing: 14) {
                        // Log a new trigger
                        NavigationLink {
                            NewTriggerView()
                        } label: {
                            HStack {
                                Image(systemName: "plus.circle.fill")
                                Text("Log a new trigger")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .cornerRadius(18)
                        }
                        .buttonStyle(.plain)

                        // Open full patterns view
                        NavigationLink {
                            PatternsView()
                        } label: {
                            HStack {
                                Image(systemName: "chart.bar.fill")
                                Text("Open full patterns view")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                                    )
                            )
                            .foregroundColor(MSTheme.primaryText)
                        }
                        .buttonStyle(.plain)

                        // Guided somatic practice CTA
                        NavigationLink {
                            GuidedPracticeView(practice: SomaticToolkit.defaultPractice)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "person.wave.2.fill")
                                    .font(.title3)
                                    .foregroundColor(.purple)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Try a shadow practice now")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundColor(MSTheme.primaryText)

                                    Text("A short guided exercise to regulate your nervous system.")
                                        .font(.caption)
                                        .foregroundColor(MSTheme.secondaryText)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(MSTheme.secondaryText)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.06))
                            )
                        }
                        .buttonStyle(.plain)
                    }

                    // FOOTER
                    Text("Every track you log is a step toward knowing your shadow.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 4)
                }
                .padding(24)
            }
            // 🔥 This is what gives you the dark gradient background.
            .musicShadowBackground()
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadEvents()
                await loadInsights()
            }
        }
    }
}

 // MARK: - Shadow Weather

struct ShadowWeatherSnapshot {
    let emoji: String
    let title: String
    let description: String
}

private extension ContentView {

    /// Uses last 7 events' intensity to give a simple weather status.
    var shadowWeatherSnapshot: ShadowWeatherSnapshot? {
        let recent = events.prefix(7)
        let intensities = recent.compactMap { $0.intensity }

        guard !intensities.isEmpty else {
            return ShadowWeatherSnapshot(
                emoji: "☁️",
                title: "Not enough data yet",
                description: "Log a few triggers and your shadow weather will start to show up here."
            )
        }

        let average = Double(intensities.reduce(0, +)) / Double(intensities.count)

        switch average {
        case ..<3:
            return ShadowWeatherSnapshot(
                emoji: "🌙",
                title: "Calm",
                description: "Intensity has been on the softer side. Your system feels relatively steady right now."
            )
        case 3..<6:
            return ShadowWeatherSnapshot(
                emoji: "⛅️",
                title: "Shifting",
                description: "Intensity has been up and down. Something is moving under the surface—this is often when new insights start to land."
            )
        default:
            return ShadowWeatherSnapshot(
                emoji: "⛈️",
                title: "Activated",
                description: "Your shadow has been loud lately. This is a powerful time to slow down, notice patterns, and lean on grounding practices."
            )
        }
    }
}

struct ShadowWeatherCard: View {
    let snapshot: ShadowWeatherSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shadow weather")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            HStack(alignment: .top, spacing: 12) {
                Text(snapshot.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(snapshot.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Text(snapshot.description)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .shadowCard()
    }
}

 // MARK: - Patterns at a glance (+ archetype)

struct TopItemSummary {
    let label: String
    let count: Int
}

struct ArchetypeSummary {
    let name: String
    let tagline: String
}

struct PatternsGlanceSnapshot {
    let topBody: TopItemSummary?
    let topImpulse: TopItemSummary?
    let topSomatic: TopItemSummary?
    let archetype: ArchetypeSummary?
}

private extension ContentView {

    var patternsGlanceSnapshot: PatternsGlanceSnapshot {
        let body = topItem(from: events.compactMap { $0.body_location })
        let impulse = topItem(from: events.compactMap { $0.impulse })
        let somatic = topItem(from: events.compactMap { $0.somatic_type })
        let archetype = archetypeSummary(from: insights)

        return PatternsGlanceSnapshot(
            topBody: body,
            topImpulse: impulse,
            topSomatic: somatic,
            archetype: archetype
        )
    }

    func topItem(from items: [String]) -> TopItemSummary? {
        guard !items.isEmpty else { return nil }

        let counts = Dictionary(grouping: items, by: { $0 })
            .map { (key, value) in (label: key, count: value.count) }
            .sorted { $0.count > $1.count }

        guard let top = counts.first else { return nil }
        return TopItemSummary(label: top.label, count: top.count)
    }

    func archetypeSummary(from insights: [ShadowInsight]) -> ArchetypeSummary? {
        guard !insights.isEmpty else { return nil }

        let beliefs = insights.compactMap { $0.core_belief?.lowercased() }
        let protections = insights.compactMap { $0.protector_mode?.lowercased() }

        let text = (beliefs + protections).joined(separator: " ")

        if text.contains("alone") || text.contains("unlovable") {
            return ArchetypeSummary(
                name: "The Abandoned Child",
                tagline: "Carries fear of being left, rejected, or forgotten."
            )
        }
        if text.contains("independent") || text.contains("don’t need") {
            return ArchetypeSummary(
                name: "The Lone Wolf",
                tagline: "Keeps distance to stay safe, even when craving connection."
            )
        }
        if text.contains("not enough") || text.contains("prove") {
            return ArchetypeSummary(
                name: "The Overachiever",
                tagline: "Tries to earn worth through doing, fixing, and performing."
            )
        }
        if text.contains("invisible") || text.contains("seen") {
            return ArchetypeSummary(
                name: "The Invisible One",
                tagline: "Hides needs and feelings to avoid being a burden."
            )
        }
        if text.contains("protect") || text.contains("control") {
            return ArchetypeSummary(
                name: "The Protector",
                tagline: "Stays on guard, watching for threats—outside and inside."
            )
        }
        if text.contains("mask") || text.contains("people-pleas") {
            return ArchetypeSummary(
                name: "The Mask",
                tagline: "Shows only the acceptable parts, hiding softer truths."
            )
        }
        if text.contains("perform") || text.contains("perfect") {
            return ArchetypeSummary(
                name: "The Performer",
                tagline: "Turns life into a stage to feel valued and safe."
            )
        }

        // Default fallback if nothing clear
        return ArchetypeSummary(
            name: "In transition",
            tagline: "Your patterns are still taking shape as you log more triggers."
        )
    }
}

struct PatternsGlanceCard: View {
    let snapshot: PatternsGlanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Your patterns at a glance")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Quick snapshot of where things tend to land.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            // Top stats row
            HStack(spacing: 12) {
                if let body = snapshot.topBody {
                    PatternStatTile(
                        icon: "figure.arms.open",
                        title: "Body hotspot",
                        value: body.label.capitalized,
                        count: "\(body.count)x"
                    )
                }

                if let impulse = snapshot.topImpulse {
                    PatternStatTile(
                        icon: "figure.run",
                        title: "Impulse",
                        value: impulse.label.capitalized,
                        count: "\(impulse.count)x"
                    )
                }

                if let somatic = snapshot.topSomatic {
                    PatternStatTile(
                        icon: "waveform.path.ecg",
                        title: "Sensation",
                        value: somatic.label.capitalized,
                        count: "\(somatic.count)x"
                    )
                }
            }

            // Archetype row
            if let archetype = snapshot.archetype {
                ArchetypeTile(archetype: archetype)
            }
        }
        .shadowCard()
    }
}

/// Small rounded stat pill for body / impulse / sensation
private struct PatternStatTile: View {
    let icon: String
    let title: String
    let value: String
    let count: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))

                Text(title.uppercased())
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.85))
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)

            Text(count)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.75))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0.10),
                            Color.white.opacity(0.04)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
        )
        .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 8)
    }
}

/// Larger tile for the archetype section
private struct ArchetypeTile: View {
    let archetype: ArchetypeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.purple, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)

                    Image(systemName: "brain.head.profile")
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 20, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Shadow archetype")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text(archetype.name)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Text(archetype.tagline)
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            // Learn-more pill
            NavigationLink {
                ShadowArchetypeDetailView(currentName: archetype.name)
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "square.grid.2x2")
                        .font(.caption2)
                    Text("Meet the archetypes")
                        .font(.caption2.weight(.semibold))
                    Image(systemName: "chevron.right")
                        .font(.caption2)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.07))
                )
                .foregroundColor(MSTheme.primaryText)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(MSTheme.cardStroke, lineWidth: 0.8)
        )
    }
}
 // MARK: - Today’s Practice + Latest Reflection

struct TodayPracticeCard: View {
    let latestInsight: ShadowInsight?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s shadow practice")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            if let practice = latestInsight?.suggested_practice, !practice.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.purple.opacity(0.9))
                        .font(.caption)

                    Text(practice)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            } else {
                Text("Log a few triggers and Music Shadow will offer you a simple practice to try.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .shadowCard()
    }
}

struct LatestReflectionCard: View {
    let latestInsight: ShadowInsight?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest reflection")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            if let summary = latestInsight?.summary, !summary.isEmpty {
                Text(summary)
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("Once you’ve logged a few triggers, your AI reflections will show up here.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
            }

            if let practice = latestInsight?.suggested_practice, !practice.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue.opacity(0.9))
                        .font(.caption)

                    Text(practice)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .shadowCard()
    }
}


// MARK: - Why this works

struct WhyItWorksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Why this works")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Music taps into memory, emotion, and body all at once. By logging the spikes, you’re building a map of how your nervous system responds—and giving your shadow a language.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                WhyItWorksView()
            } label: {
                HStack {
                    Text("Learn the science behind it")
                        .font(.subheadline.weight(.semibold))

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .stroke(MSTheme.cardStroke, lineWidth: 1)
                        )
                )
                .foregroundColor(MSTheme.primaryText)
            }
            .buttonStyle(.plain)
        }
        .shadowCard()
    }
}

 // MARK: - Supabase loading

private extension ContentView {
    func loadEvents() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let client = SupabaseClientManager.shared.client
            guard let session = client.auth.currentSession else {
                await MainActor.run {
                    errorMessage = "No active user session."
                    isLoading = false
                }
                return
            }

            let userId = session.user.id
            let result: [SongEvent] = try await client
                .from("song_events")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                events = result
                isLoading = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Error loading events: \(error.localizedDescription)"
                isLoading = false
            }
        }
    }

    func loadInsights() async {
        do {
            let client = SupabaseClientManager.shared.client
            guard let session = client.auth.currentSession else { return }

            let userId = session.user.id
            let result: [ShadowInsight] = try await client
                .from("shadow_insights")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            await MainActor.run {
                insights = result
            }
        } catch {
            print("Error loading insights: \(error)")
        }
    }
}
