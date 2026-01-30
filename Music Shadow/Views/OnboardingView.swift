import SwiftUI

/// First-time user onboarding flow
struct OnboardingView: View {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var currentPage: Int = 0
    
    // Onboarding pages data
    private let pages: [(title: String, body: String)] = [
        (
            title: "Music reveals patterns",
            body: "Music can activate memories, emotions, and body sensations before words ever form.\n\nMusic Shadow helps you notice those moments."
        ),
        (
            title: "Log the moment",
            body: "When a song hits — in your chest, stomach, breath, or mood — log it.\n\nYou don't need the full story. Just the signal."
        ),
        (
            title: "Reflection, not diagnosis",
            body: "AI reflections help you understand patterns with compassion.\n\nThey do not label, judge, or replace therapy."
        ),
        (
            title: "Your data stays yours",
            body: "Your entries are private by default.\n\nSharing with a partner is always optional — and reversible."
        )
    ]
    
    var body: some View {
        ZStack {
            // Background gradient
            MSTheme.bgGradient
                .ignoresSafeArea()
            
            // Animated background elements
            OnboardingAnimatedBackground()
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Skip button (always visible)
                HStack {
                    Spacer()
                    Button {
                        completeOnboarding()
                    } label: {
                        Text("Skip")
                            .font(.subheadline)
                            .foregroundColor(MSTheme.secondaryText)
                            .frame(minHeight: 44) // Accessibility: minimum tap target
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                    }
                    .accessibilityLabel("Skip onboarding")
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                
                // Page content
                TabView(selection: $currentPage) {
                    ForEach(0..<pages.count, id: \.self) { index in
                        OnboardingPageView(
                            title: pages[index].title,
                            bodyText: pages[index].body
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                .onAppear {
                    // Customize page indicator appearance
                    UIPageControl.appearance().currentPageIndicatorTintColor = .white
                    UIPageControl.appearance().pageIndicatorTintColor = UIColor.white.withAlphaComponent(0.3)
                }
                
                // Action button
                VStack(spacing: 16) {
                    if currentPage == pages.count - 1 {
                        // Final page: "Get Started" button
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Get Started")
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
                        .accessibilityLabel("Get Started")
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    } else {
                        // Other pages: show page indicator only
                        // (TabView handles the dots, but we add spacing)
                        Spacer()
                            .frame(height: 20)
                    }
                }
            }
        }
    }
    
    private func completeOnboarding() {
        hasSeenOnboarding = true
    }
}

