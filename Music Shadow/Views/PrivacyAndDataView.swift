import SwiftUI

struct PrivacyAndDataView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your data & privacy")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("Your data is never sold. You can delete any entry at any time. Sharing is explicit and reversible.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                
                // Data ownership
                VStack(alignment: .leading, spacing: 12) {
                    Text("Data ownership")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("You own all data you create in Music Shadow")
                        bulletPoint("Your entries, reflections, and patterns belong to you")
                        bulletPoint("We never sell your data to third parties")
                        bulletPoint("Data is stored securely using industry-standard encryption")
                        bulletPoint("You can export or delete your data at any time")
                    }
                }
                .shadowCard()
                
                // Sharing rules
                VStack(alignment: .leading, spacing: 12) {
                    Text("Sharing rules")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("All entries are private by default")
                        bulletPoint("Sharing with a partner is completely optional")
                        bulletPoint("You choose which triggers to share using the \"Share with partner\" toggle")
                        bulletPoint("You control what level of detail your partner sees (Minimal or Full)")
                        bulletPoint("You can unshare any trigger at any time")
                        bulletPoint("Unlinking a partner immediately stops all sharing")
                    }
                }
                .shadowCard()
                
                // Deletion rights
                VStack(alignment: .leading, spacing: 12) {
                    Text("Deletion rights")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("You can delete any logged activation at any time")
                        bulletPoint("Deleting a trigger also removes its associated AI reflection")
                        bulletPoint("Deleting your account removes all your data permanently")
                        bulletPoint("There is no recovery period — deletion is immediate and final")
                        bulletPoint("Shared data is removed from partner views when you delete it")
                    }
                }
                .shadowCard()
                
                // Technical details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Technical details")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Data is stored in Supabase, a secure cloud database")
                        bulletPoint("Authentication uses industry-standard OAuth and JWT tokens")
                        bulletPoint("AI processing happens via Google's Gemini API")
                        bulletPoint("No data is shared with AI providers beyond what's needed for reflection generation")
                        bulletPoint("All API calls are encrypted in transit")
                    }
                }
                .shadowCard()
                
                // Note
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "lock.shield.fill")
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                            .font(.caption)
                        
                        Text("Your privacy is fundamental to Music Shadow. We're committed to transparency about how your data is used and protected.")
                            .font(.caption)
                            .foregroundColor(MSTheme.secondaryText.opacity(0.9))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(Color.white.opacity(0.04))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(MSTheme.cardStroke, lineWidth: 1)
                )
            }
            .padding(24)
        }
        .musicShadowBackground()
        .navigationTitle("Privacy & data")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(MSTheme.secondaryText)
                .font(.body)
            Text(text)
                .font(.body)
                .foregroundColor(MSTheme.secondaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}


