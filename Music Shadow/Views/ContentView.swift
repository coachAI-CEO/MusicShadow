import SwiftUI
import Supabase

struct ContentView: View {

    // MARK: - Data
    @State private var events: [SongEvent] = []
    @State private var insights: [ShadowInsight] = []

    // MARK: - UI State
    @State private var isLoading: Bool = true
    @State private var errorMessage: String?
    @State private var navigationPath = NavigationPath()
    @State private var showNewTrigger = false
    @State private var patternsExpanded: Bool = false

    var body: some View {
        NavigationStack(path: $navigationPath) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // HERO
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 10) {
                            MusicShadowEmblem(size: 30)
                            
                            Text("Music Shadow")
                                .font(.largeTitle.bold())
                                .foregroundColor(MSTheme.primaryText)
                        }
                        
                        Text("Log the songs that move you. Watch the patterns underneath.")
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                    .padding(.top, 12)
                    
                    if isLoading {
                        VStack(spacing: 20) {
                            EtherealLoadingView()
                                .frame(height: 300)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(.top, 40)
                    } else if let errorMessage {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(errorMessage)
                                .foregroundColor(.red)
                                .font(.caption)
                            
                            Button {
                                Task {
                                    await loadEvents()
                                    await loadInsights()
                                }
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "arrow.clockwise")
                                        .font(.caption2)
                                    Text("Retry")
                                        .font(.caption.weight(.semibold))
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.08))
                                )
                                .foregroundColor(MSTheme.primaryText)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 16)
                    } else {
                        // MARK: 1. Quick Stats Ribbon (each pill navigates)
                        QuickStatsRibbon(
                            totalTriggers: events.count,
                            thisWeekCount: eventsThisWeek.count,
                            primaryArchetype: patternsGlanceSnapshot.archetype?.archetype.rawValue,
                            onTotalTap: { navigationPath.append("allTriggers") },
                            onThisWeekTap: { navigationPath.append("allTriggers") },
                            onArchetypeTap: { navigationPath.append("patterns") }
                        )
                        .padding(.bottom, 8)
                        
                        // MARK: 2. Featured Insight (if available)
                        if let featuredInsight = selectFeaturedInsight() {
                            FeaturedInsightCard(insight: featuredInsight) {
                                // Navigate to insight detail
                                if let event = events.first(where: { $0.id == featuredInsight.event_id }) {
                                    navigationPath.append(event.id.uuidString)
                                }
                            }
                        }
                        
                        // MARK: 3. Pattern Highlights
                        let highlights = PatternHighlight.generate(from: events, insights: insights)
                        if !highlights.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text("Patterns We're Noticing")
                                        .font(MSTheme.Typography.headline)
                                        .foregroundColor(MSTheme.Colors.primaryText)
                                    
                                    Spacer()
                                    
                                    if highlights.count > 2 {
                                        Button {
                                            withAnimation(.easeInOut(duration: 0.2)) {
                                                patternsExpanded.toggle()
                                                HapticManager.trigger(.light)
                                            }
                                        } label: {
                                            Text(patternsExpanded ? "Show Less" : "See All (\(highlights.count))")
                                                .font(.caption.weight(.semibold))
                                                .foregroundColor(MSTheme.Colors.accentPrimary)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                                .padding(.horizontal, MSTheme.Spacing.md)
                                
                                let displayedPatterns: [PatternHighlight] = patternsExpanded
                                    ? highlights
                                    : Array(highlights.prefix(2))
                                ForEach(displayedPatterns) { highlight in
                                    PatternHighlightCard(highlight: highlight, onTap: {
                                        navigationPath.append("patterns")
                                    })
                                    .padding(.horizontal, MSTheme.Spacing.md)
                                }
                            }
                        }
                        
                        // MARK: 4. Quick Actions Grid
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Quick Actions")
                                .font(MSTheme.Typography.headline)
                                .foregroundColor(MSTheme.Colors.primaryText)
                                .padding(.horizontal, MSTheme.Spacing.md)
                            
                            QuickActionsGrid(
                                onBrowseTriggers: {
                                    navigationPath.append("allTriggers")
                                },
                                onSongAnalytics: {
                                    navigationPath.append("songAnalytics")
                                },
                                onMyArchetypes: {
                                    navigationPath.append("patterns")
                                },
                                onTimeline: {
                                    navigationPath.append("patterns")
                                }
                            )
                            .padding(.horizontal, MSTheme.Spacing.md)
                        }
                        
                        // MARK: 5. Recent Activity
                        RecentActivitySection(
                            events: events,
                            maxItems: 3,
                            onViewAll: {
                                navigationPath.append("allTriggers")
                            }
                        )
                        .padding(.horizontal, MSTheme.Spacing.md)
                        
                        // MARK: 6. Shadow archetype (HERO - visual anchor)
                        if let archetype = patternsGlanceSnapshot.archetype {
                            NavigationLink {
                                ShadowArchetypeDetailView(archetype: archetype.archetype)
                            } label: {
                                HeroArchetypeCard(archetype: archetype)
                            }
                            .buttonStyle(.plain)
                            .padding(.vertical, 8)
                        }
                    }
                    
                    // FOOTER
                    Text("Every track you log is a step toward knowing your shadow.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding(.top, 4)
                        .padding(.horizontal, MSTheme.Spacing.md)
                }
                .padding(.vertical, 24)
            }
            .musicShadowBackground()
            .navigationTitle("Music Shadow")
            .navigationBarTitleDisplayMode(.inline)
            // FAB for logging new triggers
            .floatingActionButton {
                showNewTrigger = true
            }
            .sheet(isPresented: $showNewTrigger) {
                // Refresh data when sheet is dismissed
                Task {
                    await loadEvents()
                    await loadInsights()
                }
            } content: {
                NavigationStack {
                    NewTriggerView()
                }
            }
            .task {
                await loadEvents()
                await loadInsights()
            }
            .refreshable {
                DataCache.shared.invalidateAll()
                await loadEvents()
                await loadInsights()
            }
            .onReceive(NotificationCenter.default.publisher(for: .navigateToPatternsView)) { _ in
                // Add a small delay to ensure the dismiss animation completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    navigationPath.append("patterns")
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: .musicShadowDataErased)) { _ in
                // Reload data after erasure
                Task {
                    await loadEvents()
                    await loadInsights()
                }
            }
            .navigationDestination(for: String.self) { destination in
                switch destination {
                case "patterns":
                    PatternsView()
                case "allTriggers":
                    AllTriggersView(events: events)
                case "songAnalytics":
                    SongAnalyticsView(events: events)
                default:
                    // Try to navigate to trigger detail by ID
                    if let eventId = UUID(uuidString: destination),
                       let event = events.first(where: { $0.id == eventId }) {
                        TriggerDetailView(event: event)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        if !navigationPath.isEmpty {
                            navigationPath = NavigationPath()
                        }
                    } label: {
                        MusicShadowEmblem(size: 24)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Home")
                    .accessibilityHint("Return to dashboard")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MSTheme.secondaryText)
                    }
                }
            }
        }
    }
}

 // MARK: - Shadow Weather

struct ShadowWeatherSnapshot {
    let emoji: String
    let title: String
    let description: String
}

private extension ContentView {

    /// Uses roughly the last 7 days of *shadow* events' intensity to give a simple weather status.
    var shadowWeatherSnapshot: ShadowWeatherSnapshot? {
        // Parse Supabase timestamps
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        let calendar = Calendar.current
        guard let cutoff = calendar.date(byAdding: .day, value: -7, to: Date()) else {
            return nil
        }

        // Only consider shadow spikes for the weather. Positive hits are excluded here.
        let shadowEvents = events.filter { event in
            // 1) Valence filter: treat anything that isn't an explicit positive hit as shadow
            let isShadow: Bool
            if let valence = event.valence?.lowercased() {
                isShadow = (valence != "positive")
            } else {
                // For older records without valence, treat them as shadow so history still counts.
                isShadow = true
            }

            guard isShadow else { return false }

            // 2) Time window: keep only events from the last 7 days when we can parse the date
            if let createdAt = event.created_at,
               let date = formatter.date(from: createdAt) {
                return date >= cutoff
            } else {
                // If we somehow don't have a date, skip this event for the weather calc
                return false
            }
        }

        let intensities = shadowEvents.compactMap { $0.intensity }

        guard !intensities.isEmpty else {
            return ShadowWeatherSnapshot(
                emoji: "☁️",
                title: "Your shadow is still forming.",
                description: "Log a few activations and your shadow weather will start to show up here."
            )
        }

        let spikeCount = intensities.count
        let average = Double(intensities.reduce(0, +)) / Double(intensities.count)
        let avgText = String(format: "%.1f", average)

        switch average {
        case ..<3:
            return ShadowWeatherSnapshot(
                emoji: "🌙",
                title: "Calm",
                description: "Last 7 days: \(spikeCount) shadow spikes, mostly soft (avg \(avgText)/10). Your system feels relatively steady right now."
            )
        case 3..<6:
            return ShadowWeatherSnapshot(
                emoji: "⛅️",
                title: "Shifting",
                description: "Last 7 days: \(spikeCount) shadow spikes with mixed intensity (avg \(avgText)/10). Something is moving under the surface—this is often when new insights start to land."
            )
        default:
            return ShadowWeatherSnapshot(
                emoji: "⛈️",
                title: "Activated",
                description: "Last 7 days: \(spikeCount) stronger shadow spikes (avg \(avgText)/10). This is a powerful time to slow down, notice patterns, and lean on grounding practices."
            )
        }
    }
}

 // MARK: - Patterns at a glance (+ archetype)

struct TopItemSummary {
    let label: String
    let count: Int
}

struct ArchetypeSummary {
    let archetype: ShadowArchetype
    let isConfident: Bool
}

struct PatternsGlanceSnapshot {
    let topBody: TopItemSummary?
    let topImpulse: TopItemSummary?
    let topSomatic: TopItemSummary?
    let archetype: ArchetypeSummary?
}

private extension ContentView {

    var patternsGlanceSnapshot: PatternsGlanceSnapshot {
        let body = topItem(from: events.compactMap { $0.body_location })
        let impulse = topItem(from: events.compactMap { $0.impulse })
        let somatic = topItem(from: events.compactMap { $0.somatic_type })
        let archetype = archetypeSummary(from: insights, events: events)

        return PatternsGlanceSnapshot(
            topBody: body,
            topImpulse: impulse,
            topSomatic: somatic,
            archetype: archetype
        )
    }

    func topItem(from items: [String]) -> TopItemSummary? {
        guard !items.isEmpty else { return nil }

        let counts = Dictionary(grouping: items, by: { $0 })
            .map { (key, value) in (label: key, count: value.count) }
            .sorted { $0.count > $1.count }

        guard let top = counts.first else { return nil }
        return TopItemSummary(label: top.label, count: top.count)
    }

    func archetypeSummary(from insights: [ShadowInsight], events: [SongEvent]) -> ArchetypeSummary? {
        let scores = ArchetypeEngine.scores(from: insights, events: events)

        guard let primary = scores.first, primary.score > 0 else {
            return nil
        }

        // You can tweak this threshold later
        let isConfident = primary.score >= 3

        return ArchetypeSummary(
            archetype: primary.archetype,
            isConfident: isConfident
        )
    }
}

struct PatternsGlanceCard: View {
    let snapshot: PatternsGlanceSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Where things usually land")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Quick snapshot of where things tend to land.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText.opacity(0.9))

            // Top stats row
            HStack(spacing: 12) {
                if let body = snapshot.topBody {
                    PatternStatTile(
                        icon: "figure.arms.open",
                        title: "Body hotspot",
                        value: body.label.capitalized,
                        count: "\(body.count)x",
                        intensity: body.count
                    )
                }

                if let impulse = snapshot.topImpulse {
                    PatternStatTile(
                        icon: "figure.run",
                        title: "Impulse",
                        value: impulse.label.capitalized,
                        count: "\(impulse.count)x",
                        intensity: impulse.count
                    )
                }

                if let somatic = snapshot.topSomatic {
                    PatternStatTile(
                        icon: "waveform.path.ecg",
                        title: "Sensation",
                        value: somatic.label.capitalized,
                        count: "\(somatic.count)x",
                        intensity: somatic.count
                    )
                }
            }
        }
        .shadowCard()
    }
}

// MARK: - Hero Archetype Card (visual anchor)

struct HeroArchetypeCard: View {
    let archetype: ArchetypeSummary

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(archetype.archetype.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(MSTheme.primaryText)
                .scaledToFit()
                .frame(width: 64, height: 64)

            VStack(alignment: .leading, spacing: 6) {
                Text("Shadow archetype")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(MSTheme.secondaryText)

                Text(archetype.archetype.rawValue)
                    .font(.title3.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                Text(archetype.archetype.tagline)
                    .font(.subheadline)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                if !archetype.isConfident {
                    Text("Still forming — will refine as you log more.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                        .padding(.top, 2)
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.subheadline.weight(.semibold))
                .foregroundColor(MSTheme.secondaryText.opacity(0.8))
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 20)
        .shadowCard()
    }
}

struct ShadowArchetypeDetailView: View {
    let archetype: ShadowArchetype

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 14) {
                    Image(archetype.iconName)
                        .resizable()
                        .renderingMode(.template)
                        .foregroundColor(MSTheme.primaryText)
                        .scaledToFit()
                        .frame(width: 64, height: 64)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(archetype.rawValue)
                            .font(.title3.weight(.semibold))
                            .foregroundColor(MSTheme.primaryText)

                        Text(archetype.tagline)
                            .font(.footnote)
                            .foregroundColor(MSTheme.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                        
                        Text("This is a protective pattern that developed to keep you safe.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.75))
                            .padding(.top, 2)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(MSTheme.cardStroke, lineWidth: 0.8)
                )

                VStack(alignment: .leading, spacing: 8) {
                    Text("How this pattern tends to feel")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text(archetype.longDescription)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Core wound it protects")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text(archetype.coreWound)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Nervous system pattern")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text(archetype.nervousSystemPattern)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Growth invitation")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text(archetype.growthInvitation)
                        .font(.footnote)
                        .foregroundColor(MSTheme.primaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("You don't have to change everything at once. Small experiments count.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.75))
                        .padding(.top, 6)
                }
                .shadowCard()
                .padding(.top, 8)

                // Soft closing integration line
                Text("This pattern isn't a problem — it's a protector that learned early.")
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.75))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                Spacer()
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Shadow archetype")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ShadowArchetypeLearnMoreView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Intro
                VStack(alignment: .leading, spacing: 8) {
                    Text("Shadow archetypes")
                        .font(.title3.bold())
                        .foregroundColor(MSTheme.primaryText)

                    Text("In Music Shadow, archetypes are a gentle way of naming the patterns your nervous system learned to keep you safe. They are not diagnoses or boxes you have to stay in—just lenses to get curious with.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                // How the app uses archetypes
                VStack(alignment: .leading, spacing: 8) {
                    Text("How Music Shadow uses them")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("As you log activations and reflections, the app looks for repeating themes in wounds, protectors, and core beliefs. From there it makes a best guess about which patterns are most active right now.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Your primary archetype is the pattern that seems to be leading most often. A secondary pattern can show up in the background—another flavor your system reaches for when things get intense.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                // List of all archetypes
                VStack(alignment: .leading, spacing: 12) {
                    Text("The archetypes")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("You might recognize pieces of more than one. That’s normal—most people do.")
                        .font(.caption)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    ForEach(ShadowArchetype.allCases) { archetype in
                        ArchetypeLearnMoreRow(archetype: archetype)
                    }
                }
                .shadowCard()

                // How to relate to this
                VStack(alignment: .leading, spacing: 8) {
                    Text("How to work with this")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    Text("• Let this be language, not a verdict.\n• Notice where the description lands as \"oh, that’s me\" versus \"not so much\".\n• Use it to track patterns over time, not to judge yourself.\n• Remember: these patterns formed to protect you. Curiosity is more helpful than blame.")
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("You’re allowed to grow beyond any of these patterns. The goal isn’t to get rid of your shadow, but to know it well enough that it doesn’t have to run the show.")
                        .font(.caption2)
                        .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .shadowCard()

                Spacer()
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("About archetypes")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ArchetypeLearnMoreRow: View {
    let archetype: ShadowArchetype

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(archetype.iconName)
                .resizable()
                .renderingMode(.template)
                .foregroundColor(MSTheme.primaryText)
                .scaledToFit()
                .frame(width: 36, height: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(archetype.rawValue)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(MSTheme.primaryText)

                Text(archetype.tagline)
                    .font(.caption)
                    .foregroundColor(MSTheme.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)

                Text(archetype.longDescription)
                    .font(.caption2)
                    .foregroundColor(MSTheme.secondaryText.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
        }
    }
}

 // MARK: - Latest Reflection

struct LatestReflectionCard: View {
    let latestInsight: ShadowInsight?
    @State private var isExpanded = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Latest reflection")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            if let summary = latestInsight?.summary, !summary.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(summary)
                        .font(.footnote)
                        .foregroundColor(MSTheme.secondaryText)
                        .lineLimit(isExpanded ? nil : 2)
                        .fixedSize(horizontal: false, vertical: isExpanded)
                    
                    if !isExpanded && summary.count > 100 {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isExpanded = true
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text("Read more")
                                    .font(.caption.weight(.semibold))
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                            }
                            .foregroundColor(MSTheme.primaryText.opacity(0.8))
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                Text("Once you've logged a few activations, your AI reflections will show up here.")
                    .font(.footnote)
                    .foregroundColor(MSTheme.secondaryText)
            }
        }
        .shadowCard()
    }
}

 // MARK: - Why this works

struct WhyItWorksCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Why music reveals patterns")
                .font(.headline)
                .foregroundColor(MSTheme.secondaryText)

            Text("Music taps into memory, emotion, and body all at once. By logging the spikes, you’re building a map of how your nervous system responds—and giving your shadow a language.")
                .font(.caption)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)

            NavigationLink {
                WhyItWorksView()
            } label: {
                HStack(spacing: 6) {
                    Text("Learn the science behind it")
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
                .font(.footnote.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(Color.white.opacity(0.06))
                )
            }
            .buttonStyle(.plain)
        }
        .shadowCard()
    }
}

 // MARK: - Supabase loading

private extension ContentView {
    func loadEvents() async {
        let client = SupabaseClientManager.shared.client
        guard let session = client.auth.currentSession else {
            await MainActor.run {
                errorMessage = "No active user session."
                isLoading = false
            }
            return
        }
        let userId = session.user.id

        // Check cache first (only for this user)
        if let cached = DataCache.shared.getCachedEvents(userId: userId) {
            DebugMode.shared.log("Using cached events (\(cached.count) items)", category: "Cache")
            await MainActor.run {
                events = cached
                isLoading = false
                errorMessage = nil
            }
            return
        }
        
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            DebugMode.shared.log("Loading events from Supabase for user \(userId)", category: "Data")
            
            let result: [SongEvent] = try await client
                .from("song_events")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Cache the result for this user
            DataCache.shared.setCachedEvents(result, userId: userId)
            DebugMode.shared.log("Loaded \(result.count) events and cached", category: "Data")

            await MainActor.run {
                events = result
                isLoading = false
            }
        } catch {
            DebugMode.shared.log("Error loading events: \(error.localizedDescription)", category: "Error")
            await MainActor.run {
                errorMessage = "We couldn't load your activations. Please try again."
                isLoading = false
            }
        }
    }

    func loadInsights() async {
        let client = SupabaseClientManager.shared.client
        guard let session = client.auth.currentSession else { return }
        let userId = session.user.id

        // Check cache first (only for this user)
        if let cached = DataCache.shared.getCachedInsights(userId: userId) {
            DebugMode.shared.log("Using cached insights (\(cached.count) items)", category: "Cache")
            await MainActor.run {
                insights = cached
            }
            return
        }
        
        do {
            DebugMode.shared.log("Loading insights from Supabase for user \(userId)", category: "Data")
            
            let result: [ShadowInsight] = try await client
                .from("shadow_insights")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            // Cache the result for this user
            DataCache.shared.setCachedInsights(result, userId: userId)
            DebugMode.shared.log("Loaded \(result.count) insights and cached", category: "Data")

            await MainActor.run {
                insights = result
            }
        } catch {
            DebugMode.shared.log("Error loading insights: \(error.localizedDescription)", category: "Error")
        }
    }
    
    // MARK: - Helper Methods
    
    /// Events from the last 7 days
    var eventsThisWeek: [SongEvent] {
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        return events.filter { event in
            guard let createdAt = event.created_at,
                  let date = formatter.date(from: createdAt) else {
                return false
            }
            return date >= oneWeekAgo
        }
    }
    
    /// Select the most relevant insight to feature
    func selectFeaturedInsight() -> ShadowInsight? {
        // Prioritize:
        // 1. Most recent insight (if < 24 hours old)
        // 2. Insight with highest archetype match score
        // 3. Random insight from last 30 days
        
        guard !insights.isEmpty else { return nil }
        
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        
        // Check for recent insights
        if let firstInsight = insights.first,
           let createdAt = firstInsight.created_at,
           let date = formatter.date(from: createdAt) {
            let hoursSince = Date().timeIntervalSince(date) / 3600
            if hoursSince < 24 {
                return firstInsight
            }
        }
        
        // Otherwise return most recent
        return insights.first
    }
}
