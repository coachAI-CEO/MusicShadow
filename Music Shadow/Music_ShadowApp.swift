import SwiftUI

@main
struct Music_ShadowApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            AuthView()
                .onAppear {
                    if !hasSeenOnboarding {
                        showOnboarding = true
                    }
                }
                .fullScreenCover(isPresented: $showOnboarding) {
                    OnboardingView()
                }
                .onReceive(NotificationCenter.default.publisher(for: .showOnboarding)) { _ in
                    showOnboarding = true
                }
        }
    }
}
