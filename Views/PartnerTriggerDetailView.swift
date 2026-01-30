import SwiftUI

/// Partner-safe detail view for a single shared trigger.
/// Shows only somatic + AI summary fields (no journal text or free writing).
struct PartnerTriggerDetailView: View {
    let event: SongEvent
    let insight: ShadowInsight?

    private var formattedDate: String? {
        guard let created = event.created_at else { return nil }
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = iso.date(from: created) else { return nil }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df.string(from: date)
    }

    private var intensityLine: String? {
        guard let intensity = event.intensity else { return nil }
        if let label = event.intensity_label, !label.isEmpty {
            return "Intensity \(intensity)/10 – \(label)"
        } else {
            return "Intensity \(intensity)/10"
        }
    }

    private var somaticLine: String? {
        let parts = [
            event.body_location?.capitalized,
            event.somatic_type?.capitalized,
            event.impulse?.capitalized
        ].compactMap { $0 }.filter { !$0.isEmpty }

        guard !parts.isEmpty else { return nil }
        return parts.joined(separator: " · ")
    }

    private var aiLine: String {
        if let reason = event.ai_reason, !reason.isEmpty {
            return reason
        }
        if let summary = insight?.summary, !summary.isEmpty {
            return summary
        }
        return "No short reflection has been added for this moment yet."
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.song_title ?? "Shared activation")
                        .font(.title3.bold())
                        .foregroundColor(MSTheme.primaryText)

                    if let artist = event.artist, !artist.isEmpty {
                        Text(artist)
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    if let date = formattedDate {
                        Text(date)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    }
                }

                // Somatic snapshot (gentle mode)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Somatic snapshot")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    if let intensityLine {
                        Text(intensityLine)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    if let somaticLine {
                        Text(somaticLine)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                }
                .shadowCard()

                // AI reflection (short)
                VStack(alignment: .leading, spacing: 8) {
                    Text("AI reflection (short)")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text(aiLine)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                // Gentle guidance copy
                VStack(alignment: .leading, spacing: 8) {
                    Text("Why this view is gentle")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("This page shows only the intensity, somatic snapshot, and a short AI reflection. The full journal and free writing always stay on your partner’s side unless they explicitly choose to share more.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.95))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}


