import SwiftUI

@main
struct Music_ShadowApp: App {
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @State private var showOnboarding = false

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if CommandLine.arguments.contains("-uiTestSendSheet") {
                // Debug-only route so UI tests can exercise the send sheet without an account.
                SendSongSheet(songTitle: "Fade Into You", artist: "Mazzy Star")
            } else if CommandLine.arguments.contains("-uiTestPartner") {
                DebugPartnerPreview()
            } else if CommandLine.arguments.contains("-uiTestArchetypes") {
                NavigationStack {
                    ArchetypesView(events: DebugSamples.events, insights: DebugSamples.insights)
                }
            } else {
                mainContent
            }
            #else
            mainContent
            #endif
        }
    }

    private var mainContent: some View {
        AuthView()
            .onAppear {
                if !hasSeenOnboarding {
                    showOnboarding = true
                }
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingView()
            }
    }
}

#if DEBUG
/// Sample data for the debug-only `-uiTestArchetypes` route. Never compiled into release builds.
enum DebugSamples {
    private static func event(_ id: UUID, valence: String, impulse: String?, somatic: String?) -> SongEvent {
        var json: [String: Any] = ["id": id.uuidString, "valence": valence, "song_title": "Sample", "artist": "Sample"]
        if let impulse { json["impulse"] = impulse }
        if let somatic { json["somatic_type"] = somatic }
        let data = try! JSONSerialization.data(withJSONObject: json)
        return try! JSONDecoder().decode(SongEvent.self, from: data)
    }

    private static let ids = (0..<4).map { _ in UUID() }

    static var events: [SongEvent] {
        [event(ids[0], valence: "positive", impulse: "cling", somatic: "urgeCry"),
         event(ids[1], valence: "positive", impulse: "scream", somatic: "burning"),
         event(ids[2], valence: "shadow", impulse: "hide", somatic: "tight"),
         event(ids[3], valence: "shadow", impulse: "cry", somatic: "heavy")]
    }

    static var insights: [ShadowInsight] {
        func make(_ i: Int, _ wound: String, _ summary: String) -> ShadowInsight {
            ShadowInsight(id: UUID(), event_id: ids[i], user_id: UUID(), created_at: nil,
                          wound_type: wound, protector_mode: nil, age_range: nil, nervous_system: nil,
                          core_belief: nil, summary: summary, suggested_practice: nil)
        }
        return [make(0, "Belonging", "It made you think of your partner and feel connected and held."),
                make(1, "Joy", "Pure delight, you wanted to dance and sing."),
                make(2, "Fear of abandonment", "You felt abandoned and alone."),
                make(3, "Not enough", "A sense of never being enough.")]
    }
}
#endif
