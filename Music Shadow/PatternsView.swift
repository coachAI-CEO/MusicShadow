import SwiftUI
import Supabase

// MARK: - Patterns View

struct PatternsView: View {
    @State private var events: [SongEvent] = []
    @State private var insights: [ShadowInsight] = []

    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    // Daily radar toggle (notifications can hook here later)
    @State private var radarRemindersEnabled: Bool = false

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Patterns")
                            .font(.title.bold())
                            .foregroundColor(MSTheme.primaryText)

                        Text("See how your triggers cluster across body, impulses, sensations, and AI reflections.")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)

                    if isLoading {
                        ProgressView("Loading your patterns…")
                            .foregroundColor(.white)
                            .padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        // 1) Daily Emotional Radar
                        if !radarPoints.isEmpty {
                            DailyRadarCard(
                                points: radarPoints,
                                remindersEnabled: $radarRemindersEnabled
                            )
                        }

                        // 2) Somatic map
                        if !events.isEmpty {
                            SomaticMapCard(bodyCounts: bodyLocationCounts)
                        }

                        // 3) Response patterns
                        if !events.isEmpty {
                            ResponsePatternsCard(
                                impulseCounts: impulseCounts,
                                somaticCounts: somaticCounts
                            )
                        }

                        // 4) Shadow Archetype snapshot
                        let archetypeScores = ArchetypeEngine.scores(from: insights, events: events)
                        if !archetypeScores.isEmpty {
                            ShadowArchetypeCard(
                                primary: archetypeScores.first,
                                secondary: archetypeScores.count > 1 ? archetypeScores[1] : nil
                            )
                        }

                        // 4b) Light archetype snapshot (from positive hits only)
                        let lightScores = ArchetypeEngine.lightScores(from: insights, events: events)
                        if !lightScores.isEmpty {
                            ShadowArchetypeCard(
                                primary: lightScores.first,
                                secondary: lightScores.count > 1 ? lightScores[1] : nil,
                                title: "Light archetype",
                                blurb: "What your positive hits point to: the songs that open, free or connect you. It updates as you log more.",
                                emptyText: "Log a few positive hits with reflections to see what lifts you.",
                                secondaryLabel: "Also showing up:"
                            )
                        }

                        // 5) AI Themes snapshot
                        if !insights.isEmpty {
                            AIThemesCard(insights: insights)
                        }

                        // 6) Song Activation Analytics (summary card → full dashboard)
                        if !songActivationAggregates.isEmpty {
                            NavigationLink {
                                SongAnalyticsView(events: events)
                            } label: {
                                SongActivationCard(songs: songActivationAggregates)
                                    .contentShape(Rectangle()) // whole card tappable
                            }
                            .buttonStyle(.plain)
                        }

                        // 7) Logged Triggers CTA
                        if !events.isEmpty {
                            NavigationLink {
                                AllTriggersView(events: events)
                            } label: {
                                Text("Your logged triggers")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(MSTheme.primaryText)
                                    .padding(.vertical, 12)
                                    .padding(.horizontal, 32)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(Color.white.opacity(0.06))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                                            )
                                    )
                            }
                            .buttonStyle(PlainButtonStyle())
                            .padding(.top, 4)
                        }
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
        .onChange(of: radarRemindersEnabled) { newValue in
            // Hook notifications later if you want
            print("Radar reminders toggled: \(newValue)")
        }
    }
}

// MARK: - Daily Emotional Radar

struct RadarDayPoint: Identifiable {
    let id = UUID()
    let date: Date
    let label: String
    let averageIntensity: Double
    let isToday: Bool
    let isHigh: Bool
}

struct DailyRadarCard: View {
    let points: [RadarDayPoint]
    @Binding var remindersEnabled: Bool

    private var activeDays: Int {
        points.filter { $0.isHigh }.count
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Shadow radar")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("A 7-day view of how active your shadow spikes have been.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }

                Spacer()

                Toggle(isOn: $remindersEnabled) {
                    Text("Daily ping")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .toggleStyle(SwitchToggleStyle(tint: .purple))
                .labelsHidden()
            }

            HStack(spacing: 10) {
                ForEach(points) { point in
                    VStack(spacing: 4) {
                        Circle()
                            .fill(
                                point.isHigh
                                ? AnyShapeStyle(
                                    LinearGradient(
                                        colors: [.purple, .blue],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                : AnyShapeStyle(Color.white.opacity(0.14))
                            )
                            .frame(width: point.isToday ? 14 : 10,
                                   height: point.isToday ? 14 : 10)
                            .overlay(
                                Circle()
                                    .stroke(
                                        point.isToday ? Color.white.opacity(0.9) : Color.clear,
                                        lineWidth: 1
                                    )
                            )

                        Text(point.label)
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText.opacity(point.isToday ? 1 : 0.75))
                    }
                }
            }
            .padding(.top, 4)

            Text(summaryText)
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
        }
        .shadowCard()
    }

    private var summaryText: String {
        guard !points.isEmpty else { return "No data yet." }
        if activeDays == 0 {
            return "No strong spikes in the last week. Stay curious and keep tracking."
        } else if activeDays <= 2 {
            return "Your shadow has flared a few times this week. Notice what those days had in common."
        } else {
            return "Your shadow has been active on \(activeDays) of the last 7 days. This is a rich window for gentle work."
        }
    }
}

// MARK: - Somatic Map

struct PatternCountItem: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct SomaticMapCard: View {
    let bodyCounts: [PatternCountItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Somatic map")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Where your triggers land in your body the most.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            if bodyCounts.isEmpty {
                Text("No somatic data yet.")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            } else {
                let top = bodyCounts.prefix(5)
                let maxCount = max(top.map(\.count).max() ?? 1, 1)

                VStack(spacing: 10) {
                    ForEach(top) { item in
                        SomaticRow(item: item, maxCount: maxCount)
                    }
                }
            }
        }
        .shadowCard()
    }
}

struct SomaticRow: View {
    let item: PatternCountItem
    let maxCount: Int

    private var intensityText: String {
        let ratio = Double(item.count) / Double(maxCount)
        switch ratio {
        case 0.75...: return "High"
        case 0.4...:  return "Medium"
        default:      return "Soft"
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(bodyEmoji(for: item.label))
                .font(.title3)

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(item.label.capitalized)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Spacer()

                    Text("\(item.count)x")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.08))

                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: max(
                                    CGFloat(item.count) / CGFloat(maxCount) * geo.size.width,
                                    8
                                )
                            )
                    }
                }
                .frame(height: 10)

                Text(intensityText)
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
        }
        .padding(.vertical, 4)
    }
}

private func bodyEmoji(for label: String) -> String {
    switch label.lowercased() {
    case "chest": return "💓"
    case "head": return "🧠"
    case "gut": return "🌀"
    case "throat": return "🗣️"
    case "limbs", "arms", "legs": return "🦵"
    case "wholebody", "whole_body", "whole body": return "🧍"
    case "numb": return "🧊"
    default: return "👤"
    }
}

// MARK: - Response Patterns

struct ResponsePatternsCard: View {
    let impulseCounts: [PatternCountItem]
    let somaticCounts: [PatternCountItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Response patterns")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("How your system tends to react and what it feels like.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            HStack(alignment: .top, spacing: 16) {
                // Impulses
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "figure.run")
                            .foregroundColor(.pink.opacity(0.9))
                        Text("Impulses")
                            .font(.subheadline.weight(.semibold))
                    }

                    if impulseCounts.isEmpty {
                        Text("No impulse data yet.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    } else {
                        ForEach(impulseCounts.prefix(3)) { item in
                            HStack {
                                Text(item.label)
                                    .foregroundColor(MSTheme.primaryText)
                                Spacer()
                                Text("\(item.count)x")
                                    .foregroundColor(MSTheme.secondaryText)
                                    .font(.caption)
                            }
                        }
                    }
                }

                // Sensations
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.blue.opacity(0.9))
                        Text("Sensations")
                            .font(.subheadline.weight(.semibold))
                    }

                    if somaticCounts.isEmpty {
                        Text("No sensation data yet.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    } else {
                        ForEach(somaticCounts.prefix(3)) { item in
                            HStack {
                                Text(item.label)
                                    .foregroundColor(MSTheme.primaryText)
                                Spacer()
                                Text("\(item.count)x")
                                    .foregroundColor(MSTheme.secondaryText)
                                    .font(.caption)
                            }
                        }
                    }
                }
            }
        }
        .shadowCard()
    }
}

// MARK: - Shadow Archetypes
// Archetype scoring and types are in ShadowArchetype.swift (ArchetypeEngine, ShadowArchetype, ArchetypeScore)
// MARK: - 6) Song Activation Analytics (summary card)

struct SongActivationAggregate: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let count: Int
    let averageIntensity: Double
    let maxIntensity: Int
}

struct SongActivationCard: View {
    let songs: [SongActivationAggregate]

    private var primary: SongActivationAggregate? { songs.first }
    private var secondary: SongActivationAggregate? {
        songs.count > 1 ? songs[1] : nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Song activation analytics")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Which songs consistently light up your system.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            if let primary {
                primaryTile(primary)
            }

            if let secondary {
                Divider()
                    .background(MSTheme.cardStroke)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Also very active")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text("\(secondary.title) — \(secondary.artist)")
                        .font(.footnote)
                        .foregroundColor(MSTheme.primaryText)

                    Text("\(secondary.count)x spikes · max \(secondary.maxIntensity)/10")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }
            }

            if songs.count > 2 {
                Text("+\(songs.count - 2) more songs showing up in your shadow.")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    .padding(.top, 4)
            }
        }
        .shadowCard()
    }

    private func primaryTile(_ song: SongActivationAggregate) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
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

                    Image(systemName: "music.quarternote.3")
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .semibold))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Most activated song")
                        .font(.caption2.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)

                    Text(song.title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Text(song.artist)
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }

                Spacer()
            }

            HStack(spacing: 10) {
                statPill(label: "Spikes", value: "\(song.count)x")
                statPill(
                    label: "Avg intensity",
                    value: String(format: "%.1f/10", song.averageIntensity)
                )
                statPill(label: "Max", value: "\(song.maxIntensity)/10")
            }
        }
        .padding(.top, 4)
    }

    private func statPill(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label.uppercased())
                .font(.caption2.weight(.semibold))
                .foregroundColor(.white.opacity(0.75))
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.08))
        )
    }
}
// MARK: - AI Themes Card

struct AIThemesCard: View {
    let insights: [ShadowInsight]

    private var woundCounts: [PatternCountItem] {
        aggregate(insights.compactMap { $0.wound_type })
    }

    private var protectorCounts: [PatternCountItem] {
        aggregate(insights.compactMap { $0.protector_mode })
    }

    private var beliefCounts: [PatternCountItem] {
        aggregate(insights.compactMap { $0.core_belief })
    }

    private var primaryWound: PatternCountItem? { woundCounts.first }
    private var primaryProtector: PatternCountItem? { protectorCounts.first }
    private var primaryBelief: PatternCountItem? { beliefCounts.first }

    private var latestInsight: ShadowInsight? {
        insights.first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("AI perspective")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("What your shadow work seems to be circling around, based on all AI reflections.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            if insights.isEmpty {
                Text("No AI insights yet. Log a few triggers to unlock this view.")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            } else {
                VStack(alignment: .leading, spacing: 10) {

                    if primaryWound != nil || primaryProtector != nil {
                        Text("Most active themes")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        HStack(spacing: 8) {
                            if let wound = primaryWound {
                                themePill(
                                    icon: "heart.text.square",
                                    label: "WOUND",
                                    value: wound.label
                                )
                            }

                            if let protector = primaryProtector {
                                themePill(
                                    icon: "shield.lefthalf.fill",
                                    label: "PROTECTOR",
                                    value: protector.label
                                )
                            }
                        }
                    }

                    if let belief = primaryBelief {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Repeating core belief")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MSTheme.primaryText)

                            Text("“\(belief.label)”")
                                .font(.footnote.italic())
                                .foregroundColor(MSTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.top, 4)
                    }
                }

                if let latest = latestInsight,
                   latest.summary != nil || latest.suggested_practice != nil {
                    Divider()
                        .background(MSTheme.cardStroke)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest reflection")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        if let summary = latest.summary, !summary.isEmpty {
                            Text(summary)
                                .font(.footnote)
                                .foregroundColor(MSTheme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if let practice = latest.suggested_practice, !practice.isEmpty {
                            HStack(alignment: .top, spacing: 6) {
                                Image(systemName: "brain.head.profile")
                                    .foregroundColor(.white.opacity(0.85))
                                    .font(.system(size: 20, weight: .semibold))

                                Text(practice)
                                    .font(.footnote)
                                    .foregroundColor(MSTheme.secondaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.top, 2)
                        }
                    }
                }
            }
        }
        .shadowCard()
    }

    private func themePill(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
            VStack(alignment: .leading, spacing: 2) {
                Text(label.uppercased())
                    .font(.caption2.weight(.semibold))
                Text(value)
                    .font(.caption)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(MSTheme.cardStroke, lineWidth: 0.8)
        )
        .foregroundColor(MSTheme.primaryText)
    }

    private func aggregate(_ items: [String]) -> [PatternCountItem] {
        Dictionary(grouping: items, by: { $0 })
            .map { key, value in PatternCountItem(label: key, count: value.count) }
            .sorted { $0.count > $1.count }
    }
}

// MARK: - Derived Data & Aggregations

extension PatternsView {

    // Basic aggregates
    var bodyLocationCounts: [PatternCountItem] {
        aggregateCounts(events.compactMap { $0.body_location })
    }

    var impulseCounts: [PatternCountItem] {
        aggregateCounts(events.compactMap { $0.impulse })
    }

    var somaticCounts: [PatternCountItem] {
        aggregateCounts(events.compactMap { $0.somatic_type })
    }

    private func aggregateCounts(_ items: [String]) -> [PatternCountItem] {
        Dictionary(grouping: items, by: { $0 })
            .map { key, value in PatternCountItem(label: key, count: value.count) }
            .sorted { $0.count > $1.count }
    }

    struct PatternIntensityPoint: Identifiable {
        let id = UUID()
        let date: Date
        let intensity: Int
    }

    var intensitySeries: [PatternIntensityPoint] {
        let formatter = ISO8601DateFormatter()
        return events.compactMap { event in
            guard
                let createdString = event.created_at,
                let date = formatter.date(from: createdString),
                let intensity = event.intensity
            else { return nil }

            return PatternIntensityPoint(date: date, intensity: intensity)
        }
        .sorted { $0.date < $1.date }
    }

    // Radar points – 7-day window
    var radarPoints: [RadarDayPoint] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        var buckets: [Date: [Int]] = [:]
        for point in intensitySeries {
            let day = calendar.startOfDay(for: point.date)
            buckets[day, default: []].append(point.intensity)
        }

        var result: [RadarDayPoint] = []

        for offset in (0..<7).reversed() {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: today) else { continue }
            let dayStart = calendar.startOfDay(for: day)
            let intensities = buckets[dayStart] ?? []
            let avg = intensities.isEmpty ? 0.0 : Double(intensities.reduce(0, +)) / Double(intensities.count)

            let labelFormatter = DateFormatter()
            labelFormatter.dateFormat = "E"
            let label = offset == 0 ? "Today" : labelFormatter.string(from: day)

            let isHigh = avg >= 7.0

            result.append(
                RadarDayPoint(
                    date: dayStart,
                    label: label,
                    averageIntensity: avg,
                    isToday: offset == 0,
                    isHigh: isHigh
                )
            )
        }

        return result
    }

    // Map SongAnalytics aggregates → compact home card aggregates
    var songActivationAggregates: [SongActivationAggregate] {
        let aggregated = aggregateSongs(from: events)
            .sorted { $0.count > $1.count }

        return aggregated.map { song in
            SongActivationAggregate(
                title: song.title,
                artist: song.artist,
                count: song.count,
                averageIntensity: song.averageIntensity,
                maxIntensity: song.maxIntensity
            )
        }
    }

}

// MARK: - Data Loading

extension PatternsView {
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
            DebugMode.shared.log("Error loading insights: \(error.localizedDescription)", category: "Error")
            await MainActor.run {
                // Don't clobber a more specific events error message if we already have one.
                if errorMessage == nil {
                    errorMessage = "We couldn't load your reflections. Patterns will use events only."
                }
            }
        }
    }
}
