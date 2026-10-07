import SwiftUI

/// What your linked partner chose to share with you. The database trims each row to the level they picked.
struct PartnerFeedView: View {
    var api: PartnerAPI = SupabasePartnerAPI()
    var partnerName: String?

    @State private var items: [PartnerFeedItem] = []
    @State private var isLoading = true
    @State private var errorMessage: String?

    private var who: String { (partnerName?.isEmpty == false) ? partnerName! : "Your partner" }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("\(who) shared")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)
                    Text("Only what they chose to share, and only the details they picked.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.bottom, 4)

                if isLoading {
                    ProgressView()
                        .tint(MSTheme.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if let errorMessage {
                    VStack(spacing: 10) {
                        Text(errorMessage).font(.caption).foregroundColor(MSTheme.Colors.error)
                        Button("Try again") { Task { await load() } }
                            .font(.caption.weight(.semibold))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
                } else if items.isEmpty {
                    Text("Nothing shared yet. When \(who.lowercased() == "your partner" ? "your partner" : who) shares an activation, it shows up here.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        .accessibilityIdentifier("partnerFeedEmpty")
                } else {
                    VStack(spacing: 12) {
                        ForEach(items) { item in
                            NavigationLink {
                                PartnerTriggerDetailView(item: item, partnerName: partnerName)
                            } label: {
                                PartnerFeedRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Shared with you")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable { await load() }
        .task { await load() }
    }

    private func load() async {
        isLoading = items.isEmpty
        errorMessage = nil
        do {
            items = try await api.feed(limit: 50, before: nil)
        } catch {
            DebugMode.shared.log("Partner feed load error: \(error.localizedDescription)", category: "Error")
            errorMessage = PartnerLinkError(error).message
        }
        isLoading = false
    }
}

private struct PartnerFeedRow: View {
    let item: PartnerFeedItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.isPositive ? "sparkles" : "waveform.path")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.Colors.accentPrimary)
                .frame(width: 34, height: 34)
                .background(Circle().fill(Color.white.opacity(0.08)))

            VStack(alignment: .leading, spacing: 4) {
                Text(item.song_title ?? "A song")
                    .font(.headline)
                    .foregroundColor(MSTheme.primaryText)
                if let artist = item.artist, !artist.isEmpty {
                    Text(artist).font(.subheadline).foregroundColor(MSTheme.secondaryText)
                }
                HStack(spacing: 8) {
                    if let date = item.date {
                        Text(PartnerDates.relative(date))
                    }
                    if let intensity = item.intensity {
                        Text("·")
                        Text("\(intensity)/10")
                    }
                }
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.85))
            }

            Spacer(minLength: 0)
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
        }
        .padding(16)
        .shadowCard()
        .accessibilityElement(children: .combine)
    }
}
