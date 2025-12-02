import SwiftUI

// MARK: - Aggregated Models

struct SongAggregate: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let count: Int
    let averageIntensity: Double
    let maxIntensity: Int
    let lastTriggeredAt: Date?
}

struct ArtistAggregate: Identifiable {
    let id = UUID()
    let artist: String
    let totalTriggers: Int
    let averageIntensity: Double
}

private struct SongKey: Hashable {
    let title: String
    let artist: String
}

// Simple “bucket” models for the dashboard

struct QuickStats {
    let totalTriggers: Int
    let uniqueSongs: Int
    let uniqueArtists: Int
    let averageIntensity: Double
}

struct IntensityBucket: Identifiable {
    let id = UUID()
    let label: String
    let range: ClosedRange<Int>
    let count: Int
}

struct TimeOfDayBucket: Identifiable {
    let id = UUID()
    let label: String
    let icon: String
    let count: Int
}

// MARK: - Main Dashboard View

struct SongAnalyticsView: View {
    let events: [SongEvent]

    // MARK: Aggregated data

    private var songAggregates: [SongAggregate] {
        aggregateSongs(from: events).sorted { $0.count > $1.count }
    }

    private var artistAggregates: [ArtistAggregate] {
        aggregateArtists(from: songAggregates).sorted { $0.totalTriggers > $1.totalTriggers }
    }

    private var stats: QuickStats {
        makeQuickStats(from: events)
    }

    private var intensityBuckets: [IntensityBucket] {
        makeIntensityBuckets(from: events)
    }

    private var timeOfDayBuckets: [TimeOfDayBucket] {
        makeTimeOfDayBuckets(from: events)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    Text("Song Activation Analytics")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("See how the music you feel most shapes your patterns.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                .padding(.top, 12)

                if events.isEmpty {
                    Text("No triggers logged yet. Once you start logging, you’ll see which songs and artists light up your system.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .shadowCard()
                    Spacer()
                } else {

                    // 1) Quick stats
                    QuickStatsCard(stats: stats)

                    // 2) Intensity distribution
                    IntensityDistributionCard(buckets: intensityBuckets)

                    // 3) Time-of-day pattern
                    TimeOfDayCard(buckets: timeOfDayBuckets)

                    // 4) Top songs
                    if !songAggregates.isEmpty {
                        TopSongsCard(items: songAggregates)
                    }

                    // 5) Top artists
                    if !artistAggregates.isEmpty {
                        TopArtistsCard(items: artistAggregates)
                    }
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Cards

// 1) Quick stats

private struct QuickStatsCard: View {
    let stats: QuickStats

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("High-level snapshot of how often your shadow gets activated through music.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            // 2×2 grid so labels don’t get chopped
            VStack(spacing: 10) {
                HStack(spacing: 12) {
                    StatTile(
                        icon: "bolt.heart",
                        title: "Triggers",
                        value: "\(stats.totalTriggers)"
                    )
                    StatTile(
                        icon: "music.note.list",
                        title: "Songs",
                        value: "\(stats.uniqueSongs)"
                    )
                }

                HStack(spacing: 12) {
                    StatTile(
                        icon: "person.2",
                        title: "Artists",
                        value: "\(stats.uniqueArtists)"
                    )
                    StatTile(
                        icon: "waveform.path.ecg",
                        title: "Avg 1–10",
                        value: String(format: "%.1f", stats.averageIntensity)
                    )
                }
            }
        }
        .shadowCard()
    }
}

private struct StatTile: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))

                Text(title)
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.white.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 0.7)
        )
    }
}

// 2) Intensity distribution

private struct IntensityDistributionCard: View {
    let buckets: [IntensityBucket]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity profile")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("How strong your triggers tend to be.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            let maxCount = max(buckets.map { $0.count }.max() ?? 1, 1)

            VStack(spacing: 10) {
                ForEach(buckets) { bucket in
                    HStack {
                        Text(bucket.label)
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                            .frame(width: 70, alignment: .leading)

                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(Color.white.opacity(0.06))
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [.purple, .blue],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(
                                        width: max(
                                            CGFloat(bucket.count) / CGFloat(maxCount) * geo.size.width,
                                            bucket.count > 0 ? 10 : 0
                                        )
                                    )
                            }
                        }
                        .frame(height: 10)

                        Text("\(bucket.count)x")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText)
                            .frame(width: 32, alignment: .trailing)
                    }
                }
            }
        }
        .shadowCard()
    }
}

// 3) Time-of-day triggers

private struct TimeOfDayCard: View {
    let buckets: [TimeOfDayBucket]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Time of day")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("When your system tends to light up the most.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            HStack(spacing: 12) {
                ForEach(buckets) { bucket in
                    VStack(spacing: 6) {
                        Text(bucket.icon)
                            .font(.largeTitle)

                        Text(bucket.label)
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(MSTheme.secondaryText)

                        Text("\(bucket.count)x")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.85))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(Color.white.opacity(0.05))
                    )
                }
            }
        }
        .shadowCard()
    }
}

// 4) Top Songs

private struct TopSongsCard: View {
    let items: [SongAggregate]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most activating songs")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            ForEach(items.prefix(5)) { item in
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.title)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MSTheme.primaryText)

                            Text(item.artist)
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        Spacer()
                        Text("\(item.count)x")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    HStack(spacing: 8) {
                        Chip(label: "Avg \(String(format: "%.1f", item.averageIntensity))")
                        Chip(label: "Max \(item.maxIntensity)")
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .shadowCard()
    }
}

// 5) Top Artists

private struct TopArtistsCard: View {
    let items: [ArtistAggregate]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most activating artists")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            ForEach(items.prefix(5)) { artist in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(artist.artist)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        Text("\(artist.totalTriggers) triggers")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }

                    Spacer()

                    Chip(label: "Avg \(String(format: "%.1f", artist.averageIntensity))")
                }
                .padding(.vertical, 8)
            }
        }
        .shadowCard()
    }
}

// Small pill used in a few places

private struct Chip: View {
    let label: String

    var body: some View {
        Text(label)
            .font(.caption2.weight(.semibold))
            .foregroundColor(.white.opacity(0.9))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.white.opacity(0.08))
            )
    }
}

// MARK: - Aggregation Helpers

// Normalization helpers so "Sleep Token" and "sleep token" are treated as one thing.

/// Lowercases + trims for use as a dictionary/set key.
private func normalizeKey(_ raw: String?, fallback: String) -> String {
    let base = (raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fallback)
    return base.lowercased()
}

/// Picks a nice display value from a bunch of raw strings:
/// – prefers the first non-empty trimmed string
/// – falls back to the given label if nothing good is found.
private func canonicalDisplay(from values: [String?], fallback: String) -> String {
    for value in values {
        if let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines),
           !trimmed.isEmpty {
            return trimmed
        }
    }
    return fallback
}

func aggregateSongs(from events: [SongEvent]) -> [SongAggregate] {
    let iso = ISO8601DateFormatter()

    // Group by normalized song title + artist so case/spacing differences
    // don't create duplicates.
    let grouped = Dictionary(grouping: events) { event in
        SongKey(
            title: normalizeKey(event.song_title, fallback: "unknown song"),
            artist: normalizeKey(event.artist, fallback: "unknown artist")
        )
    }

    return grouped.map { _, eventsForSong in
        let intensities = eventsForSong.compactMap { $0.intensity }

        let avg = intensities.isEmpty
            ? 0.0
            : Double(intensities.reduce(0, +)) / Double(intensities.count)

        let maxVal = intensities.max() ?? 0

        let lastDate = eventsForSong
            .compactMap { $0.created_at }
            .compactMap { iso.date(from: $0) }
            .sorted(by: >)
            .first

        let displayTitle = canonicalDisplay(
            from: eventsForSong.map { $0.song_title },
            fallback: "Unknown song"
        )

        let displayArtist = canonicalDisplay(
            from: eventsForSong.map { $0.artist },
            fallback: "Unknown artist"
        )

        return SongAggregate(
            title: displayTitle,
            artist: displayArtist,
            count: eventsForSong.count,
            averageIntensity: avg,
            maxIntensity: maxVal,
            lastTriggeredAt: lastDate
        )
    }
}

private func aggregateArtists(from songs: [SongAggregate]) -> [ArtistAggregate] {
    // Group by normalized artist key so "Sleep Token" and "sleep token"
    // roll up into a single artist row.
    let grouped = Dictionary(grouping: songs) {
        normalizeKey($0.artist, fallback: "unknown artist")
    }

    return grouped.map { _, items in
        let total = items.reduce(0) { $0 + $1.count }

        let avg = items.isEmpty
            ? 0.0
            : items.reduce(0.0) { $0 + $1.averageIntensity } / Double(items.count)

        let displayArtist = canonicalDisplay(
            from: items.map { $0.artist },
            fallback: "Unknown artist"
        )

        return ArtistAggregate(
            artist: displayArtist,
            totalTriggers: total,
            averageIntensity: avg
        )
    }
}

private func makeQuickStats(from events: [SongEvent]) -> QuickStats {
    let intensities = events.compactMap { $0.intensity }
    let avg = intensities.isEmpty
        ? 0.0
        : Double(intensities.reduce(0, +)) / Double(intensities.count)

    // Unique songs keyed by normalized title + artist.
    let songKeys: Set<SongKey> = Set(
        events.map {
            SongKey(
                title: normalizeKey($0.song_title, fallback: "unknown song"),
                artist: normalizeKey($0.artist, fallback: "unknown artist")
            )
        }
    )

    // Unique artists keyed by normalized artist name.
    let artistKeys: Set<String> = Set(
        events.map { normalizeKey($0.artist, fallback: "unknown artist") }
    )

    return QuickStats(
        totalTriggers: events.count,
        uniqueSongs: songKeys.count,
        uniqueArtists: artistKeys.count,
        averageIntensity: avg
    )
}

private func makeIntensityBuckets(from events: [SongEvent]) -> [IntensityBucket] {
    let ints = events.compactMap { $0.intensity }

    func count(in range: ClosedRange<Int>) -> Int {
        ints.filter { range.contains($0) }.count
    }

    return [
        IntensityBucket(label: "Soft 1–3",    range: 1...3,  count: count(in: 1...3)),
        IntensityBucket(label: "Medium 4–7",  range: 4...7,  count: count(in: 4...7)),
        IntensityBucket(label: "Intense 8–10", range: 8...10, count: count(in: 8...10))
    ]
}

private func makeTimeOfDayBuckets(from events: [SongEvent]) -> [TimeOfDayBucket] {
    let iso = ISO8601DateFormatter()
    let calendar = Calendar.current

    func hour(for event: SongEvent) -> Int? {
        guard
            let created = event.created_at,
            let date = iso.date(from: created)
        else { return nil }
        return calendar.component(.hour, from: date)
    }

    var night = 0, morning = 0, afternoon = 0, evening = 0

    for event in events {
        guard let h = hour(for: event) else { continue }
        switch h {
        case 0..<6:   night += 1
        case 6..<12:  morning += 1
        case 12..<18: afternoon += 1
        default:      evening += 1
        }
    }

    return [
        TimeOfDayBucket(label: "Night",     icon: "🌙", count: night),
        TimeOfDayBucket(label: "Morning",   icon: "🌅", count: morning),
        TimeOfDayBucket(label: "Afternoon", icon: "🌤", count: afternoon),
        TimeOfDayBucket(label: "Evening",   icon: "🌇", count: evening)
    ]
}

