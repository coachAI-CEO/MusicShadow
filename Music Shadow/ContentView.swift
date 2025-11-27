import SwiftUI
import Supabase

struct ContentView: View {
    // Data
    @State private var events: [SongEvent] = []
    @State private var insights: [ShadowInsight] = []

    // UI state
    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Hero + “Why this works” link
                        greetingSection

                        if isLoading {
                            ProgressView("Loading your shadow data…")
                                .foregroundColor(.white)
                                .padding(.top, 40)
                        } else if let errorMessage {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                                .padding(.top, 24)
                        } else {
                            // 1) Shadow weather
                            if let weather = shadowWeather {
                                ShadowWeatherCard(weather: weather)
                            }

                            // 2) Patterns at a glance (top body / impulse / sensation)
                            if let snapshot = topPatternSnapshot {
                                PatternsGlanceCard(snapshot: snapshot)
                            }

                            // 3) Today’s shadow practice (from latest AI insight)
                            if let latest = latestInsight,
                               let practice = latest.suggested_practice,
                               !practice.isEmpty {
                                ShadowPracticeCard(practice: practice)
                            }

                            // 4) Latest reflection (summary + practice from AI)
                            if let latest = latestInsight {
                                LatestReflectionCard(insight: latest)
                            }

                            // 5) Primary actions
                            primaryActions
                        }
                    }
                    .padding(24)
                }
                .musicShadowBackground()
            }
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await loadEvents()
                await loadInsights()
            }
        }
    }
}

// MARK: - Hero / Greeting

extension ContentView {
    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Music Shadow")
                .font(.largeTitle.bold())
                .foregroundColor(MSTheme.primaryText)

            if let weather = shadowWeather {
                Text(weather.subtitle)
                    .font(.subheadline)
                    .foregroundColor(MSTheme.secondaryText)
                    .lineSpacing(2)
            } else {
                Text("Your inner world is in motion.")
                    .font(.subheadline)
                    .foregroundColor(MSTheme.secondaryText)
                    .lineSpacing(2)
            }

            // Link to “Why it works” explainer page
            NavigationLink {
                WhyItWorksView()
            } label: {
                HStack(spacing: 4) {
                    Text("Why this works")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "info.circle")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.06))
                )
                .foregroundColor(MSTheme.secondaryText)
            }
            .buttonStyle(PlainButtonStyle())
            .padding(.top, 4)
        }
        .padding(.top, 12)
    }
}

// MARK: - Cards

// 1) Shadow weather card

struct ShadowWeatherCard: View {
    let weather: ShadowWeather

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Shadow weather")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            HStack(alignment: .top, spacing: 12) {
                Text(weather.emoji)
                    .font(.system(size: 32))

                VStack(alignment: .leading, spacing: 4) {
                    Text(weather.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Text(weather.description)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .shadowCard()
    }
}

// 2) Patterns at a glance

struct PatternsGlanceSnapshot {
    let topBody: CountItem?
    let topImpulse: CountItem?
    let topSomatic: CountItem?
}

struct PatternsGlanceCard: View {
    let snapshot: PatternsGlanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your patterns at a glance")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Quick snapshot of where things tend to land.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            HStack(spacing: 10) {
                if let topBody = snapshot.topBody {
                    patternPill(
                        label: "Body hotspot",
                        value: topBody.label.capitalized,
                        count: topBody.count
                    )
                }
                if let topImpulse = snapshot.topImpulse {
                    patternPill(
                        label: "Impulse",
                        value: topImpulse.label.capitalized,
                        count: topImpulse.count
                    )
                }
                if let topSomatic = snapshot.topSomatic {
                    patternPill(
                        label: "Sensation",
                        value: topSomatic.label.capitalized,
                        count: topSomatic.count
                    )
                }
            }
        }
        .shadowCard()
    }

    private func patternPill(label: String, value: String, count: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption2.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)

            Text("\(count)x")
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
    }
}

// 3) Today’s shadow practice

struct ShadowPracticeCard: View {
    let practice: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today’s shadow practice")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundColor(.purple.opacity(0.9))
                    .font(.caption)

                Text(practice)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .shadowCard()
    }
}

// 4) Latest reflection card

struct LatestReflectionCard: View {
    let insight: ShadowInsight

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest reflection")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            if let summary = insight.summary, !summary.isEmpty {
                Text(summary)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let practice = insight.suggested_practice, !practice.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "hands.sparkles")
                        .foregroundColor(.blue.opacity(0.9))
                        .font(.caption)

                    Text(practice)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .shadowCard()
    }
}

// MARK: - Primary Actions

extension ContentView {
    private var primaryActions: some View {
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
            .buttonStyle(PlainButtonStyle())

            // View patterns
            NavigationLink {
                PatternsView()
            } label: {
                HStack {
                    Image(systemName: "chart.bar.fill")
                    Text("View patterns")
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
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.top, 8)
    }
}

// MARK: - Weather + Aggregations

// Simple weather model derived from recent intensity
struct ShadowWeather {
    let emoji: String
    let title: String
    let subtitle: String
    let description: String
}

extension ContentView {

    // Top counts – uses shared CountItem type (defined once, e.g. in PatternsView.swift)
    private var bodyLocationCounts: [CountItem] {
        aggregate(events.compactMap { $0.body_location })
    }

    private var impulseCounts: [CountItem] {
        aggregate(events.compactMap { $0.impulse })
    }

    private var somaticCounts: [CountItem] {
        aggregate(events.compactMap { $0.somatic_type })
    }

    private func aggregate(_ items: [String]) -> [CountItem] {
        Dictionary(grouping: items, by: { $0 })
            .map { key, value in CountItem(label: key, count: value.count) }
            .sorted { $0.count > $1.count }
    }

    private var intensitySeries: [IntensityPoint] {
        let formatter = ISO8601DateFormatter()
        return events.compactMap { event in
            guard
                let createdString = event.created_at,
                let date = formatter.date(from: createdString),
                let intensity = event.intensity
            else { return nil }

            return IntensityPoint(date: date, intensity: intensity)
        }
        .sorted { $0.date < $1.date }
    }

    // Latest AI insight (supabase is ordered DESC in loader)
    private var latestInsight: ShadowInsight? {
        insights.first
    }

    // Patterns snapshot for “at a glance”
    private var topPatternSnapshot: PatternsGlanceSnapshot? {
        guard !events.isEmpty else { return nil }
        return PatternsGlanceSnapshot(
            topBody: bodyLocationCounts.first,
            topImpulse: impulseCounts.first,
            topSomatic: somaticCounts.first
        )
    }

    // Simple weather computed from recent intensities
    private var shadowWeather: ShadowWeather? {
        guard !intensitySeries.isEmpty else { return nil }

        let recent = intensitySeries.suffix(10)
        let values = recent.map { $0.intensity }

        guard let maxVal = values.max() else { return nil }
        let avg = Double(values.reduce(0, +)) / Double(values.count)

        if maxVal <= 4 {
            return ShadowWeather(
                emoji: "☁️",
                title: "Gentle",
                subtitle: "Your system has been relatively soft lately.",
                description: "Intensity has stayed on the lower side. This is a good window for gently exploring patterns without overwhelm."
            )
        } else if maxVal >= 8 && avg >= 6 {
            return ShadowWeather(
                emoji: "⛈️",
                title: "Stormy",
                subtitle: "Your system has been flaring more often.",
                description: "Spikes have been strong and frequent. This might be a time to move slowly, lean on support, and use the gentlest practices."
            )
        } else {
            return ShadowWeather(
                emoji: "🌤️",
                title: "Shifting",
                subtitle: "Intensity has been up and down.",
                description: "Something is moving under the surface—this is often when new insights and connections start to land."
            )
        }
    }
}

// MARK: - Supabase loading

extension ContentView {
    private func loadEvents() async {
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

    private func loadInsights() async {
        do {
            let client = SupabaseClientManager.shared.client

            guard let session = client.auth.currentSession else {
                return
            }

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
