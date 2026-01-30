import SwiftUI

struct HowAIWorksView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("How AI works in Music Shadow")
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)
                    
                    Text("AI reflections are supportive, not medical or diagnostic. They are generated per entry and can be regenerated or ignored.")
                        .font(.subheadline)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.top, 8)
                
                // What AI does
                VStack(alignment: .leading, spacing: 12) {
                    Text("What AI does")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Helps you notice patterns across your logged activations")
                        bulletPoint("Surfaces themes related to shadow work, protector modes, and core beliefs")
                        bulletPoint("Offers gentle, compassionate reflections on your somatic experiences")
                        bulletPoint("Suggests practices that might support your awareness")
                    }
                }
                .shadowCard()
                
                // What AI does not do
                VStack(alignment: .leading, spacing: 12) {
                    Text("What AI does not do")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Provide medical advice or diagnosis")
                        bulletPoint("Replace therapy or professional mental health support")
                        bulletPoint("Judge or label your experiences")
                        bulletPoint("Make definitive claims about your past or future")
                    }
                }
                .shadowCard()
                
                // When AI runs
                VStack(alignment: .leading, spacing: 12) {
                    Text("When AI runs")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("AI reflections are generated automatically when you log a new activation")
                        bulletPoint("The process typically takes 15-30 seconds")
                        bulletPoint("You'll see a loading state while the reflection is being created")
                        bulletPoint("If generation takes longer, you can check again or regenerate later")
                    }
                }
                .shadowCard()
                
                // How to regenerate reflections
                VStack(alignment: .leading, spacing: 12) {
                    Text("How to regenerate reflections")
                        .font(.headline)
                        .foregroundColor(MSTheme.secondaryText)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        bulletPoint("Open any logged activation to view its AI reflection")
                        bulletPoint("Tap the \"Regenerate AI reflection\" button if you want a fresh perspective")
                        bulletPoint("You can regenerate as many times as you'd like")
                        bulletPoint("Each regeneration creates a new reflection, but previous ones are not deleted")
                    }
                }
                .shadowCard()
                
                // Note
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(MSTheme.secondaryText.opacity(0.8))
                            .font(.caption)
                        
                        Text("AI reflections are meant to support your self-awareness and pattern recognition. They are tools for exploration, not definitive answers.")
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
        .navigationTitle("How AI works")
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


