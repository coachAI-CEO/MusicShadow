// Music Shadow/Views/ExportDataView.swift

import SwiftUI
import Supabase

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isExporting = false
    @State private var exportFormat: ExportFormat = .json
    @State private var includeInsights = true
    @State private var exportedURL: URL?
    @State private var showShareSheet = false
    @State private var errorMessage: String?

    enum ExportFormat: String, CaseIterable {
        case json = "JSON"
        case csv = "CSV"

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: MSTheme.Spacing.lg) {
                    // Header
                    VStack(spacing: MSTheme.Spacing.md) {
                        Image(systemName: "square.and.arrow.up.on.square.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [MSTheme.Colors.accentPrimary, MSTheme.Colors.accentSecondary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )

                        Text("Export Your Data")
                            .font(MSTheme.Typography.title2)
                            .fontWeight(.bold)
                            .foregroundColor(MSTheme.primaryText)

                        Text("Download all your activations and insights. Your data belongs to you.")
                            .font(MSTheme.Typography.body)
                            .foregroundColor(MSTheme.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, MSTheme.Spacing.lg)

                    // Format selection
                    VStack(alignment: .leading, spacing: MSTheme.Spacing.md) {
                        Text("Export Format")
                            .font(MSTheme.Typography.headline)
                            .foregroundColor(MSTheme.primaryText)

                        HStack(spacing: MSTheme.Spacing.md) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                FormatOptionButton(
                                    format: format,
                                    isSelected: exportFormat == format
                                ) {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        exportFormat = format
                                        HapticManager.trigger(.light)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, MSTheme.Spacing.md)
                    .padding(.vertical, MSTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .fill(MSTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )

                    // Options
                    VStack(alignment: .leading, spacing: MSTheme.Spacing.md) {
                        Text("Options")
                            .font(MSTheme.Typography.headline)
                            .foregroundColor(MSTheme.primaryText)

                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Include AI Insights")
                                    .font(MSTheme.Typography.body)
                                    .foregroundColor(MSTheme.primaryText)
                                Text("Export wound types, beliefs, and summaries")
                                    .font(MSTheme.Typography.caption)
                                    .foregroundColor(MSTheme.secondaryText)
                            }

                            Spacer()

                            Toggle("", isOn: $includeInsights)
                                .tint(MSTheme.Colors.accentPrimary)
                        }
                    }
                    .padding(.horizontal, MSTheme.Spacing.md)
                    .padding(.vertical, MSTheme.Spacing.md)
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .fill(MSTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )

                    // What's included
                    VStack(alignment: .leading, spacing: MSTheme.Spacing.sm) {
                        Text("What's Included")
                            .font(MSTheme.Typography.headline)
                            .foregroundColor(MSTheme.primaryText)

                        VStack(alignment: .leading, spacing: MSTheme.Spacing.sm) {
                            ExportIncludedItem(icon: "music.note", text: "All song activations")
                            ExportIncludedItem(icon: "figure.arms.open", text: "Body locations & sensations")
                            ExportIncludedItem(icon: "heart.text.square", text: "Journal entries")
                            ExportIncludedItem(icon: "calendar", text: "Timestamps & metadata")
                            if includeInsights {
                                ExportIncludedItem(icon: "brain", text: "AI-generated insights")
                            }
                        }
                    }
                    .padding(.horizontal, MSTheme.Spacing.md)
                    .padding(.vertical, MSTheme.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .fill(MSTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                            .stroke(MSTheme.cardStroke, lineWidth: 1)
                    )

                    // Error message
                    if let errorMessage = errorMessage {
                        HStack(spacing: MSTheme.Spacing.sm) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(MSTheme.Colors.error)
                            Text(errorMessage)
                                .font(MSTheme.Typography.caption)
                                .foregroundColor(MSTheme.Colors.error)
                        }
                        .padding(.horizontal, MSTheme.Spacing.md)
                        .padding(.vertical, MSTheme.Spacing.sm)
                        .background(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md)
                                .fill(MSTheme.Colors.error.opacity(0.1))
                        )
                    }

                    // Export button
                    Button {
                        Task { await exportData() }
                    } label: {
                        HStack(spacing: MSTheme.Spacing.sm) {
                            if isExporting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.9)
                            } else {
                                Image(systemName: "arrow.down.doc.fill")
                            }
                            Text(isExporting ? "Exporting..." : "Export Data")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, MSTheme.Spacing.md)
                        .background(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.lg)
                                .fill(
                                    LinearGradient(
                                        colors: [MSTheme.Colors.accentPrimary, MSTheme.Colors.accentSecondary],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        )
                        .foregroundColor(.white)
                    }
                    .disabled(isExporting)
                    .opacity(isExporting ? 0.7 : 1)

                    Spacer(minLength: MSTheme.Spacing.xl)
                }
                .padding(.horizontal, MSTheme.Spacing.md)
            }
            .musicShadowBackground()
            .navigationTitle("Export Data")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(MSTheme.Colors.accentPrimary)
                }
            }
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
        }
    }

    private func exportData() async {
        isExporting = true
        errorMessage = nil
        HapticManager.trigger(.light)

        do {
            let events: [SongEvent] = try await SupabaseClientManager.shared.client
                .from("song_events")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value

            var insights: [ShadowInsight] = []
            if includeInsights {
                insights = try await SupabaseClientManager.shared.client
                    .from("shadow_insights")
                    .select()
                    .execute()
                    .value
            }

            let fileURL: URL
            switch exportFormat {
            case .json:
                fileURL = try generateJSONExport(events: events, insights: insights)
            case .csv:
                fileURL = try generateCSVExport(events: events, insights: insights)
            }

            exportedURL = fileURL
            HapticManager.trigger(.success)
            showShareSheet = true

        } catch {
            errorMessage = "Export failed: \(error.localizedDescription)"
            HapticManager.trigger(.error)
        }

        isExporting = false
    }

    private func generateJSONExport(events: [SongEvent], insights: [ShadowInsight]) throws -> URL {
        let exportEvents: [ExportSongEvent] = events.map { e in
            ExportSongEvent(
                id: e.id,
                song_title: e.song_title,
                artist: e.artist,
                body_location: e.body_location,
                somatic_type: e.somatic_type,
                impulse: e.impulse,
                intensity: e.intensity,
                valence: e.valence,
                created_at: e.created_at,
                free_journal: e.free_journal
            )
        }

        let exportInsights: [ExportShadowInsight] = insights.map { i in
            ExportShadowInsight(
                event_id: i.event_id,
                wound_type: i.wound_type,
                protector_mode: i.protector_mode,
                core_belief: i.core_belief,
                summary: i.summary,
                suggested_practice: i.suggested_practice,
                created_at: i.created_at
            )
        }

        let exportData = ExportData(
            exportedAt: ISO8601DateFormatter().string(from: Date()),
            totalActivations: exportEvents.count,
            totalInsights: exportInsights.count,
            activations: exportEvents,
            insights: exportInsights
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(exportData)

        let fileName = "music_shadow_export_\(dateString()).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try data.write(to: url)

        return url
    }

    private func generateCSVExport(events: [SongEvent], insights: [ShadowInsight]) throws -> URL {
        var csvContent = "id,song_title,artist,body_location,somatic_type,impulse,intensity,valence,created_at,free_journal"

        if includeInsights {
            csvContent += ",wound_type,protector_mode,core_belief,summary"
        }
        csvContent += "\n"

        for event in events {
            let insight = insights.first { $0.event_id == event.id }

            var row = [
                event.id.uuidString,
                escapeCSV(event.song_title ?? ""),
                escapeCSV(event.artist ?? ""),
                escapeCSV(event.body_location ?? ""),
                escapeCSV(event.somatic_type ?? ""),
                escapeCSV(event.impulse ?? ""),
                String(event.intensity ?? 0),
                escapeCSV(event.valence ?? ""),
                escapeCSV(event.created_at ?? ""),
                escapeCSV(event.free_journal ?? "")
            ]

            if includeInsights {
                row.append(contentsOf: [
                    escapeCSV(insight?.wound_type ?? ""),
                    escapeCSV(insight?.protector_mode ?? ""),
                    escapeCSV(insight?.core_belief ?? ""),
                    escapeCSV(insight?.summary ?? "")
                ])
            }

            csvContent += row.joined(separator: ",") + "\n"
        }

        let fileName = "music_shadow_export_\(dateString()).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        try csvContent.write(to: url, atomically: true, encoding: .utf8)

        return url
    }

    private func escapeCSV(_ string: String) -> String {
        let escaped = string.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\n") || escaped.contains("\"") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private func dateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

struct ExportData: Encodable {
    let exportedAt: String
    let totalActivations: Int
    let totalInsights: Int
    let activations: [ExportSongEvent]
    let insights: [ExportShadowInsight]
}

struct ExportSongEvent: Encodable {
    let id: UUID
    let song_title: String?
    let artist: String?
    let body_location: String?
    let somatic_type: String?
    let impulse: String?
    let intensity: Int?
    let valence: String?
    let created_at: String?
    let free_journal: String?
}

struct ExportShadowInsight: Encodable {
    let event_id: UUID
    let wound_type: String?
    let protector_mode: String?
    let core_belief: String?
    let summary: String?
    let suggested_practice: String?
    let created_at: String?
}

struct FormatOptionButton: View {
    let format: ExportDataView.ExportFormat
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: MSTheme.Spacing.sm) {
                Image(systemName: format == .json ? "doc.text.fill" : "tablecells.fill")
                    .font(.system(size: 24))
                Text(format.rawValue)
                    .font(MSTheme.Typography.subheadline)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, MSTheme.Spacing.md)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md)
                    .fill(isSelected ? MSTheme.Colors.accentPrimary.opacity(0.2) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md)
                    .stroke(isSelected ? MSTheme.Colors.accentPrimary : MSTheme.cardStroke, lineWidth: isSelected ? 2 : 1)
            )
            .foregroundColor(isSelected ? MSTheme.Colors.accentPrimary : MSTheme.secondaryText)
        }
        .buttonStyle(.plain)
    }
}

struct ExportIncludedItem: View {
    let icon: String
    let text: String

    var body: some View {
        HStack(spacing: MSTheme.Spacing.sm) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(MSTheme.Colors.accentPrimary)
                .frame(width: 20)
            Text(text)
                .font(MSTheme.Typography.body)
                .foregroundColor(MSTheme.secondaryText)
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    ExportDataView()
}
