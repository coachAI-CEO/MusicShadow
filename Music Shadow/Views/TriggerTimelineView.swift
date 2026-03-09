import SwiftUI

struct TriggerTimelineView: View {
    let events: [SongEvent]
    
    // Group events by month/year
    private var groupedEvents: [(String, [SongEvent])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        // Safety: handle missing dates by putting them at the end
        let sorted = events.sorted {
            ($0.created_at ?? "") > ($1.created_at ?? "")
        }
        
        let grouped = Dictionary(grouping: sorted) { event -> String in
            guard let created = event.created_at,
                  let date = ISO8601DateFormatter().date(from: created) else {
                return "Unknown Date"
            }
            return formatter.string(from: date)
        }
        
        // Sort keys (months) descending
        return grouped.sorted { (pair1, pair2) in
            // Quick heuristic: compare first event of each group
            let date1 = pair1.value.first?.created_at ?? ""
            let date2 = pair2.value.first?.created_at ?? ""
            return date1 > date2
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Timeline")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("Your journey over time.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                
                // TIMELINE CONTENT
                if events.isEmpty {
                    Text("No activations logged yet.")
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 40)
                        .frame(maxWidth: .infinity, alignment: .center)
                } else {
                    LazyVStack(spacing: 32) {
                        ForEach(groupedEvents, id: \.0) { (month, monthEvents) in
                            VStack(alignment: .leading, spacing: 16) {
                                // Month Header
                                Text(month.uppercased())
                                    .font(.caption.weight(.bold))
                                    .foregroundColor(MSTheme.Colors.accentPrimary)
                                    .padding(.leading, 4)
                                
                                ForEach(monthEvents) { event in
                                    NavigationLink(destination: TriggerDetailView(event: event)) {
                                        TimelineRow(event: event)
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Timeline")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// A distinct row style for the Timeline
struct TimelineRow: View {
    let event: SongEvent
    
    private var eventDay: String {
        guard let created = event.created_at,
              let date = ISO8601DateFormatter().date(from: created) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "d"
        return f.string(from: date)
    }
    
    private var eventMonthShort: String {
        guard let created = event.created_at,
              let date = ISO8601DateFormatter().date(from: created) else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM"
        return f.string(from: date)
    }

    var body: some View {
        HStack(spacing: 16) {
            // Date Bubble
            VStack(spacing: 0) {
                Text(eventMonthShort.uppercased())
                    .font(.caption2.bold())
                    .foregroundColor(MSTheme.secondaryText)
                Text(eventDay)
                    .font(.title3.bold())
                    .foregroundColor(MSTheme.primaryText)
            }
            .frame(width: 44)
            .padding(.vertical, 8)
            .background(Color.white.opacity(0.04))
            .cornerRadius(12)
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(event.song_title ?? "Unknown Song")
                    .font(.body.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)
                
                Text(event.artist ?? "Unknown Artist")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                
                if let bodyPart = event.body_location {
                    HStack(spacing: 4) {
                        Image(systemName: "figure.arms.open")
                            .font(.caption2)
                        Text(bodyPart.capitalized)
                            .font(.caption2)
                    }
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                    .padding(.top, 2)
                }
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(MSTheme.secondaryText.opacity(0.5))
                .font(.caption)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(MSTheme.Colors.cardBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MSTheme.cardStroke, lineWidth: 1)
                )
        )
    }
}
