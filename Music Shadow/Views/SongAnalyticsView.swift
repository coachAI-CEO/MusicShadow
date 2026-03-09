import SwiftUI

// MARK: - Aggregated Models

struct SongAggregate: Identifiable, Hashable {
    let id = UUID()
    let title: String
    let artist: String
    let count: Int
    let averageIntensity: Double
    let maxIntensity: Int
    let lastTriggeredAt: Date?
}

struct ArtistAggregate: Identifiable, Hashable {
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

private enum ValenceFilter: String, CaseIterable, Identifiable {
    case all
    case shadow
    case positive

    var id: String { rawValue }

    var label: String {
        switch self {
        case .all: return "All"
        case .shadow: return "Shadow"
        case .positive: return "Positive"
        }
    }

    var helperText: String {
        switch self {
        case .all:
            return "Showing all activations."
        case .shadow:
            return "Showing only shadow spikes."
        case .positive:
            return "Showing only positive hits."
        }
    }
}

private enum DateRangeFilter: Int, CaseIterable, Identifiable {
    case all = 0
    case last7Days = 7
    case last30Days = 30
    case last90Days = 90
    
    var id: Int { rawValue }
    
    var days: Int { rawValue }
    
    var label: String {
        switch self {
        case .all: return "All Time"
        case .last7Days: return "Last 7 Days"
        case .last30Days: return "Last 30 Days"
        case .last90Days: return "Last 90 Days"
        }
    }
}

struct SongAnalyticsView: View {
    let events: [SongEvent]

    @State private var valenceFilter: ValenceFilter = .all
    @State private var showAdvancedFilters: Bool = false
    
    // Advanced filter states
    @State private var dateRangeFilter: DateRangeFilter = .all
    @State private var selectedBodyLocation: String? = nil
    @State private var minIntensity: Double = 1.0
    @State private var maxIntensity: Double = 10.0
    @State private var intensityFilterEnabled: Bool = false

    @State private var selectedSong: SongAggregate?
    @State private var selectedArtist: ArtistAggregate?
    
    // Available filter options
    private var availableBodyLocations: [String] {
        let locations = events.compactMap { $0.body_location?.lowercased() }
        return Array(Set(locations)).sorted()
    }

    private var filteredEvents: [SongEvent] {
        var filtered = events
        
        // Valence filter
        switch valenceFilter {
        case .all:
            break
        case .shadow:
            filtered = filtered.filter { ($0.valence ?? "shadow").lowercased() == "shadow" }
        case .positive:
            filtered = filtered.filter { ($0.valence ?? "").lowercased() == "positive" }
        }
        
        // Date range filter
        filtered = applyDateRangeFilter(to: filtered)
        
        // Body location filter
        if let location = selectedBodyLocation {
            filtered = filtered.filter { ($0.body_location?.lowercased() ?? "") == location.lowercased() }
        }
        
        // Intensity range filter
        if intensityFilterEnabled {
            filtered = filtered.filter { event in
                guard let intensity = event.intensity else { return false }
                return intensity >= Int(minIntensity) && intensity <= Int(maxIntensity)
            }
        }
        
        return filtered
    }
    
    private func applyDateRangeFilter(to events: [SongEvent]) -> [SongEvent] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let calendar = Calendar.current
        let now = Date()
        
        guard let cutoffDate = calendar.date(byAdding: .day, value: -dateRangeFilter.days, to: now) else {
            return events
        }
        
        if dateRangeFilter == .all {
            return events
        }
        
        return events.filter { event in
            guard let created = event.created_at,
                  let date = iso.date(from: created) else {
                return false
            }
            return date >= cutoffDate
        }
    }
    
    private var activeFilterCount: Int {
        var count = 0
        if valenceFilter != .all { count += 1 }
        if dateRangeFilter != .all { count += 1 }
        if selectedBodyLocation != nil { count += 1 }
        if intensityFilterEnabled { count += 1 }
        return count
    }

    // MARK: Aggregated data

    private var songAggregates: [SongAggregate] {
        aggregateSongs(from: filteredEvents).sorted { $0.count > $1.count }
    }

    private var artistAggregates: [ArtistAggregate] {
        aggregateArtists(from: songAggregates).sorted { $0.totalTriggers > $1.totalTriggers }
    }

    private var positiveSongAggregates: [SongAggregate] {
        let positives = events.filter { ($0.valence ?? "").lowercased() == "positive" }
        return aggregateSongs(from: positives).sorted { $0.count > $1.count }
    }

    private var stats: QuickStats {
        makeQuickStats(from: filteredEvents)
    }

    private var intensityBuckets: [IntensityBucket] {
        makeIntensityBuckets(from: filteredEvents)
    }

    private var timeOfDayBuckets: [TimeOfDayBucket] {
        makeTimeOfDayBuckets(from: filteredEvents)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                headerSection

                if !events.isEmpty {
                    filterSection
                }

                contentSection
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            // Refresh would need to be handled by parent if we're receiving events
            // For now, this will help with future self-loading implementation
        }
        .navigationDestination(item: $selectedSong) { song in
            // Compute events from all events (not filtered) to ensure we get all matches
            // The detail view will show stats for this specific song regardless of filter
            SongAnalyticsSongDetailView(
                song: song,
                events: eventsForSong(song, in: events)
            )
        }
        .navigationDestination(item: $selectedArtist) { artist in
            SongAnalyticsArtistDetailView(
                artist: artist,
                events: eventsForArtist(artist, in: filteredEvents)
            )
        }
    }

    // MARK: - Section builders

    @ViewBuilder
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Song Activation Analytics")
                .font(.title2.bold())
                .foregroundColor(MSTheme.primaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.85)

            Text("See how the music you feel most shapes your patterns.")
                .font(.footnote)
                .foregroundColor(MSTheme.secondaryText)
                .lineLimit(2)
                .minimumScaleFactor(0.9)

            NavigationLink {
                SongAnalyticsLearnMoreView()
            } label: {
                HStack(spacing: 6) {
                    Text("What does this mean?")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "questionmark.circle")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
                .foregroundColor(MSTheme.secondaryText)
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.top, 12)
    }

    @ViewBuilder
    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Quick valence filter
            HStack(spacing: 8) {
                ForEach(ValenceFilter.allCases) { filter in
                    Button {
                        valenceFilter = filter
                    } label: {
                        Text(filter.label)
                            .font(.footnote.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(
                                        filter == valenceFilter
                                        ? Color.white.opacity(0.20)
                                        : Color.white.opacity(0.05)
                                    )
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .stroke(
                                        filter == valenceFilter
                                        ? Color.white.opacity(0.9)
                                        : Color.white.opacity(0.25),
                                        lineWidth: 1
                                    )
                            )
                            .foregroundColor(
                                filter == valenceFilter
                                ? MSTheme.primaryText
                                : MSTheme.secondaryText
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            
            // Advanced filters toggle
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAdvancedFilters.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: showAdvancedFilters ? "chevron.up" : "chevron.down")
                        .font(.caption2)
                    Text("Advanced Filters")
                        .font(.caption.weight(.semibold))
                    if activeFilterCount > 0 {
                        Text("(\(activeFilterCount))")
                            .font(.caption2)
                    }
                }
                .foregroundColor(MSTheme.secondaryText)
            }
            .buttonStyle(.plain)
            
            // Advanced filters panel
            if showAdvancedFilters {
                VStack(alignment: .leading, spacing: 16) {
                    // Date range filter
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time Range")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MSTheme.secondaryText)
                        
                        Picker("Time Range", selection: $dateRangeFilter) {
                            ForEach(DateRangeFilter.allCases) { range in
                                Text(range.label).tag(range)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    // Body location filter
                    if !availableBodyLocations.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Body Location")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(MSTheme.secondaryText)
                                
                                if selectedBodyLocation != nil {
                                    Button {
                                        selectedBodyLocation = nil
                                    } label: {
                                        Text("Clear")
                                            .font(.caption2)
                                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                                    }
                                }
                            }
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(availableBodyLocations, id: \.self) { location in
                                        Button {
                                            selectedBodyLocation = selectedBodyLocation == location ? nil : location
                                        } label: {
                                            Text(location.capitalized)
                                                .font(.caption)
                                                .padding(.horizontal, 12)
                                                .padding(.vertical, 6)
                                                .background(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .fill(
                                                            selectedBodyLocation == location
                                                            ? MSTheme.Colors.accentPrimary
                                                            : Color.white.opacity(0.06)
                                                        )
                                                )
                                                .foregroundColor(
                                                    selectedBodyLocation == location
                                                    ? MSTheme.primaryText
                                                    : MSTheme.secondaryText
                                                )
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                    }
                    
                    // Intensity range filter
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Intensity Range")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(MSTheme.secondaryText)
                            
                            Toggle("", isOn: $intensityFilterEnabled)
                                .toggleStyle(.switch)
                                .labelsHidden()
                        }
                        
                        if intensityFilterEnabled {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("\(Int(minIntensity))")
                                        .font(.caption)
                                        .foregroundColor(MSTheme.secondaryText)
                                    Spacer()
                                    Text("\(Int(maxIntensity))")
                                        .font(.caption)
                                        .foregroundColor(MSTheme.secondaryText)
                                }
                                
                                RangeSlider(minValue: $minIntensity, maxValue: $maxIntensity, range: 1...10)
                                    .frame(height: 20)
                            }
                        }
                    }
                    
                    // Clear all filters button
                    if activeFilterCount > 0 {
                        Button {
                            withAnimation {
                                valenceFilter = .all
                                dateRangeFilter = .all
                                selectedBodyLocation = nil
                                intensityFilterEnabled = false
                            }
                        } label: {
                            Text("Clear All Filters")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Active filters summary
            if activeFilterCount > 0 {
                Text(filterSummaryText)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            } else {
                Text(valenceFilter.helperText)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }
        }
        .padding(.top, 4)
    }
    
    private var filterSummaryText: String {
        var parts: [String] = []
        if valenceFilter != .all {
            parts.append(valenceFilter.label.lowercased())
        }
        if dateRangeFilter != .all {
            parts.append(dateRangeFilter.label.lowercased())
        }
        if let location = selectedBodyLocation {
            parts.append("\(location.capitalized) only")
        }
        if intensityFilterEnabled {
            parts.append("Intensity \(Int(minIntensity))-\(Int(maxIntensity))")
        }
        return "Showing: \(parts.joined(separator: ", "))."
    }

    @ViewBuilder
    private var contentSection: some View {
        if events.isEmpty {
            VStack(spacing: 20) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 12) {
                    Text("No analytics yet")
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("Analytics appear once you've logged a few music activations.")
                .font(.footnote)
                .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    NewTriggerView()
                } label: {
                    Text("Log an activation")
                        .font(.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44) // Accessibility: minimum tap target
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(Color.purple.opacity(0.9))
                        )
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Log an activation")
                
            Spacer()
            }
            .padding(24)
        } else if filteredEvents.isEmpty {
            Text("No activations match this view yet. Try another filter or log a few more activations.")
                .font(.footnote)
                .foregroundColor(MSTheme.secondaryText)
                .shadowCard()
            Spacer()
        } else {
            // 1) Quick stats
            QuickStatsCard(stats: stats)
            
            // 1.5) Pattern Correlation Insights
            let correlations = detectPatternCorrelations(from: filteredEvents)
            if !correlations.isEmpty {
                PatternCorrelationInsightsCard(insights: correlations)
            }

            // 2) Intensity distribution
            IntensityDistributionCard(buckets: intensityBuckets)

            // 3) Time-of-day pattern
            TimeOfDayCard(buckets: timeOfDayBuckets)

            // 4) Top songs
            if !songAggregates.isEmpty {
                TopSongsCard(items: songAggregates) { song in
                    selectedSong = song
                    // Events will be computed in navigationDestination
                }
            }

            // 4b) Top positive-hit songs
            if !positiveSongAggregates.isEmpty {
                PositiveSongsCard(items: positiveSongAggregates) { song in
                    selectedSong = song
                    // Events will be computed in navigationDestination
                }
            }

            // 5) Top artists
            if !artistAggregates.isEmpty {
                TopArtistsCard(items: artistAggregates) { artist in
                    selectedArtist = artist
                    // Events will be computed in navigationDestination
                }
            }

            // Data source footnote
            Text("Based on all activations you've logged on this account.")
                .font(.caption2)
                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                .padding(.top, 4)
        }
    }
}

// MARK: - Filter Components

struct RangeSlider: View {
    @Binding var minValue: Double
    @Binding var maxValue: Double
    let range: ClosedRange<Double>
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 4)
                
                // Active range
                let minPercent = (minValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                let maxPercent = (maxValue - range.lowerBound) / (range.upperBound - range.lowerBound)
                let minX = geometry.size.width * minPercent
                let maxX = geometry.size.width * maxPercent
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(MSTheme.accentGradient)
                    .frame(width: maxX - minX, height: 4)
                    .offset(x: minX)
                
                // Min thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: minX - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPercent = (value.location.x / geometry.size.width).clamped(to: 0...1)
                                let newValue = range.lowerBound + newPercent * (range.upperBound - range.lowerBound)
                                if newValue < maxValue {
                                    minValue = newValue
                                }
                            }
                    )
                
                // Max thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 20, height: 20)
                    .offset(x: maxX - 10)
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                let newPercent = (value.location.x / geometry.size.width).clamped(to: 0...1)
                                let newValue = range.lowerBound + newPercent * (range.upperBound - range.lowerBound)
                                if newValue > minValue {
                                    maxValue = newValue
                                }
                            }
                    )
            }
        }
    }
}

extension Double {
    func clamped(to range: ClosedRange<Double>) -> Double {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}

// MARK: - Cards

// 0) Pattern Correlation Insights

struct PatternCorrelationInsightsCard: View {
    let insights: [PatternCorrelation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "lightbulb.fill")
                    .foregroundColor(MSTheme.Colors.accentPrimary)
                Text("Pattern Insights")
                    .font(.headline)
                    .foregroundColor(MSTheme.secondaryText)
            }
            
            Text("Auto-detected patterns across your activations.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            
            VStack(alignment: .leading, spacing: 10) {
                ForEach(insights) { insight in
                    HStack(alignment: .top, spacing: 10) {
                        // Confidence indicator
                        Circle()
                            .fill(insight.confidence == "High" ? MSTheme.Colors.accentPrimary : MSTheme.secondaryText.opacity(0.5))
                            .frame(width: 6, height: 6)
                            .padding(.top, 6)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(insight.message)
                                .font(.subheadline)
                                .foregroundColor(MSTheme.primaryText)
                                .fixedSize(horizontal: false, vertical: true)
                            
                            HStack(spacing: 4) {
                                Text(insight.category)
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                                Text("·")
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.5))
                                Text("\(insight.confidence) confidence")
                                    .font(.caption2)
                                    .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            }
                        }
                    }
                    
                    if insight.id != insights.last?.id {
                        Divider()
                            .background(MSTheme.cardStroke.opacity(0.3))
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.top, 4)
        }
        .shadowCard()
    }
}

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

            HStack(spacing: 12) {
                StatTile(
                    icon: "bolt.heart",
                    title: "Activations",
                    value: "\(stats.totalTriggers)"
                )
                StatTile(
                    icon: "music.note.list",
                    title: "Songs",
                    value: "\(stats.uniqueSongs)"
                )
                StatTile(
                    icon: "person.2.wave.2",
                    title: "Artists",
                    value: "\(stats.uniqueArtists)"
                )
                StatTile(
                    icon: "waveform.path.ecg",
                    title: "Avg intensity",
                    value: String(format: "%.1f", stats.averageIntensity)
                )
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
            // Title gets full width so it doesn't truncate
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            // Icon sits next to the numeric value
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.9))

                Text(value)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
            }
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

            Text("How strong your activations tend to be.")
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
    let onTap: (SongAggregate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most activating songs")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            ForEach(items.prefix(5)) { item in
                Button {
                    onTap(item)
                } label: {
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
                        if let last = item.lastTriggeredAt {
                            Text("Last activated \(relativeDateString(from: last))")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .shadowCard()
    }
}

// 4b) Top Positive-Hit Songs

private struct PositiveSongsCard: View {
    let items: [SongAggregate]
    let onTap: (SongAggregate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most uplifting songs")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Songs most often linked to positive, expanding hits in your system.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            ForEach(items.prefix(5)) { item in
                Button {
                    onTap(item)
                } label: {
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
                        if let last = item.lastTriggeredAt {
                            Text("Last activated \(relativeDateString(from: last))")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                        }
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .shadowCard()
    }
}

// 5) Top Artists

private struct TopArtistsCard: View {
    let items: [ArtistAggregate]
    let onTap: (ArtistAggregate) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Most activating artists")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            ForEach(items.prefix(5)) { artist in
                Button {
                    onTap(artist)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(artist.artist)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(MSTheme.primaryText)

                            Text("\(artist.totalTriggers) activations")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                        }

                        Spacer()

                        Chip(label: "Avg \(String(format: "%.1f", artist.averageIntensity))")
                    }
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
            }
        }
        .shadowCard()
    }
}

// MARK: - Detail Views

struct SongAnalyticsSongDetailView: View {
    let song: SongAggregate
    let events: [SongEvent]

    private var stats: QuickStats {
        makeQuickStats(from: events)
    }

    private var intensityBuckets: [IntensityBucket] {
        makeIntensityBuckets(from: events)
    }

    private var timeOfDayBuckets: [TimeOfDayBucket] {
        makeTimeOfDayBuckets(from: events)
    }
    
    // New computed properties for enhancements
    private var correlationInsights: [CorrelationInsight] {
        detectCorrelationInsights(from: events, songTitle: song.title, artist: song.artist)
    }
    
    private var intensityTrendPoints: [IntensityTrendPoint] {
        makeIntensityTrendPoints(from: events)
    }
    
    private var bodyLocationCounts: [BodyLocationCount] {
        countBodyLocations(from: events)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(song.title)
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text(song.artist)
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("\(song.count) activations · avg intensity \(String(format: "%.1f", song.averageIntensity)) · max \(song.maxIntensity)")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }

                // Correlation Insights
                if !correlationInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 6) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundColor(MSTheme.Colors.accentPrimary)
                            Text("Pattern Detected")
                                .font(.headline)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        
                        ForEach(correlationInsights) { insight in
                            CorrelationInsightCard(insight: insight)
                        }
                    }
                    .shadowCard()
                }

                QuickStatsCard(stats: stats)
                
                // Intensity Trends Over Time
                if !intensityTrendPoints.isEmpty && intensityTrendPoints.count > 1 {
                    IntensityTrendCard(points: intensityTrendPoints)
                }
                
                IntensityDistributionCard(buckets: intensityBuckets)
                
                // Body Location Patterns
                if !bodyLocationCounts.isEmpty {
                    BodyLocationPatternCard(counts: bodyLocationCounts)
                }
                
                TimeOfDayCard(buckets: timeOfDayBuckets)

                if !events.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recent activations")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)

                        Text("Each dot is one activation for this song (larger dots = higher intensity).")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                        RecentTriggersTimeline(
                            events: Array(
                                events
                                    .sorted(by: { ($0.created_at ?? "") < ($1.created_at ?? "") })
                                    .prefix(20)
                            )
                        )
                    }
                    .shadowCard()
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct SongAnalyticsArtistDetailView: View {
    let artist: ArtistAggregate
    let events: [SongEvent]

    private var stats: QuickStats {
        makeQuickStats(from: events)
    }

    private var intensityBuckets: [IntensityBucket] {
        makeIntensityBuckets(from: events)
    }

    private var timeOfDayBuckets: [TimeOfDayBucket] {
        makeTimeOfDayBuckets(from: events)
    }

    // Aggregate songs just for this artist
    private var songAggregates: [SongAggregate] {
        aggregateSongs(from: events).sorted { $0.count > $1.count }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(artist.artist)
                        .font(.title2.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("\(artist.totalTriggers) activations across your log")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }

                QuickStatsCard(stats: stats)
                IntensityDistributionCard(buckets: intensityBuckets)
                TimeOfDayCard(buckets: timeOfDayBuckets)

                if !songAggregates.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Songs from this artist")
                            .font(.headline)
                            .foregroundColor(MSTheme.secondaryText)

                        Text("How often each song from this artist shows up in your triggers.")
                            .font(.caption2)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.9))

                        let maxCount = max(songAggregates.map { $0.count }.max() ?? 1, 1)

                        VStack(spacing: 8) {
                            ForEach(songAggregates.prefix(10)) { song in
                                HStack(spacing: 10) {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(song.title)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundColor(MSTheme.primaryText)
                                            .lineLimit(1)
                                            .minimumScaleFactor(0.8)

                                        Text("\(song.count)x activations · avg \(String(format: "%.1f", song.averageIntensity)) · max \(song.maxIntensity)")
                                            .font(.caption2)
                                            .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                                    }

                                    Spacer()

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color.white.opacity(0.08))

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
                                                        CGFloat(song.count) / CGFloat(maxCount) * geo.size.width,
                                                        song.count > 0 ? 10 : 0
                                                    )
                                                )
                                        }
                                    }
                                    .frame(width: 80, height: 8)
                                }
                            }
                        }
                    }
                    .shadowCard()
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct SongEventRow: View {
    let event: SongEvent

    var body: some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(event.song_title ?? "Unknown song")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                Text(event.artist ?? "Unknown artist")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
            }

            Spacer()

            HStack(spacing: 6) {
                if event.share_with_partner == true {
                    Image(systemName: "person.2")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText)
                }

            if let intensity = event.intensity {
                Text("\(intensity)/10")
                    .font(.caption2.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Enhanced Detail View Components

private struct CorrelationInsightCard: View {
    let insight: CorrelationInsight
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "sparkles")
                .foregroundColor(MSTheme.Colors.accentPrimary)
                .font(.caption)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(insight.message)
                    .font(.subheadline)
                    .foregroundColor(MSTheme.primaryText)
                
                Text("\(insight.confidence) confidence")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.8))
            }
        }
        .padding(.vertical, 8)
    }
}

private struct IntensityTrendCard: View {
    let points: [IntensityTrendPoint]
    
    private var minIntensity: Int {
        points.map { $0.intensity }.min() ?? 0
    }
    
    private var maxIntensity: Int {
        points.map { $0.intensity }.max() ?? 10
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Intensity Over Time")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)
            
            Text("How your intensity has changed across multiple listens.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            
            if points.count > 1 {
                GeometryReader { geo in
                    ZStack(alignment: .bottomLeading) {
                        // Grid lines
                        ForEach(1..<10) { level in
                            Rectangle()
                                .fill(Color.white.opacity(0.05))
                                .frame(height: 1)
                                .offset(y: -geo.size.height * CGFloat(level) / 10)
                        }
                        
                        // Trend line
                        Path { path in
                            guard !points.isEmpty else { return }
                            let range = Double(maxIntensity - minIntensity)
                            let rangeStart = Double(minIntensity)
                            
                            for (index, point) in points.enumerated() {
                                let x = geo.size.width * CGFloat(index) / CGFloat(max(points.count - 1, 1))
                                let normalizedIntensity = range > 0 
                                    ? (Double(point.intensity) - rangeStart) / range
                                    : 0.5
                                let y = geo.size.height - (geo.size.height * CGFloat(normalizedIntensity))
                                
                                if index == 0 {
                                    path.move(to: CGPoint(x: x, y: y))
                                } else {
                                    path.addLine(to: CGPoint(x: x, y: y))
                                }
                            }
                        }
                        .stroke(MSTheme.accentGradient, lineWidth: 2)
                        
                        // Data points
                        ForEach(points) { point in
                            let x = geo.size.width * CGFloat(point.index) / CGFloat(max(points.count - 1, 1))
                            let normalizedIntensity = Double(maxIntensity - minIntensity) > 0
                                ? (Double(point.intensity) - Double(minIntensity)) / Double(maxIntensity - minIntensity)
                                : 0.5
                            let y = geo.size.height - (geo.size.height * CGFloat(normalizedIntensity))
                            
                            Circle()
                                .fill(MSTheme.Colors.accentPrimary)
                                .frame(width: 6, height: 6)
                                .position(x: x, y: y)
                        }
                        
                        // Y-axis labels
                        VStack(alignment: .leading, spacing: 0) {
                            Text("\(maxIntensity)")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                            Spacer()
                            Text("\(minIntensity)")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.7))
                        }
                    }
                }
                .frame(height: 120)
                .padding(.vertical, 8)
            }
        }
        .shadowCard()
    }
}

private struct BodyLocationPatternCard: View {
    let counts: [BodyLocationCount]
    
    private var topLocation: BodyLocationCount? {
        counts.first
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Location Patterns")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)
            
            Text("Where this song most often lands in your body.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            
            if let top = topLocation {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Most common:")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                        Spacer()
                        Text("\(top.count)x (\(Int(top.percentage))%)")
                            .font(.caption.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)
                    }
                    
                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(Color.white.opacity(0.08))
                            
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(MSTheme.accentGradient)
                                .frame(width: geo.size.width * CGFloat(top.percentage / 100))
                        }
                    }
                    .frame(height: 8)
                    
                    Text(top.location)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(MSTheme.primaryText)
                }
                .padding(.top, 4)
            }
            
            if counts.count > 1 {
                VStack(alignment: .leading, spacing: 6) {
                    Text("All locations:")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                        .padding(.top, 8)
                    
                    ForEach(counts.prefix(5)) { location in
                        HStack {
                            Text(location.location)
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText)
                            Spacer()
                            Text("\(location.count)x")
                                .font(.caption)
                                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                        }
                    }
                }
            }
        }
        .shadowCard()
    }
}

// Compact timeline for recent triggers within a single song
private struct RecentTriggersTimeline: View {
    struct TimelinePoint: Identifiable {
        let id = UUID()
        let position: Double  // 0...1 across the width
        let intensity: Int
        let createdAt: Date?
    }

    let events: [SongEvent]

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }

    private var points: [TimelinePoint] {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let sorted = events.compactMap { event -> (SongEvent, Date?) in
            let date: Date?
            if let created = event.created_at {
                date = iso.date(from: created)
            } else {
                date = nil
            }
            return (event, date)
        }
        .sorted { (lhs, rhs) in
            let l = lhs.1 ?? Date.distantPast
            let r = rhs.1 ?? Date.distantPast
            return l < r
        }

        guard !sorted.isEmpty else { return [] }

        let lastIndex = max(sorted.count - 1, 1)

        return sorted.enumerated().map { index, pair in
            let event = pair.0
            let date = pair.1
            let pos = lastIndex == 0 ? 0.5 : Double(index) / Double(lastIndex)
            return TimelinePoint(
                position: pos,
                intensity: event.intensity ?? 0,
                createdAt: date
            )
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Base line
                    Rectangle()
                        .fill(Color.white.opacity(0.15))
                        .frame(height: 2)
                        .cornerRadius(1)
                        .frame(maxHeight: .infinity, alignment: .center)

                    ForEach(points) { point in
                        let radius = 4.0 + (Double(point.intensity) / 10.0) * 4.0

                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(width: radius, height: radius)
                            .position(
                                x: geo.size.width * CGFloat(point.position),
                                y: geo.size.height / 2
                            )
                    }
                }
            }
            .frame(height: 36)

            if let first = points.first?.createdAt,
               let last = points.last?.createdAt,
               first != last {
                HStack {
                    Text(dateFormatter.string(from: first))
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                    Spacer()
                    Text(dateFormatter.string(from: last))
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                }
            } else if let only = points.first?.createdAt {
                Text("All recent activations · \(dateFormatter.string(from: only))")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            } else {
                Text("Timeline based on your last few activations for this song.")
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.9))
            }
        }
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

struct SongAnalyticsLearnMoreView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Song activations, explained")
                    .font(.title2.bold())
                    .foregroundColor(MSTheme.primaryText)

                Text("Every time you log an activation, you're telling Music Shadow: \"this song did something to my system.\" This screen helps you see the patterns in those hits.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Group {
                    Text("Activations")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("An activation is any moment the song lands strongly in your body — shadow spike or positive hit. Over time, the total number of activations shows how often music is touching something deep.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Group {
                    Text("Intensity")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("Intensity isn’t good or bad. It simply tells you how strong the activation felt in the moment (1–10). Soft, medium, and intense zones help you notice which songs barely brush you and which ones grab your whole system.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Group {
                    Text("Time of day")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("Morning vs. late-night spikes can feel very different. The time-of-day view helps you see when your nervous system is most open, raw, or defended around music.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Group {
                    Text("Shadow vs. positive hits")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("Shadow spikes are the contractions — the song hits an old wound, panic, shame, or anger. Positive hits are the openings — the song softens you, expands you, or makes you feel deeply alive. Both matter. The filter at the top lets you look at them together or separately.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Group {
                    Text("How to use this")
                        .font(.headline)
                        .foregroundColor(MSTheme.primaryText)

                    Text("You don’t need to force insights here. Just notice: which songs show up the most, when your spikes tend to happen, and whether they feel more shadowy or positive. That gentle noticing is the work.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Song activations")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Enhanced Detail View Models

struct CorrelationInsight: Identifiable {
    let id = UUID()
    let message: String
    let confidence: String // "High", "Medium", "Low"
}

struct IntensityTrendPoint: Identifiable {
    let id = UUID()
    let date: Date
    let intensity: Int
    let index: Int // Position in sequence (0, 1, 2, ...)
}

struct BodyLocationCount: Identifiable {
    let id = UUID()
    let location: String
    let count: Int
    let percentage: Double
}

// MARK: - Relative Date Helper

private func relativeDateString(from date: Date) -> String {
    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .short
    return formatter.localizedString(for: date, relativeTo: Date())
}

// MARK: - Aggregation Helpers

func aggregateSongs(from events: [SongEvent]) -> [SongAggregate] {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

    let grouped = Dictionary(grouping: events) { event in
        SongKey(
            title: event.song_title ?? "Unknown song",
            artist: event.artist ?? "Unknown artist"
        )
    }

    return grouped.map { key, eventsForSong in
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

        return SongAggregate(
            title: key.title,
            artist: key.artist,
            count: eventsForSong.count,
            averageIntensity: avg,
            maxIntensity: maxVal,
            lastTriggeredAt: lastDate
        )
    }
}

private func aggregateArtists(from songs: [SongAggregate]) -> [ArtistAggregate] {
    let grouped = Dictionary(grouping: songs) { $0.artist }

    return grouped.map { artist, items in
        let total = items.reduce(0) { $0 + $1.count }
        let avg = items.isEmpty
            ? 0.0
            : items.reduce(0.0) { $0 + $1.averageIntensity } / Double(items.count)

        return ArtistAggregate(
            artist: artist,
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

    let songKeys: Set<SongKey> = Set(
        events.map {
            SongKey(
                title: $0.song_title ?? "Unknown song",
                artist: $0.artist ?? "Unknown artist"
            )
        }
    )

    let artists: Set<String> = Set(events.compactMap { $0.artist ?? "Unknown artist" })

    return QuickStats(
        totalTriggers: events.count,
        uniqueSongs: songKeys.count,
        uniqueArtists: artists.count,
        averageIntensity: avg
    )
}

private func makeIntensityBuckets(from events: [SongEvent]) -> [IntensityBucket] {
    let ints = events.compactMap { $0.intensity }

    func count(in range: ClosedRange<Int>) -> Int {
        ints.filter { range.contains($0) }.count
    }

    return [
        IntensityBucket(label: "Soft 1–3", range: 1...3, count: count(in: 1...3)),
        IntensityBucket(label: "Medium 4–7", range: 4...7, count: count(in: 4...7)),
        IntensityBucket(label: "Intense 8–10", range: 8...10, count: count(in: 8...10))
    ]
}

private func makeTimeOfDayBuckets(from events: [SongEvent]) -> [TimeOfDayBucket] {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
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
        case 0..<6: night += 1
        case 6..<12: morning += 1
        case 12..<18: afternoon += 1
        default: evening += 1
        }
    }

    return [
        TimeOfDayBucket(label: "Night", icon: "🌙", count: night),
        TimeOfDayBucket(label: "Morning", icon: "🌅", count: morning),
        TimeOfDayBucket(label: "Afternoon", icon: "🌤", count: afternoon),
        TimeOfDayBucket(label: "Evening", icon: "🌇", count: evening)
    ]
}

private func eventsForSong(_ song: SongAggregate, in source: [SongEvent]) -> [SongEvent] {
    let key = SongKey(title: song.title, artist: song.artist)
    return source.filter {
        let eventKey = SongKey(
            title: $0.song_title ?? "Unknown song",
            artist: $0.artist ?? "Unknown artist"
        )
        return eventKey == key
    }
}

private func eventsForArtist(_ artist: ArtistAggregate, in source: [SongEvent]) -> [SongEvent] {
    return source.filter { ($0.artist ?? "Unknown artist") == artist.artist }
}

// MARK: - Global Pattern Correlation Detection

public struct PatternCorrelation: Identifiable {
    public let id = UUID()
    public let message: String
    public let confidence: String // "High", "Medium"
    public let category: String // "Artist", "Time", "Intensity", etc.
    
    public init(message: String, confidence: String, category: String) {
        self.message = message
        self.confidence = confidence
        self.category = category
    }
}

/// Detect pattern correlations across all events
private func detectPatternCorrelations(from events: [SongEvent]) -> [PatternCorrelation] {
    guard events.count >= 5 else { return [] } // Need at least 5 events to detect patterns
    var correlations: [PatternCorrelation] = []
    
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    let calendar = Calendar.current
    
    // 1. Artist patterns: "Songs by X always trigger Y in Z"
    let eventsByArtist = Dictionary(grouping: events) { $0.artist ?? "Unknown" }
    for (artist, artistEvents) in eventsByArtist where artistEvents.count >= 3 && artist != "Unknown" {
        // Check for consistent body location
        let bodyLocations = artistEvents.compactMap { $0.body_location?.lowercased() }
        if bodyLocations.count >= 3 {
            let locationCounts = Dictionary(grouping: bodyLocations, by: { $0 }).mapValues { $0.count }
            let total = bodyLocations.count
            let threshold = Int(Double(total) * 0.75) // 75% threshold
            
            if let (location, count) = locationCounts.first(where: { $1 >= threshold }) {
                let percentage = Int((Double(count) / Double(total)) * 100)
                let confidence = count >= Int(Double(total) * 0.85) ? "High" : "Medium"
                
                // Check for consistent impulse
                let impulses = artistEvents.compactMap { $0.impulse?.lowercased() }
                let impulseCounts = Dictionary(grouping: impulses, by: { $0 }).mapValues { $0.count }
                let impulseTotal = impulses.count
                if let (impulse, impulseCount) = impulseCounts.first(where: { $1 >= Int(Double(impulseTotal) * 0.75) }) {
                    correlations.append(PatternCorrelation(
                        message: "Songs by \(artist) typically trigger \(impulse.capitalized) responses in your \(location.capitalized) (\(percentage)% of the time)",
                        confidence: confidence,
                        category: "Artist"
                    ))
                } else {
                    correlations.append(PatternCorrelation(
                        message: "Songs by \(artist) consistently land in your \(location.capitalized) (\(percentage)% of activations)",
                        confidence: confidence,
                        category: "Artist"
                    ))
                }
            }
        }
    }
    
    // 2. Time-of-day intensity patterns: "Evening triggers tend to be higher intensity"
    var eveningEvents: [SongEvent] = []
    var morningEvents: [SongEvent] = []
    var afternoonEvents: [SongEvent] = []
    var nightEvents: [SongEvent] = []
    
    for event in events {
        guard let created = event.created_at,
              let date = iso.date(from: created) else { continue }
        let hour = calendar.component(.hour, from: date)
        switch hour {
        case 0..<6: nightEvents.append(event)
        case 6..<12: morningEvents.append(event)
        case 12..<18: afternoonEvents.append(event)
        default: eveningEvents.append(event)
        }
    }
    
    func averageIntensity(for events: [SongEvent]) -> Double {
        let intensities = events.compactMap { $0.intensity }
        guard !intensities.isEmpty else { return 0 }
        return Double(intensities.reduce(0, +)) / Double(intensities.count)
    }
    
    let eveningAvg = averageIntensity(for: eveningEvents)
    let morningAvg = averageIntensity(for: morningEvents)
    let afternoonAvg = averageIntensity(for: afternoonEvents)
    let nightAvg = averageIntensity(for: nightEvents)
    
    // Find the time period with significantly higher intensity
    let allAverages = [
        ("Evening", eveningAvg, eveningEvents.count),
        ("Morning", morningAvg, morningEvents.count),
        ("Afternoon", afternoonAvg, afternoonEvents.count),
        ("Night", nightAvg, nightEvents.count)
    ]
    
    let sortedByIntensity = allAverages.filter { $0.2 >= 3 }.sorted { $0.1 > $1.1 }
    if let highest = sortedByIntensity.first,
       let lowest = sortedByIntensity.last,
       highest.1 - lowest.1 >= 2.0, // At least 2 points difference
       highest.2 >= 3 {
        correlations.append(PatternCorrelation(
            message: "\(highest.0) triggers tend to be higher intensity (avg \(String(format: "%.1f", highest.1))/10 vs \(String(format: "%.1f", lowest.1))/10)",
            confidence: highest.1 - lowest.1 >= 3.0 ? "High" : "Medium",
            category: "Time"
        ))
    }
    
    // 3. Weekday vs Weekend patterns: "Shadow triggers cluster on weekdays"
    var weekdayEvents: [SongEvent] = []
    var weekendEvents: [SongEvent] = []
    
    for event in events {
        guard let created = event.created_at,
              let date = iso.date(from: created) else { continue }
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 { // Sunday = 1, Saturday = 7
            weekendEvents.append(event)
        } else {
            weekdayEvents.append(event)
        }
    }
    
    let weekdayShadow = weekdayEvents.filter { ($0.valence ?? "").lowercased() == "shadow" }.count
    let weekendShadow = weekendEvents.filter { ($0.valence ?? "").lowercased() == "shadow" }.count
    let weekdayTotal = weekdayEvents.count
    let weekendTotal = weekendEvents.count
    
    if weekdayTotal >= 5 && weekendTotal >= 3 {
        let weekdayRatio = Double(weekdayShadow) / Double(weekdayTotal)
        let weekendRatio = Double(weekendShadow) / Double(weekendTotal)
        
        if weekdayRatio - weekendRatio >= 0.3 { // 30% difference
            let confidence = weekdayRatio - weekendRatio >= 0.5 ? "High" : "Medium"
            correlations.append(PatternCorrelation(
                message: "Shadow triggers cluster on weekdays (\(Int(weekdayRatio * 100))% vs \(Int(weekendRatio * 100))% on weekends)",
                confidence: confidence,
                category: "Time"
            ))
        } else if weekendRatio - weekdayRatio >= 0.3 {
            let confidence = weekendRatio - weekdayRatio >= 0.5 ? "High" : "Medium"
            correlations.append(PatternCorrelation(
                message: "Shadow triggers are more common on weekends (\(Int(weekendRatio * 100))% vs \(Int(weekdayRatio * 100))% on weekdays)",
                confidence: confidence,
                category: "Time"
            ))
        }
    }
    
    // 4. Body location patterns: "Most activations land in your chest"
    let allBodyLocations = events.compactMap { $0.body_location?.lowercased() }
    if allBodyLocations.count >= 5 {
        let locationCounts = Dictionary(grouping: allBodyLocations, by: { $0 }).mapValues { $0.count }
        let total = allBodyLocations.count
        
        if let (location, count) = locationCounts.max(by: { $0.value < $1.value }),
           count >= Int(Double(total) * 0.5) && count >= 5 { // At least 50% and 5+ activations
            let percentage = Int((Double(count) / Double(total)) * 100)
            correlations.append(PatternCorrelation(
                message: "Most activations land in your \(location.capitalized) (\(percentage)% of all triggers)",
                confidence: percentage >= 60 ? "High" : "Medium",
                category: "Body"
            ))
        }
    }
    
    return correlations.sorted { $0.confidence == "High" && $1.confidence != "High" }
}

// MARK: - Enhanced Detail View Helpers

/// Detect correlation insights like "always triggers Fight in chest"
private func detectCorrelationInsights(from events: [SongEvent], songTitle: String, artist: String) -> [CorrelationInsight] {
    guard events.count >= 3 else { return [] } // Need at least 3 events to detect patterns
    
    var insights: [CorrelationInsight] = []
    
    // 1. Check for consistent nervous system state (from insights if available)
    // Note: This requires insights data, which we don't have access to here
    // We'll focus on body_location, impulse, and somatic_type patterns
    
    // 2. Check for consistent body location
    let bodyLocations = events.compactMap { $0.body_location?.lowercased() }
    if !bodyLocations.isEmpty {
        let locationCounts = Dictionary(grouping: bodyLocations, by: { $0 }).mapValues { $0.count }
        let total = bodyLocations.count
        let threshold = Int(Double(total) * 0.8) // 80% threshold
        
        if let (location, count) = locationCounts.first(where: { $1 >= threshold && $1 >= 3 }) {
            let percentage = Int((Double(count) / Double(total)) * 100)
            let confidence = count >= Int(Double(total) * 0.9) ? "High" : "Medium"
            insights.append(CorrelationInsight(
                message: "This song consistently lands in your \(location.capitalized) (\(percentage)% of activations)",
                confidence: confidence
            ))
        }
    }
    
    // 3. Check for consistent impulse
    let impulses = events.compactMap { $0.impulse?.lowercased() }
    if !impulses.isEmpty {
        let impulseCounts = Dictionary(grouping: impulses, by: { $0 }).mapValues { $0.count }
        let total = impulses.count
        let threshold = Int(Double(total) * 0.75) // 75% threshold
        
        if let (impulse, count) = impulseCounts.first(where: { $1 >= threshold && $1 >= 3 }) {
            let percentage = Int((Double(count) / Double(total)) * 100)
            let confidence = count >= Int(Double(total) * 0.85) ? "High" : "Medium"
            let impulseLabel = impulse.capitalized
            insights.append(CorrelationInsight(
                message: "\(percentage)% of activations trigger a \(impulseLabel) response",
                confidence: confidence
            ))
        }
    }
    
    // 4. Check for consistent somatic type
    let somaticTypes = events.compactMap { $0.somatic_type?.lowercased() }
    if !somaticTypes.isEmpty {
        let somaticCounts = Dictionary(grouping: somaticTypes, by: { $0 }).mapValues { $0.count }
        let total = somaticTypes.count
        let threshold = Int(Double(total) * 0.75)
        
        if let (type, count) = somaticCounts.first(where: { $1 >= threshold && $1 >= 3 }) {
            let percentage = Int((Double(count) / Double(total)) * 100)
            let confidence = count >= Int(Double(total) * 0.85) ? "High" : "Medium"
            let typeLabel = type.capitalized
            insights.append(CorrelationInsight(
                message: "Most activations feel \(typeLabel) (\(percentage)% of the time)",
                confidence: confidence
            ))
        }
    }
    
    // 5. Combine body location + impulse if both are consistent
    if let bodyLocation = bodyLocations.first,
       let impulse = impulses.first,
       !insights.isEmpty {
        let bodyInsight = insights.first(where: { $0.message.contains(bodyLocation.capitalized) })
        let impulseInsight = insights.first(where: { $0.message.contains(impulse.capitalized) })
        
        if bodyInsight != nil && impulseInsight != nil {
            // Create combined insight
            let combined = CorrelationInsight(
                message: "\"\(songTitle)\" typically triggers \(impulse.capitalized) responses in your \(bodyLocation.capitalized)",
                confidence: "High"
            )
            // Remove individual insights and add combined
            insights.removeAll { $0.message.contains(bodyLocation.capitalized) || $0.message.contains(impulse.capitalized) }
            insights.insert(combined, at: 0)
        }
    }
    
    return insights
}

/// Create intensity trend points over time
private func makeIntensityTrendPoints(from events: [SongEvent]) -> [IntensityTrendPoint] {
    let iso = ISO8601DateFormatter()
    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    
    let sorted = events.compactMap { event -> (Date, Int)? in
        guard let created = event.created_at,
              let date = iso.date(from: created),
              let intensity = event.intensity else {
            return nil
        }
        return (date, intensity)
    }
    .sorted { $0.0 < $1.0 } // Sort by date
    
    return sorted.enumerated().map { index, pair in
        IntensityTrendPoint(
            date: pair.0,
            intensity: pair.1,
            index: index
        )
    }
}

/// Count body locations for a song
private func countBodyLocations(from events: [SongEvent]) -> [BodyLocationCount] {
    let locations = events.compactMap { $0.body_location?.lowercased() }
    let total = locations.count
    guard total > 0 else { return [] }
    
    let counts = Dictionary(grouping: locations, by: { $0 }).mapValues { $0.count }
    
    return counts.map { location, count in
        BodyLocationCount(
            location: location.capitalized,
            count: count,
            percentage: (Double(count) / Double(total)) * 100
        )
    }
    .sorted { $0.count > $1.count }
}
