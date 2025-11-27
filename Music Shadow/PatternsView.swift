import SwiftUI
import Supabase
import Charts

struct PatternsView: View {
    @State private var events: [SongEvent] = []
    @State private var insights: [ShadowInsight] = []

    @State private var isLoading = true
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Header
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Patterns")
                            .font(.title.bold())
                            .foregroundColor(MSTheme.primaryText)

                        Text("See how your triggers cluster across body, impulses, and sensations.")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                    .padding(.top, 8)

                    // MARK: Loading / error states
                    if isLoading {
                        ProgressView("Loading your patterns…")
                            .foregroundColor(.white)
                            .padding(.top, 40)
                    } else if let errorMessage {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.caption)
                    } else {
                        // MARK: 1) Somatic map
                        if !events.isEmpty {
                            SomaticMapCard(bodyCounts: bodyLocationCounts)
                        }

                        // MARK: 2) Response patterns
                        if !events.isEmpty {
                            ImpulseSensationCard(
                                impulseCounts: impulseCounts,
                                somaticCounts: somaticCounts
                            )
                        }

                        // MARK: 3) Intensity over time
                        if !intensitySeries.isEmpty {
                            IntensityTimelineCard(points: intensitySeries)
                        }

                        // MARK: 4) AI themes snapshot
                        if !insights.isEmpty {
                            AIThemesCard(insights: insights)
                        }

                        // MARK: 5) Jump to full logs
                        if !events.isEmpty {
                            NavigationLink {
                                AllTriggersView(events: events)
                            } label: {
                                Text("Your logged triggers")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundColor(MSTheme.primaryText)
                                    .padding(.horizontal, 24)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                                            .fill(Color.white.opacity(0.04))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 24, style: .continuous)
                                                    .stroke(MSTheme.cardStroke, lineWidth: 1)
                                            )
                                    )
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
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
    }
}

//
// MARK: - 1) Somatic map
//

struct SomaticMapCard: View {
    let bodyCounts: [CountItem]

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
    let item: CountItem
    let maxCount: Int

    private var intensityLabel: String {
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

                Text(intensityLabel)
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

//
// MARK: - 2) Impulse + Sensation mix
//

struct ImpulseSensationCard: View {
    let impulseCounts: [CountItem]
    let somaticCounts: [CountItem]

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

//
// MARK: - 3) Intensity over time
//

struct IntensityTimelineCard: View {
    let points: [IntensityPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Shadow spikes over time")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("How intense your triggers have been recently.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            Chart(points) { point in
                LineMark(
                    x: .value("Date", point.date),
                    y: .value("Intensity", point.intensity)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(
                    LinearGradient(
                        colors: [.purple, .blue],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )

                PointMark(
                    x: .value("Date", point.date),
                    y: .value("Intensity", point.intensity)
                )
            }
            .frame(height: 180)

            if let last = points.last {
                Text("Last spike: \(last.intensity)/10")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }
        }
        .shadowCard()
    }
}

//
// MARK: - 4) AI themes snapshot
//

struct AIThemesCard: View {
    let insights: [ShadowInsight]

    private var woundCounts: [CountItem] {
        aggregate(insights.compactMap { $0.wound_type })
    }

    private var protectorCounts: [CountItem] {
        aggregate(insights.compactMap { $0.protector_mode })
    }

    private var beliefCounts: [CountItem] {
        aggregate(insights.compactMap { $0.core_belief })
    }

    private var primaryWound: CountItem? { woundCounts.first }
    private var primaryProtector: CountItem? { protectorCounts.first }
    private var primaryBelief: CountItem? { beliefCounts.first }

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
                                    label: "Wound",
                                    value: wound.label
                                )
                            }

                            if let protector = primaryProtector {
                                themePill(
                                    icon: "shield.lefthalf.fill",
                                    label: "Protector",
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
                                Image(systemName: "sparkles")
                                    .foregroundColor(.purple.opacity(0.9))
                                    .font(.caption)

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

    private func aggregate(_ items: [String]) -> [CountItem] {
        Dictionary(grouping: items, by: { $0 })
            .map { key, value in CountItem(label: key, count: value.count) }
            .sorted { $0.count > $1.count }
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
}

//
// MARK: - Trigger row + models
//

struct TriggerRow: View {
    let event: SongEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.song_title ?? "Unknown song")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                Text(event.artist ?? "")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)

                if let created = event.created_at {
                    Text(created)
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}

struct CountItem: Identifiable {
    let id = UUID()
    let label: String
    let count: Int
}

struct IntensityPoint: Identifiable {
    let id = UUID()
    let date: Date
    let intensity: Int
}

//
// MARK: - Aggregations
//

extension PatternsView {
    var bodyLocationCounts: [CountItem] {
        aggregate(events.compactMap { $0.body_location })
    }

    var impulseCounts: [CountItem] {
        aggregate(events.compactMap { $0.impulse })
    }

    var somaticCounts: [CountItem] {
        aggregate(events.compactMap { $0.somatic_type })
    }

    private func aggregate(_ items: [String]) -> [CountItem] {
        Dictionary(grouping: items, by: { $0 })
            .map { key, value in CountItem(label: key, count: value.count) }
            .sorted { $0.count > $1.count }
    }

    var intensitySeries: [IntensityPoint] {
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
}

//
// MARK: - Supabase loading
//

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
            print("Error loading insights: \(error)")
        }
    }
}
