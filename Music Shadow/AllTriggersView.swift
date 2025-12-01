import SwiftUI

struct AllTriggersView: View {
    let events: [SongEvent]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your logged triggers")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("Scroll through everything you’ve logged so far.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.bottom, 4)

                if events.isEmpty {
                    Text("No triggers logged yet.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 40)
                } else {
                    VStack(spacing: 10) {
                        ForEach(events) { event in
                            NavigationLink(
                                destination: TriggerDetailView(event: event)
                            ) {
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
        .navigationTitle("Triggers")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TriggerRow: View {
    let event: SongEvent

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(event.song_title ?? "Unknown song")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                if let artist = event.artist, !artist.isEmpty {
                    Text(artist)
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                }

                if let created = event.created_at {
                    Text(created)
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }
}
