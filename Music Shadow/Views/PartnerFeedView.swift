import SwiftUI

struct PartnerFeedView: View {
    @State private var partnerEvents: [SongEvent] = []
    @State private var isLoading: Bool = true
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
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
                                TriggerRow(event: event) // Re-using TriggerRow for consistent look
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
        .task {
            // Simulate loading or fetch from Supabase
            // In reality, this would query song_events where user_id == partner_id AND share_with_partner == true
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            isLoading = false
            // Empty for now as we don't have partner ID logic hooked up yet
        }
    }
}
