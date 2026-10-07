import SwiftUI
import Supabase

struct ArchetypesView: View {
    // Data passed from parent or loaded locally
    var events: [SongEvent] = []
    var insights: [ShadowInsight] = []

    // State for local loading if needed
    @State private var localEvents: [SongEvent] = []
    @State private var localInsights: [ShadowInsight] = []
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    private var activeEvents: [SongEvent] {
        events.isEmpty ? localEvents : events
    }
    
    private var activeInsights: [ShadowInsight] {
        insights.isEmpty ? localInsights : insights
    }
    
    private var archetypeScores: [ArchetypeScore] {
        ArchetypeEngine.scores(from: activeInsights, events: activeEvents)
    }

    private var lightScores: [ArchetypeScore] {
        ArchetypeEngine.lightScores(from: activeInsights, events: activeEvents)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Archetypes")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("The protective patterns your nervous system uses most often, and the songs that lift you.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                }
                
                if let errorMessage {
                    Text(errorMessage)
                        .font(.callout)
                        .foregroundColor(MSTheme.Colors.error)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .shadowCard()
                } else if isLoading && archetypeScores.isEmpty {
                    HStack(spacing: 10) {
                        ProgressView().tint(MSTheme.secondaryText)
                        Text("Reading your patterns…")
                            .font(.callout)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .shadowCard()
                }

                // PRIMARY ARCHETYPE CARD
                if let primary = archetypeScores.first {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Primary Pattern")
                                .font(.headline)
                                .foregroundColor(MSTheme.Colors.accentPrimary)
                            Spacer()
                            Text("\(primary.score) matches")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText)
                        }
                        
                        NavigationLink(destination: ShadowArchetypeDetailView(archetype: primary.archetype)) {
                            HeroArchetypeCard(archetype: ArchetypeSummary(archetype: primary.archetype, isConfident: primary.score >= 3))
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Text("This appears to be your go-to response when triggered.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                } else {
                    Text("Log more activations to reveal your primary pattern.")
                        .font(.body)
                        .foregroundColor(MSTheme.secondaryText)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .shadowCard()
                }
                
                // LIGHT ARCHETYPE (from positive hits)
                if let light = lightScores.first {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("What lifts you")
                                .font(.headline)
                                .foregroundColor(MSTheme.Colors.accentPrimary)
                            Spacer()
                            Text("\(light.score) matches")
                                .font(.caption2)
                                .foregroundColor(MSTheme.secondaryText)
                        }

                        NavigationLink(destination: ShadowArchetypeDetailView(archetype: light.archetype)) {
                            HStack(alignment: .top, spacing: 16) {
                                ArchetypeIcon(archetype: light.archetype, size: 56)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(light.archetype.rawValue)
                                        .font(.title3.weight(.semibold))
                                        .foregroundColor(MSTheme.primaryText)
                                    Text(light.archetype.tagline)
                                        .font(.footnote)
                                        .foregroundColor(MSTheme.secondaryText)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(20)
                            .shadowCard()
                        }
                        .buttonStyle(PlainButtonStyle())

                        Text("From your positive hits: the songs that open, free or connect you.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText)
                    }
                }

                // SHADOW ARCHETYPES GRID
                VStack(alignment: .leading, spacing: 12) {
                    Text("Shadow archetypes")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ShadowArchetype.shadowCases) { archetype in
                            NavigationLink(destination: ShadowArchetypeDetailView(archetype: archetype)) {
                                ArchetypeGridItem(
                                    archetype: archetype,
                                    score: archetypeScores.first(where: { $0.archetype == archetype })?.score ?? 0,
                                    isPrimary: archetypeScores.first?.archetype == archetype
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // LIGHT ARCHETYPES GRID
                VStack(alignment: .leading, spacing: 12) {
                    Text("Light archetypes")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ShadowArchetype.lightCases) { archetype in
                            NavigationLink(destination: ShadowArchetypeDetailView(archetype: archetype)) {
                                ArchetypeGridItem(
                                    archetype: archetype,
                                    score: lightScores.first(where: { $0.archetype == archetype })?.score ?? 0,
                                    isPrimary: lightScores.first?.archetype == archetype
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }

                // LEARN MORE
                NavigationLink(destination: ShadowArchetypeLearnMoreView()) {
                    HStack {
                        Text("Learn more about archetypes")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.caption)
                    }
                    .foregroundColor(MSTheme.Colors.accentPrimary)
                    .padding()
                    .background(Color.white.opacity(0.04))
                    .cornerRadius(12)
                }
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Archetypes")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            if events.isEmpty && insights.isEmpty {
                await loadData()
            }
        }
    }
    
    private func loadData() async {
        isLoading = true
        errorMessage = nil

        // Get current user ID to access cache and scope network queries
        guard let userId = SupabaseClientManager.shared.client.auth.currentSession?.user.id else {
            isLoading = false
            errorMessage = "Please sign in to see your archetypes."
            return
        }

        let client = SupabaseClientManager.shared.client

        // Try cache first
        if let cachedEvents = DataCache.shared.getCachedEvents(userId: userId) {
            localEvents = cachedEvents
        }
        if let cachedInsights = DataCache.shared.getCachedInsights(userId: userId) {
            localInsights = cachedInsights
        }

        // Cache hit on both → done
        if !localEvents.isEmpty || !localInsights.isEmpty {
            isLoading = false
            return
        }

        // Cache miss → fetch directly so users who deep-link to Archetypes
        // before visiting the Dashboard still see real data.
        do {
            async let eventsFetch: [SongEvent] = client
                .from("song_events")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            async let insightsFetch: [ShadowInsight] = client
                .from("shadow_insights")
                .select()
                .eq("user_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value

            let (fetchedEvents, fetchedInsights) = try await (eventsFetch, insightsFetch)

            // Backfill the cache so subsequent reads are fast.
            DataCache.shared.setCachedEvents(fetchedEvents, userId: userId)
            DataCache.shared.setCachedInsights(fetchedInsights, userId: userId)

            localEvents = fetchedEvents
            localInsights = fetchedInsights
        } catch {
            DebugMode.shared.log("ArchetypesView direct fetch failed: \(error.localizedDescription)", category: "Error")
            errorMessage = "We couldn't load your archetypes. Please try again."
        }

        isLoading = false
    }
}

struct ArchetypeGridItem: View {
    let archetype: ShadowArchetype
    let score: Int
    let isPrimary: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack(alignment: .topTrailing) {
                ArchetypeIcon(archetype: archetype, size: 40, color: isPrimary ? MSTheme.Colors.accentPrimary : MSTheme.primaryText)
                
                if score > 0 {
                    Text("\(score)")
                        .font(.caption2.bold())
                        .foregroundColor(.white)
                        .padding(4)
                        .background(Circle().fill(MSTheme.Colors.accentPrimary))
                        .offset(x: 8, y: -8)
                }
            }
            
            Text(archetype.rawValue)
                .font(.caption.weight(.semibold))
                .foregroundColor(MSTheme.primaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isPrimary ? Color.white.opacity(0.1) : Color.white.opacity(0.04))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isPrimary ? MSTheme.Colors.accentPrimary.opacity(0.5) : Color.clear, lineWidth: 1)
        )
    }
}
