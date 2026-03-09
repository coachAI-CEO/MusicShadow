import SwiftUI
import Supabase
import Auth

// MARK: - Quick Stats Ribbon

struct QuickStatsRibbon: View {
    let totalTriggers: Int
    let thisWeekCount: Int
    let primaryArchetype: String?
    let onTotalTap: () -> Void
    let onThisWeekTap: () -> Void
    let onArchetypeTap: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // Left Group (Total + This Week) - Takes ~50%
            HStack(spacing: 8) {
                // Total Card
                statCard(
                    icon: "music.note.list",
                    value: "\(totalTriggers)",
                    label: "Total",
                    action: onTotalTap
                )

                // This Week Card
                statCard(
                    icon: "calendar",
                    value: "\(thisWeekCount)",
                    label: "This Week",
                    action: onThisWeekTap
                )
            }
            .frame(maxWidth: .infinity)

            // Archetype Card (Right) - Takes ~50%
            statCard(
                icon: "person.circle",
                value: primaryArchetype ?? "None",
                label: "Primary",
                action: onArchetypeTap
            )
            .frame(maxWidth: .infinity)
        }
    }
    
    private func statCard(icon: String, value: String, label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(MSTheme.Colors.accentPrimary)
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(value)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(MSTheme.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(label)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(MSTheme.secondaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Featured Insight Card

struct FeaturedInsightCard: View {
    let insight: ShadowInsight
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "star.fill")
                        .font(.caption)
                        .foregroundColor(MSTheme.Colors.accentPrimary)
                    Text("Featured Insight")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }
                if let wound = insight.wound_type, !wound.isEmpty {
                    Text(wound)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)
                }
                if let summary = insight.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                HStack {
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                    .fill(MSTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Pattern Highlight

struct PatternHighlight: Identifiable {
    let id: UUID
    let title: String
    let subtitle: String?
    let count: Int

    static func generate(from events: [SongEvent], insights: [ShadowInsight]) -> [PatternHighlight] {
        var result: [PatternHighlight] = []
        let bodyCounts = Dictionary(grouping: events.compactMap { $0.body_location }, by: { $0 })
        let impulseCounts = Dictionary(grouping: events.compactMap { $0.impulse }, by: { $0 })
        let somaticCounts = Dictionary(grouping: events.compactMap { $0.somatic_type }, by: { $0 })

        if let topBody = bodyCounts.max(by: { $0.value.count < $1.value.count }) {
            result.append(PatternHighlight(
                id: UUID(),
                title: topBody.key.capitalized,
                subtitle: "Body",
                count: topBody.value.count
            ))
        }
        if let topImpulse = impulseCounts.max(by: { $0.value.count < $1.value.count }) {
            result.append(PatternHighlight(
                id: UUID(),
                title: topImpulse.key.capitalized,
                subtitle: "Impulse",
                count: topImpulse.value.count
            ))
        }
        if let topSomatic = somaticCounts.max(by: { $0.value.count < $1.value.count }) {
            result.append(PatternHighlight(
                id: UUID(),
                title: topSomatic.key.capitalized,
                subtitle: "Sensation",
                count: topSomatic.value.count
            ))
        }
        if result.isEmpty, !insights.isEmpty {
            result.append(PatternHighlight(
                id: UUID(),
                title: "Reflections are forming",
                subtitle: nil,
                count: insights.count
            ))
        }
        return result
    }
}

struct PatternHighlightCard: View {
    let highlight: PatternHighlight
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(highlight.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                if let sub = highlight.subtitle {
                    Text("\(sub) · \(highlight.count)x")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText)
                } else {
                    Text("\(highlight.count) reflection\(highlight.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Summary Card (This Week / Body hotspot)

struct SummaryCard: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(iconColor)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                .fill(MSTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                        .stroke(MSTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Actions Grid

struct QuickActionsGrid: View {
    let onBrowseTriggers: () -> Void
    let onSongAnalytics: () -> Void
    let onMyArchetypes: () -> Void
    let onTimeline: () -> Void

    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            quickAction(title: "Browse Triggers", icon: "music.note.list") { onBrowseTriggers() }
            quickAction(title: "Song Analytics", icon: "chart.bar") { onSongAnalytics() }
            quickAction(title: "My Archetypes", icon: "person.2.fill") { onMyArchetypes() }
            quickAction(title: "Timeline", icon: "calendar") { onTimeline() }
        }
    }

    private func quickAction(title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption)
                    .lineLimit(1)
            }
            .foregroundColor(MSTheme.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                    .fill(Color.white.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                            .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Recent Activity Section

struct RecentActivitySection: View {
    let events: [SongEvent]
    let maxItems: Int
    let onViewAll: () -> Void

    private var displayedEvents: [SongEvent] {
        Array(events.prefix(maxItems))
    }

    private func recentActivitySubtitle(for event: SongEvent) -> String {
        let artist = event.artist ?? ""
        let dateStr = event.created_at.flatMap { created in
            ISO8601DateFormatter().date(from: created).map {
                Self.relativeFormatter.localizedString(for: $0, relativeTo: Date())
            }
        } ?? ""
        return [artist, dateStr].filter { !$0.isEmpty }.joined(separator: " • ")
    }

    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Recent Activity")
                    .font(MSTheme.Typography.headline)
                    .foregroundColor(MSTheme.Colors.primaryText)
                Spacer()
                if events.count > maxItems {
                    Button(action: onViewAll) {
                        Text("View All")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MSTheme.Colors.accentPrimary)
                    }
                    .buttonStyle(.plain)
                }
            }

            if displayedEvents.isEmpty {
                Text("No activations yet. Log one to get started.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .padding(.vertical, 8)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(displayedEvents) { event in
                        HStack(spacing: 12) {
                            Image(systemName: "bolt.fill")
                                .font(.caption)
                                .foregroundColor(MSTheme.Colors.accentPrimary)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.song_title ?? "Unknown")
                                    .font(.subheadline.weight(.medium))
                                    .foregroundColor(MSTheme.primaryText)
                                    .lineLimit(1)
                                Text(recentActivitySubtitle(for: event))
                                    .font(.caption)
                                    .foregroundColor(MSTheme.secondaryText)
                                    .lineLimit(1)
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 2) {
                                if let intensity = event.intensity {
                                    Text("\(intensity)")
                                        .font(.caption2.weight(.semibold))
                                        .foregroundColor(MSTheme.primaryText)
                                        .frame(minWidth: 20, minHeight: 20)
                                        .background(Circle().fill(MSTheme.Colors.accentPrimary.opacity(0.3)))
                                }
                            }
                        }
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                                .fill(MSTheme.Colors.cardBackground)
                                .overlay(
                                    RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                                        .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                                )
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Pattern Stat Tile

struct PatternStatTile: View {
    let icon: String
    let title: String
    let value: String
    let count: String
    let intensity: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
            }
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
            Text(count)
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                )
        )
    }
}
