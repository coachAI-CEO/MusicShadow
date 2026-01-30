import SwiftUI

/// Milestone celebration view shown when user reaches trigger count milestones
struct MilestoneCelebrationView: View {
    let milestoneCount: Int
    let onDismiss: () -> Void
    
    private var milestoneMessage: String {
        switch milestoneCount {
        case 1:
            return "You've taken the first step toward deeper self-awareness"
        case 5:
            return "Patterns are beginning to emerge"
        case 10:
            return "Your shadow work practice is taking root"
        case 25:
            return "You're building a meaningful practice"
        case 50:
            return "Incredible dedication to your healing journey"
        case 100:
            return "A century of self-awareness moments"
        default:
            return "You've reached \(milestoneCount) triggers!"
        }
    }
    
    private var celebrationEmoji: String {
        switch milestoneCount {
        case 1: return "🌟"
        case 5: return "✨"
        case 10: return "💫"
        case 25: return "🎉"
        case 50: return "🎊"
        case 100: return "🏆"
        default: return "🎈"
        }
    }
    
    var body: some View {
        ZStack {
            // Semi-transparent background
            Color.black.opacity(0.6)
                .ignoresSafeArea()
                .onTapGesture {
                    onDismiss()
                }
            
            VStack(spacing: 24) {
                // Celebration emoji
                Text(celebrationEmoji)
                    .font(.system(size: 80))
                    .scaleEffect(1.2)
                
                // Milestone count
                Text("\(milestoneCount) Triggers Logged!")
                    .font(MSTheme.Typography.title.bold())
                    .foregroundColor(MSTheme.Colors.primaryText)
                    .multilineTextAlignment(.center)
                
                // Milestone message
                Text(milestoneMessage)
                    .font(MSTheme.Typography.body)
                    .foregroundColor(MSTheme.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                
                // Dismiss button
                Button(action: onDismiss) {
                    Text("Continue")
                        .font(MSTheme.Typography.headline.weight(.semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: MSTheme.CornerRadius.md, style: .continuous)
                                .fill(MSTheme.accentGradient)
                        )
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 32)
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                    .fill(MSTheme.Colors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: MSTheme.CornerRadius.xl, style: .continuous)
                            .stroke(MSTheme.Colors.cardStroke, lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            .padding(40)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.9)))
    }
}

// MARK: - Milestone Tracker

struct MilestoneTracker {
    private static let milestoneKey = "celebratedMilestones"
    
    /// Check if a milestone should be celebrated and mark it as celebrated
    static func checkAndCelebrateMilestone(triggerCount: Int) -> Int? {
        let milestones = [1, 5, 10, 25, 50, 100]
        
        // Check if this count is a milestone
        guard milestones.contains(triggerCount) else {
            return nil
        }
        
        // Check if we've already celebrated this milestone
        let celebrated = getCelebratedMilestones()
        if celebrated.contains(triggerCount) {
            return nil
        }
        
        // Mark as celebrated
        var updated = celebrated
        updated.insert(triggerCount)
        setCelebratedMilestones(updated)
        
        return triggerCount
    }
    
    /// Get set of already celebrated milestones
    private static func getCelebratedMilestones() -> Set<Int> {
        if let data = UserDefaults.standard.data(forKey: milestoneKey),
           let array = try? JSONDecoder().decode([Int].self, from: data) {
            return Set(array)
        }
        return []
    }
    
    /// Save set of celebrated milestones
    private static func setCelebratedMilestones(_ milestones: Set<Int>) {
        let array = Array(milestones).sorted()
        if let data = try? JSONEncoder().encode(array) {
            UserDefaults.standard.set(data, forKey: milestoneKey)
        }
    }
    
    /// Reset milestones (for testing)
    static func resetMilestones() {
        UserDefaults.standard.removeObject(forKey: milestoneKey)
    }
}

// MARK: - Preview

#Preview {
    MilestoneCelebrationView(milestoneCount: 10) {
        print("Dismissed")
    }
}
