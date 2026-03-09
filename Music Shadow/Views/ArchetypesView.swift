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

    private var activeEvents: [SongEvent] {
        events.isEmpty ? localEvents : events
    }
    
    private var activeInsights: [ShadowInsight] {
        insights.isEmpty ? localInsights : insights
    }
    
    private var archetypeScores: [ArchetypeScore] {
        ArchetypeEngine.scores(from: activeInsights, events: activeEvents)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                
                // HEADER
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Archetypes")
                        .font(.largeTitle.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("The protective patterns your nervous system uses most often.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
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
                
                // OTHER ARCHETYPES GRID
                VStack(alignment: .leading, spacing: 12) {
                    Text("All Archetypes")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        ForEach(ShadowArchetype.allCases) { archetype in
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
        
        // Get current user ID to access cache
        guard let userId = SupabaseClientManager.shared.client.auth.currentSession?.user.id else {
            isLoading = false
            return
        }
        
        if let cachedEvents = DataCache.shared.getCachedEvents(userId: userId) {
            localEvents = cachedEvents
        }
        if let cachedInsights = DataCache.shared.getCachedInsights(userId: userId) {
            localInsights = cachedInsights
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
                Image(archetype.iconName)
                    .resizable()
                    .renderingMode(.template)
                    .foregroundColor(isPrimary ? MSTheme.Colors.accentPrimary : MSTheme.primaryText)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: 40)
                
                if score > 0 {
                    Text("\(score)")
                        .font(.caption2.bold())
                        .foregroundColor(.black)
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
