import SwiftUI

/// One activation your partner shared. It only ever shows what the database sent for their chosen level.
struct PartnerTriggerDetailView: View {
    let item: PartnerFeedItem
    var partnerName: String?

    private var labels: InsightLabels.Set { InsightLabels.labels(forValence: item.valence) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header

                if hasBodyDetails { bodyCard }
                if item.hasReflection { reflectionCard }

                if let journal = item.free_journal, !journal.isEmpty {
                    card(title: "In their own words") {
                        Text(journal)
                            .font(.callout)
                            .foregroundColor(MSTheme.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Text("Shared at the \(item.level.title) level. \(item.level.detail)")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Shared activation")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(item.song_title ?? "A song")
                .font(.title.bold())
                .foregroundColor(MSTheme.primaryText)
            if let artist = item.artist, !artist.isEmpty {
                Text(artist).font(.subheadline).foregroundColor(MSTheme.secondaryText)
            }
            VStack(alignment: .leading, spacing: 2) {
                if let date = item.date {
                    Text(date.formatted(date: .abbreviated, time: .shortened))
                }
                Text((item.intensity.map { "Strength \($0)/10 · " } ?? "") + (item.isPositive ? "A song that lifted them" : "A song that hit hard"))
            }
            .font(.caption)
            .foregroundColor(MSTheme.secondaryText.opacity(0.85))
        }
    }

    private var hasBodyDetails: Bool {
        [item.body_location, item.somatic_type, item.impulse, item.pattern_report].contains { !($0 ?? "").isEmpty }
    }

    private var bodyCard: some View {
        card(title: "In the body") {
            VStack(alignment: .leading, spacing: 8) {
                row("Where", item.body_location)
                row("Sensation", item.somatic_type)
                row("Urge", item.impulse)
                row("Pattern noticed", item.pattern_report)
            }
        }
    }

    private var reflectionCard: some View {
        card(title: "AI reflection") {
            VStack(alignment: .leading, spacing: 10) {
                if let archetype = item.archetype, !archetype.isEmpty {
                    row("Archetype", archetype)
                }
                row(labels.first, item.wound_type)
                row(labels.second, item.protector_mode)
                row(labels.third, item.core_belief)
                if let summary = item.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.callout)
                        .foregroundColor(MSTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    @ViewBuilder
    private func row(_ label: String, _ value: String?) -> some View {
        if let value, !value.isEmpty {
            VStack(alignment: .leading, spacing: 2) {
                Text(label).font(.caption.weight(.semibold)).foregroundColor(MSTheme.secondaryText)
                Text(value).font(.callout).foregroundColor(MSTheme.primaryText)
            }
        }
    }

    private func card<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline).foregroundColor(MSTheme.secondaryText)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .shadowCard()
    }
}
