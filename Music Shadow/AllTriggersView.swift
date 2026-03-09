import SwiftUI

struct AllTriggersView: View {
    let events: [SongEvent]
    @State private var searchText = ""

    var filteredEvents: [SongEvent] {
        if searchText.isEmpty {
            return events
        } else {
            return events.filter { event in
                let mirror = Mirror(reflecting: event)
                // Search across all string properties
                for child in mirror.children {
                    if let value = child.value as? String {
                        if value.localizedCaseInsensitiveContains(searchText) {
                            return true
                        }
                    }
                }
                // Also check explicit known fields for safety if reflection misses something or for priority
                let titleMatch = event.song_title?.localizedCaseInsensitiveContains(searchText) ?? false
                let artistMatch = event.artist?.localizedCaseInsensitiveContains(searchText) ?? false
                let journalMatch = event.free_journal?.localizedCaseInsensitiveContains(searchText) ?? false
                
                return titleMatch || artistMatch || journalMatch
            }
        }
    }

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
                
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(MSTheme.secondaryText)
                    TextField("Search songs, artists, journals...", text: $searchText)
                        .foregroundColor(MSTheme.primaryText)
                        .textFieldStyle(PlainTextFieldStyle())
                    
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(MSTheme.secondaryText)
                        }
                    }
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding(.bottom, 8)

                if filteredEvents.isEmpty {
                    Text(searchText.isEmpty ? "No triggers logged yet." : "No matches found for '\(searchText)'.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    VStack(spacing: 10) {
                        ForEach(filteredEvents) { event in
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
