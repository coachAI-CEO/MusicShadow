import SwiftUI

/// Reusable page component for onboarding flow
struct OnboardingPageView: View {
    let title: String
    let bodyText: String
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            VStack(spacing: 20) {
                // Emblem as a soft anchor at the top of each onboarding page
                MusicShadowEmblem(size: 40)
                    .opacity(0.9)
                
                VStack(alignment: .leading, spacing: 16) {
                    Text(title)
                        .font(.title.bold())
                        .foregroundColor(MSTheme.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(bodyText)
                        .font(.body)
                        .foregroundColor(MSTheme.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(6)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

