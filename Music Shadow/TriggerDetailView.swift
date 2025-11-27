import SwiftUI
import Supabase

struct TriggerDetailView: View {
    let event: SongEvent

    @State private var insight: ShadowInsight? = nil
    @State private var isLoading: Bool = true
    @State private var errorMessage: String? = nil

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [
                    Color(red: 10/255, green: 10/255, blue: 25/255),
                    Color(red: 30/255, green: 12/255, blue: 60/255),
                    Color(red: 5/255, green: 5/255, blue: 20/255)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {

                    // HEADER CARD
                    VStack(alignment: .leading, spacing: 6) {
                        Text(event.song_title ?? "Unknown song")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        if let artist = event.artist {
                            Text(artist)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }

                        if let created = event.created_at {
                            Text(created)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                    .modifier(ShadowSection())

                    // AI INSIGHT TITLE
                    VStack(alignment: .leading, spacing: 6) {
                        Text("AI Emotional Insight")
                            .font(.title3.bold())
                            .foregroundColor(.white)

                        Text("An automated reflection based on your somatic and emotional patterns.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }

                    // AI LOADING / ERROR / CONTENT
                    if isLoading {
                        VStack(spacing: 8) {
                            ProgressView()
                                .tint(.white)
                            Text("Loading insight…")
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .modifier(ShadowSection())
                    }
                    else if let errorMessage = errorMessage {
                        VStack(alignment: .leading) {
                            Text("Error")
                                .font(.headline)
                                .foregroundColor(.white)

                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .modifier(ShadowSection())
                    }
                    else if let insight = insight {
                        VStack(alignment: .leading, spacing: 16) {

                            group("Wound Type", insight.wound_type)
                            group("Protector Mode", insight.protector_mode)
                            group("Age Range", insight.age_range)
                            group("Nervous System", insight.nervous_system)
                            group("Core Belief", insight.core_belief)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Summary")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(insight.summary ?? "—")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.top, 6)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Suggested Practice")
                                    .font(.headline)
                                    .foregroundColor(.white)

                                Text(insight.suggested_practice ?? "—")
                                    .font(.body)
                                    .foregroundColor(.white.opacity(0.85))
                            }
                            .padding(.top, 6)

                        }
                        .modifier(ShadowSection())
                    }
                    else {
                        VStack(alignment: .leading) {
                            Text("No AI insight available yet.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .modifier(ShadowSection())
                    }

                    Spacer(minLength: 40)
                }
                .padding(24)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .task { await loadInsight() }
    }

    // MARK: - Styled Group Component
    private func group(_ title: String, _ text: String?) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundColor(.white)

            Text(text ?? "—")
                .font(.body)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding(.vertical, 4)
    }

    // MARK: - Load Insight (unchanged)
    private func loadInsight() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let client = SupabaseClientManager.shared.client

            let response: PostgrestResponse<[ShadowInsight]> = try await client
                .from("shadow_insights")
                .select()
                .eq("event_id", value: event.id)
                .limit(1)
                .execute()

            let rows = response.value

            await MainActor.run {
                self.insight = rows.first
                self.isLoading = false
            }

        } catch {
            await MainActor.run {
                self.errorMessage = "Error loading insight: \(error.localizedDescription)"
                self.isLoading = false
            }
        }
    }
}

// MARK: - Shared Section Modifier (same as other screens)
struct ShadowSection: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.12), lineWidth: 1)
                    )
            )
    }
}
