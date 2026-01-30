import SwiftUI
import Foundation
import Supabase

/// Read-only partner view for a shared trigger.
/// Displays content based on partner_share_level:
/// - MINIMAL: song/artist/date/valence/intensity/timestamp_sec + ai_reason + AI reflection summary
/// - FULL: adds somatic + selected journal fields (never free_journal unless explicitly included)
struct PartnerTriggerDetailView: View {
    let event: SongEvent
    
    // AI insight for this specific trigger (if present)
    @State private var insight: ShadowInsight?
    @State private var isLoadingInsight: Bool = true
    @State private var insightError: String?
    
    private var isMinimalShare: Bool {
        event.isPartnerShareLevelMinimal
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text(event.song_title ?? "Shared trigger")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text(event.artist ?? "")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    if let createdAt = event.created_at {
                        Text(formattedEventDate(createdAt))
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    }
                }
                
                // SONG INFO CARD (always shown)
                PartnerSongInfoCard(event: event)
                
                // SOMATIC CARD (only for FULL share level)
                if !isMinimalShare {
                    PartnerSomaticCard(event: event)
                }
                
                // AI REASON (event-level) - always shown
                if let reason = event.ai_reason, !reason.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Why this may have activated them")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)
                        
                        Text(reason)
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .shadowCard()
                }
                
                // AI INSIGHT CARD (read-only, no retry) - always shown
                PartnerAIInsightCard(
                    insight: insight,
                    isLoading: isLoadingInsight,
                    errorMessage: insightError
                )
                
                // SELECTED JOURNAL FIELDS (only for FULL share level)
                // Note: free_journal is never shown here per requirements
                if !isMinimalShare {
                    PartnerJournalCard(event: event)
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Shared trigger")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInsight()
        }
    }
    
    // MARK: - Load AI Insight
    
    private func loadInsight() async {
        await MainActor.run {
            isLoadingInsight = true
            insightError = nil
        }
        
        do {
            let client = SupabaseClientManager.shared.client
            
            guard client.auth.currentSession != nil else {
                await MainActor.run {
                    self.isLoadingInsight = false
                    self.insightError = "Please sign in to view this reflection."
                }
                return
            }
            
            // Load AI insight for this event (efficient single query)
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
                // Map technical errors to calm user-facing messages
                if let urlError = error as? URLError {
                    switch urlError.code {
                    case .notConnectedToInternet, .networkConnectionLost:
                        self.insightError = "Connection issue. Check your internet and try again when you're ready."
                    case .timedOut:
                        self.insightError = "This is taking longer than expected. You can try again in a moment."
                    default:
                        self.insightError = "We couldn't load the reflection just now. You can try again when you're ready."
                    }
                } else {
                    self.insightError = "We couldn't load the reflection just now. You can try again when you're ready."
                }
            }
        }
    }
    
    // MARK: - Date formatting
    
    private func formattedEventDate(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        if let date = iso.date(from: isoString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return isoString
        }
    }
}

// MARK: - Partner Card Views

private struct PartnerSongInfoCard: View {
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
            
            // Show timestamp_sec if available
            if let ts = event.timestamp_sec {
                Text("Spike around \(formattedTime(ts)) into the track")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
            
            // Show valence if available
            if let valence = event.valence, !valence.isEmpty {
                Text("Valence: \(valence.capitalized)")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
            
            // Show intensity if available
            if let intensity = event.intensity {
                Text("Intensity: \(intensity)/10")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
            
            if let sourceLine = sourceDescription(for: event) {
                HStack(spacing: 6) {
                    Image(systemName: "iphone.and.arrow.forward")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                    
                    Text(sourceLine)
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }
            }
        }
        .shadowCard()
    }
    
    private func sourceDescription(for event: SongEvent) -> String? {
        guard let rawType = event.source_type?.lowercased() else { return nil }
        
        var base: String
        switch rawType {
        case "manual":
            base = "Source: Manual log"
        case "spotify":
            base = "Source: Spotify (Now Playing)"
        case "apple_music":
            base = "Source: Apple Music"
        case "streaming":
            base = "Source: Streaming"
        default:
            return nil
        }
        
        if let context = event.source_context, !context.isEmpty {
            return base + " · " + context
        } else {
            return base
        }
    }
    
    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}

private struct PartnerSomaticCard: View {
    let event: SongEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Somatic snapshot")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)
            
            Text("Where it landed in their body, what it felt like, and what their body wanted to do.")
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

private struct PartnerJournalCard: View {
    let event: SongEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Journal")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)
            
            VStack(alignment: .leading, spacing: 8) {
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
                    title: "One thing you won't do next time",
                    text: event.interruption_directive
                )
            }
            
            // Note: free_journal is explicitly excluded per requirements
        }
        .shadowCard()
    }
    
    @ViewBuilder
    private func journalRow(title: String, text: String?) -> some View {
        if let text = text, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                
                Text(text)
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

private struct PartnerAIInsightCard: View {
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
                        .tint(MSTheme.secondaryText)
                    Text("Loading reflection…")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                }
            } else if let errorMessage {
                Text("We couldn't load the reflection this time.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let insight {
                if let summary = insight.summary, !summary.isEmpty {
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                    
                    // Show timestamp if available
                    if let createdAt = insight.created_at {
                        Text("Generated \(formattedTimestamp(createdAt))")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            .padding(.top, 4)
                    }
                } else {
                    Text("No reflection available for this trigger.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                }
            } else {
                Text("No reflection available for this trigger.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
            }
        }
        .shadowCard()
    }
    
    private func formattedTimestamp(_ isoString: String) -> String {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        guard let date = iso.date(from: isoString) else {
            return "recently"
        }
        
        let now = Date()
        let interval = now.timeIntervalSince(date)
        
        if interval < 60 {
            return "just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }
}
