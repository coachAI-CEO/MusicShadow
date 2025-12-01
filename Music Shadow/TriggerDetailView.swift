
import SwiftUI
import Supabase

struct TriggerDetailView: View {
    let event: SongEvent

    // AI insight for this specific trigger (if present)
    @State private var insight: ShadowInsight?
    @State private var isLoadingInsight: Bool = true
    @State private var insightError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.song_title ?? "Trigger detail")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text(event.artist ?? "")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)

                    if let ts = event.created_at {
                        Text(ts)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    }
                }

                // SONG INFO CARD
                SongInfoCard(event: event)

                // SOMATIC CARD
                SomaticDetailCard(event: event)

                // JOURNAL CARD
                JournalDetailCard(event: event)

                // AI INSIGHT CARD
                AIInsightDetailCard(
                    insight: insight,
                    isLoading: isLoadingInsight,
                    errorMessage: insightError
                )

                // ANALYTICS NAV
                NavigationLink {
                    // For now, we pass just this single event.
                    // Later we can enhance this to load *all* events for this song.
                    SongAnalyticsView(events: [event])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.subheadline)
                        Text("View analytics for this song")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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
                .padding(.top, 4)
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInsight()
        }
    }

    // MARK: - Supabase load for single-event insight

    private func loadInsight() async {
        do {
            let client = SupabaseClientManager.shared.client

            guard let session = client.auth.currentSession else {
                await MainActor.run {
                    self.isLoadingInsight = false
                    self.insightError = "No active session."
                }
                return
            }

            _ = session // just to silence unused warnings if needed

            let result: [ShadowInsight] = try await client
                .from("shadow_insights")
                .select()
                .eq("event_id", value: event.id)
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            await MainActor.run {
                self.insight = result.first
                self.isLoadingInsight = false
            }

        } catch {
            await MainActor.run {
                self.isLoadingInsight = false
                self.insightError = "Error loading insight: \(error.localizedDescription)"
            }
        }
    }
}

//
// MARK: – Sub-cards

private struct SongInfoCard: View {
    let event: SongEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Song")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            VStack(alignment: .leading, spacing: 4) {
                Text(event.song_title ?? "Unknown song")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                Text(event.artist ?? "Unknown artist")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }

            if let ts = event.timestamp_seconds {
                Text("Spike at \(formattedTime(ts))")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
        }
        .shadowCard()
    }

    // keep your existing helper here
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct SomaticDetailCard: View {
    let event: SongEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Somatic snapshot")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Where it landed in your body, what it felt like, and what your body wanted to do.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            VStack(alignment: .leading, spacing: 8) {
                if let body = event.body_location {
                    HStack {
                        Label(body.capitalized, systemImage: "figure.arms.open")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(MSTheme.primaryText)
                }

                if let sensation = event.somatic_type {
                    HStack {
                        Label(sensation.capitalized, systemImage: "waveform.path.ecg")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(MSTheme.primaryText)
                }

                if let imp = event.impulse {
                    HStack {
                        Label(imp.capitalized, systemImage: "figure.run")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(MSTheme.primaryText)
                }

                if let intensity = event.intensity {
                    HStack {
                        Label("Intensity \(intensity)/10", systemImage: "bolt.fill")
                            .font(.subheadline)
                        Spacer()
                    }
                    .foregroundColor(MSTheme.primaryText)
                }
            }
        }
        .shadowCard()
    }
}

private struct JournalDetailCard: View {
    let event: SongEvent

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Group {
                journalRow(
                    title: "What did your body do?",
                    text: event.body_report
                )
                journalRow(
                    title: "What did you want to do?",
                    text: event.impulse_report
                )
                journalRow(
                    title: "What stopped you?",
                    text: event.block_report
                )
                journalRow(
                    title: "This feeling reminds me of…",
                    text: event.echo_report
                )
                journalRow(
                    title: "Belief that showed up",
                    text: event.belief_report
                )
                journalRow(
                    title: "What you usually do",
                    text: event.pattern_report
                )
                journalRow(
                    title: "One thing you won’t do next time",
                    text: event.interruption_directive
                )
            }

            if let free = event.free_journal, !free.isEmpty {
                Divider()
                    .background(MSTheme.cardStroke)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Open reflection")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)

                    Text(free)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .shadowCard()
    }

    @ViewBuilder
    private func journalRow(title: String, text: String?) -> some View {
        if let txt = text, !txt.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                Text(txt)
                    .font(.footnote)
                    .foregroundColor(MSTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct AIInsightDetailCard: View {
    let insight: ShadowInsight?
    let isLoading: Bool
    let errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("AI reflection")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            if isLoading {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Generating / loading your reflection…")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }
            } else if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
            } else if let insight {
                if let summary = insight.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                if let practice = insight.suggested_practice, !practice.isEmpty {
                    HStack(alignment: .top, spacing: 6) {
                        Image(systemName: "sparkles")
                            .foregroundColor(.purple.opacity(0.9))
                            .font(.caption)

                        Text(practice)
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 4)
                }
            } else {
                Text("Once Gemini has processed this trigger, your AI reflection will show up here.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
            }
        }
        .shadowCard()
    }
}
