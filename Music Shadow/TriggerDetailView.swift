import SwiftUI
import Supabase

struct TriggerDetailView: View {
    let event: SongEvent

    @State private var insight: ShadowInsight?
    @State private var isLoadingInsight = true
    @State private var insightError: String?
    @State private var isRegenerating = false
    @State private var shareWithPartner: Bool
    @State private var isSavingShare = false
    @State private var journalExpanded = false
    @State private var relatedEvents: [SongEvent] = []

    init(event: SongEvent) {
        self.event = event
        _shareWithPartner = State(initialValue: event.share_with_partner ?? false)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // MARK: Header
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.song_title ?? "Trigger detail")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)
                    Text(event.artist ?? "")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                    if let ts = event.created_at {
                        Text(formattedDate(ts))
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    }
                }

                // MARK: Song card
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Label {
                            Text("Song")
                                .font(.headline)
                        } icon: {}
                        .foregroundColor(MSTheme.secondaryText)

                        Text(event.song_title ?? "Unknown song")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)
                        Text(event.artist ?? "Unknown artist")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)

                        if let ts = event.timestamp_seconds, ts > 0 {
                            Text("Spike around \(formattedTime(ts)) into the track")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.85))
                        }

                        HStack(spacing: 6) {
                            Image(systemName: "square.and.pencil")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            Text("Source: \(event.source_type?.capitalized ?? "Manual log")")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                        }
                    }
                }

                // MARK: Somatic snapshot
                DetailCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Somatic snapshot")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)
                        Text("Where it landed in your body, what it felt like, and what your body wanted to do.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.85))
                            .fixedSize(horizontal: false, vertical: true)

                        VStack(alignment: .leading, spacing: 8) {
                            if let body = event.body_location {
                                Label(body.capitalized, systemImage: "figure.walk")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                            }
                            if let sensation = event.somatic_type {
                                Label(sensation.replacingOccurrences(of: "_", with: " ").capitalized,
                                      systemImage: "waveform.path.ecg")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                            }
                            if let imp = event.impulse {
                                Label(imp.replacingOccurrences(of: "_", with: " ").capitalized,
                                      systemImage: "figure.run")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                            }
                            if let intensity = event.intensity {
                                Label("Intensity \(intensity)/10", systemImage: "bolt.fill")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.primaryText)
                            }
                        }
                    }
                }

                // MARK: Journal (collapsible)
                VStack(alignment: .leading, spacing: 0) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            journalExpanded.toggle()
                        }
                        HapticManager.trigger(.light)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "book.closed")
                                .font(.subheadline)
                            Text("Journal")
                                .font(.subheadline.weight(.semibold))
                            Spacer()
                            Image(systemName: journalExpanded ? "chevron.up" : "chevron.down")
                                .font(.caption.weight(.semibold))
                        }
                        .foregroundColor(MSTheme.primaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 14)
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

                    if journalExpanded {
                        DetailCard {
                            VStack(alignment: .leading, spacing: 12) {
                                journalRow("What did your body do?", text: event.body_report)
                                journalRow("What did you want to do?", text: event.impulse_report)
                                journalRow("What got in the way?", text: event.block_report)
                                journalRow("This feeling reminds you of…", text: event.echo_report)
                                journalRow("Belief that showed up", text: event.belief_report)
                                journalRow("What you usually do in moments like this", text: event.pattern_report)
                                journalRow("One small thing you'll try differently next time", text: event.interruption_directive)
                                if let free = event.free_journal, !free.isEmpty {
                                    Divider().background(MSTheme.cardStroke)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Open reflection")
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(MSTheme.secondaryText)
                                        Text(free)
                                            .font(.footnote)
                                            .foregroundColor(MSTheme.primaryText)
                                            .fixedSize(horizontal: false, vertical: true)
                                    }
                                }
                            }
                        }
                        .padding(.top, 8)
                    }
                }

                // MARK: Share with partner
                DetailCard {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Share with partner")
                                .font(.headline)
                                .foregroundColor(MSTheme.primaryText)
                            Spacer()
                            Toggle("", isOn: $shareWithPartner)
                                .labelsHidden()
                                .tint(MSTheme.Colors.accentPrimary)
                                .disabled(isSavingShare)
                                .onChange(of: shareWithPartner) { newValue in
                                    Task { await updateShareWithPartner(newValue) }
                                }
                        }
                        Text("When enabled, this activation appears in your partner summary view.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Shared activations appear in your partner's daily summary.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                // MARK: Regenerate AI reflection
                Button {
                    Task { await regenerateInsight() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: isRegenerating ? "circle.dotted" : "arrow.triangle.2.circlepath")
                            .font(.subheadline)
                            .symbolEffect(.rotate, isActive: isRegenerating)
                        Text(isRegenerating ? "Generating…" : "Regenerate AI reflection")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                            .fill(MSTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                                    .stroke(MSTheme.cardStroke, lineWidth: 1)
                            )
                    )
                    .foregroundColor(MSTheme.primaryText)
                }
                .buttonStyle(.plain)
                .disabled(isRegenerating)

                // MARK: AI reflection
                if isLoadingInsight {
                    DetailCard {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text("Loading reflection…")
                                .font(.footnote)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                    }
                } else if let insight {
                    DetailCard {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("AI reflection")
                                .font(.headline)
                                .foregroundColor(MSTheme.secondaryText)

                            if let summary = insight.summary, !summary.isEmpty {
                                Text(summary)
                                    .font(.footnote)
                                    .foregroundColor(MSTheme.primaryText)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            // Key themes chips
                            let themes = keyThemes(from: insight)
                            if !themes.isEmpty {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Key themes")
                                        .font(.caption.weight(.semibold))
                                        .foregroundColor(MSTheme.secondaryText)
                                    FlowLayout(spacing: 8) {
                                        ForEach(themes, id: \.self) { theme in
                                            Text(theme)
                                                .font(.caption2.weight(.medium))
                                                .foregroundColor(MSTheme.primaryText)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                        .fill(Color.white.opacity(0.1))
                                                        .overlay(
                                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                                .stroke(MSTheme.cardStroke, lineWidth: 1)
                                                        )
                                                )
                                        }
                                    }
                                }
                            }

                            if let createdAt = insight.created_at {
                                Text("Generated \(relativeDate(createdAt))")
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.6))
                            }
                        }
                    }
                } else if !isLoadingInsight {
                    DetailCard {
                        Text("No reflection yet. Tap \"Regenerate AI reflection\" to generate one.")
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                }

                // MARK: Related Patterns
                if !relatedEvents.isEmpty {
                    DetailCard {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "link")
                                    .font(.subheadline)
                                    .foregroundColor(MSTheme.Colors.accentPrimary)
                                Text("Related Patterns")
                                    .font(.headline)
                                    .foregroundColor(MSTheme.primaryText)
                            }
                            Text("Other activations with similar patterns or themes.")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)

                            VStack(spacing: 0) {
                                ForEach(relatedEvents) { related in
                                    NavigationLink {
                                        TriggerDetailView(event: related)
                                    } label: {
                                        HStack(spacing: 12) {
                                            VStack(alignment: .leading, spacing: 3) {
                                                Text(related.song_title ?? "Unknown")
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(MSTheme.primaryText)
                                                    .lineLimit(1)
                                                HStack(spacing: 4) {
                                                    Text(related.artist ?? "")
                                                        .font(.caption)
                                                        .foregroundColor(MSTheme.secondaryText)
                                                    if let date = related.created_at {
                                                        Text("·")
                                                            .foregroundColor(MSTheme.secondaryText.opacity(0.5))
                                                        Text(shortDate(date))
                                                            .font(.caption)
                                                            .foregroundColor(MSTheme.secondaryText)
                                                    }
                                                }
                                            }
                                            Spacer()
                                            VStack(alignment: .trailing, spacing: 2) {
                                                if let intensity = related.intensity {
                                                    HStack(spacing: 3) {
                                                        Image(systemName: "bolt.fill")
                                                            .font(.caption2)
                                                        Text("\(intensity)/10")
                                                            .font(.caption2.weight(.semibold))
                                                    }
                                                    .foregroundColor(MSTheme.Colors.accentPrimary.opacity(0.9))
                                                }
                                                if let body = related.body_location {
                                                    Text(body.capitalized)
                                                        .font(.caption2)
                                                        .foregroundColor(MSTheme.secondaryText)
                                                }
                                            }
                                            Image(systemName: "chevron.right")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(MSTheme.secondaryText.opacity(0.5))
                                        }
                                        .padding(.vertical, 10)
                                    }
                                    .buttonStyle(.plain)

                                    if related.id != relatedEvents.last?.id {
                                        Divider().background(MSTheme.cardStroke)
                                    }
                                }
                            }
                        }
                    }
                }

                // MARK: View analytics button
                NavigationLink {
                    SongAnalyticsView(events: [event])
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "chart.bar.doc.horizontal.fill")
                            .font(.subheadline)
                        Text("View analytics for this song")
                            .font(.subheadline.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                            .fill(MSTheme.Colors.cardBackground)
                            .overlay(
                                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                                    .stroke(MSTheme.cardStroke, lineWidth: 1)
                            )
                    )
                    .foregroundColor(MSTheme.primaryText)
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadInsight()
            await loadRelatedEvents()
        }
    }

    // MARK: - Helpers

    @ViewBuilder
    private func journalRow(_ title: String, text: String?) -> some View {
        if let txt = text, !txt.isEmpty {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
                Text(txt)
                    .font(.footnote)
                    .foregroundColor(MSTheme.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func keyThemes(from insight: ShadowInsight) -> [String] {
        var themes: [String] = []
        if let w = insight.wound_type, !w.isEmpty { themes.append("Wound: \(w)") }
        if let p = insight.protector_mode, !p.isEmpty { themes.append("Protector: \(p)") }
        if let b = insight.core_belief, !b.isEmpty { themes.append("Belief: \(b)") }
        return themes
    }

    private func formattedDate(_ isoString: String) -> String {
        let parsers: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
        ]
        for parser in parsers {
            if let date = parser.date(from: isoString) {
                let fmt = DateFormatter()
                fmt.dateFormat = "MMM d, yyyy 'at' h:mm a"
                return fmt.string(from: date)
            }
        }
        return isoString
    }

    private func shortDate(_ isoString: String) -> String {
        let parsers: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
        ]
        for parser in parsers {
            if let date = parser.date(from: isoString) {
                let fmt = DateFormatter()
                fmt.dateFormat = "MMM d, yyyy"
                return fmt.string(from: date)
            }
        }
        return isoString
    }

    private func relativeDate(_ isoString: String) -> String {
        let parsers: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }()
        ]
        for parser in parsers {
            if let date = parser.date(from: isoString) {
                let rel = RelativeDateTimeFormatter()
                rel.unitsStyle = .full
                return rel.localizedString(for: date, relativeTo: Date())
            }
        }
        return ""
    }

    private func formattedTime(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }

    // MARK: - Data loading

    private func loadInsight() async {
        do {
            let result: [ShadowInsight] = try await SupabaseClientManager.shared.client
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
                self.insightError = error.localizedDescription
                self.isLoadingInsight = false
            }
        }
    }

    private func loadRelatedEvents() async {
        guard let bodyLocation = event.body_location else { return }
        do {
            let userId = SupabaseClientManager.shared.client.auth.currentSession?.user.id
            guard let userId else { return }
            let result: [SongEvent] = try await SupabaseClientManager.shared.client
                .from("song_events")
                .select()
                .eq("user_id", value: userId.uuidString)
                .eq("body_location", value: bodyLocation)
                .neq("id", value: event.id.uuidString)
                .order("created_at", ascending: false)
                .limit(5)
                .execute()
                .value
            await MainActor.run { self.relatedEvents = result }
        } catch { }
    }

    private func updateShareWithPartner(_ value: Bool) async {
        isSavingShare = true
        do {
            try await SupabaseClientManager.shared.client
                .from("song_events")
                .update(["share_with_partner": value])
                .eq("id", value: event.id.uuidString)
                .execute()
            HapticManager.trigger(.light)
        } catch { }
        isSavingShare = false
    }

    private func regenerateInsight() async {
        guard !isRegenerating else { return }
        isRegenerating = true
        isLoadingInsight = true
        insight = nil

        do {
            // Delete existing insight first
            try await SupabaseClientManager.shared.client
                .from("shadow_insights")
                .delete()
                .eq("event_id", value: event.id.uuidString)
                .execute()

            guard let session = try? await SupabaseClientManager.shared.client.auth.session else {
                isRegenerating = false
                isLoadingInsight = false
                return
            }

            struct InsightPayload: Encodable {
                let event_id: UUID
                let song_title: String?
                let artist: String?
                let lyrics_snippet: String?
                let timestamp_seconds: Int?
            }

            let url = SupabaseClientManager.shared.edgeFunctionURL("generate_insight")
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
            request.setValue(SupabaseClientManager.shared.supabaseKey, forHTTPHeaderField: "apikey")
            request.httpBody = try JSONEncoder().encode(InsightPayload(
                event_id: event.id,
                song_title: event.song_title,
                artist: event.artist,
                lyrics_snippet: nil,
                timestamp_seconds: event.timestamp_seconds
            ))
            _ = try await URLSession.shared.data(for: request)

            // Poll for result (up to 60s)
            for _ in 0..<12 {
                try await Task.sleep(nanoseconds: 5_000_000_000)
                if Task.isCancelled { return }
                let result: [ShadowInsight] = try await SupabaseClientManager.shared.client
                    .from("shadow_insights")
                    .select()
                    .eq("event_id", value: event.id)
                    .limit(1)
                    .execute()
                    .value
                if let found = result.first {
                    await MainActor.run {
                        self.insight = found
                        self.isLoadingInsight = false
                        self.isRegenerating = false
                        HapticManager.trigger(.success)
                    }
                    return
                }
            }
        } catch {
            await MainActor.run {
                self.insightError = "Couldn't refresh the reflection. Try again in a moment."
            }
        }

        await MainActor.run {
            self.isLoadingInsight = false
            self.isRegenerating = false
        }
    }
}

// MARK: - Detail Card container

private struct DetailCard<Content: View>: View {
    let content: () -> Content
    init(@ViewBuilder content: @escaping () -> Content) { self.content = content }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content() }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                    .fill(MSTheme.Colors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg, style: .continuous)
                    .stroke(MSTheme.cardStroke, lineWidth: 1)
            )
    }
}

// MARK: - Flow layout for chips

private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var height: CGFloat = 0
        var rowX: CGFloat = 0
        var rowH: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > width, rowX > 0 {
                height += rowH + spacing
                rowX = 0
                rowH = 0
            }
            rowX += size.width + spacing
            rowH = max(rowH, size.height)
        }
        height += rowH
        return CGSize(width: width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var rowX: CGFloat = bounds.minX
        var rowY: CGFloat = bounds.minY
        var rowH: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if rowX + size.width > bounds.maxX, rowX > bounds.minX {
                rowY += rowH + spacing
                rowX = bounds.minX
                rowH = 0
            }
            subview.place(at: CGPoint(x: rowX, y: rowY), proposal: ProposedViewSize(size))
            rowX += size.width + spacing
            rowH = max(rowH, size.height)
        }
    }
}
