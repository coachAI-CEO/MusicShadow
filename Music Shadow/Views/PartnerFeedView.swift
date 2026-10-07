import SwiftUI
import Supabase

struct PartnerFeedView: View {
    @State private var partnerEvents: [SongEvent] = []
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Partner Feed")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("Triggers your partner has shared with you.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.bottom, 4)

                if isLoading {
                    ProgressView()
                        .tint(MSTheme.secondaryText)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                } else if let errorMessage {
                    VStack(spacing: 10) {
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                        Button("Retry", action: {
                            Task { await loadPartnerEvents() }
                        })
                        .font(.caption.weight(.semibold))
                    }
                    .padding(.top, 40)
                    .frame(maxWidth: .infinity, alignment: .center)
                } else if partnerEvents.isEmpty {
                    Text("No shared triggers yet.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 12) {
                        ForEach(partnerEvents) { event in
                            NavigationLink(destination: PartnerTriggerDetailView(event: event)) {
                                TriggerRow(event: event)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Partner Feed")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await loadPartnerEvents() }
        .task { await loadPartnerEvents() }
    }

    private func loadPartnerEvents() async {
        let client = SupabaseClientManager.shared.client
        guard let _ = try? await client.auth.session else {
            await MainActor.run {
                errorMessage = "Not signed in."
                isLoading = false
            }
            return
        }

        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            let result: [SongEvent] = try await client
                .from("song_events")
                .select()
                .eq("share_with_partner", value: true)
                .order("created_at", ascending: false)
                .limit(50)
                .execute()
                .value

            await MainActor.run {
                partnerEvents = result
                isLoading = false
            }
        } catch {
            DebugMode.shared.log("PartnerFeed load error: \(error.localizedDescription)", category: "Error")
            await MainActor.run {
                errorMessage = "Couldn't load partner feed."
                isLoading = false
            }
        }
    }
}
