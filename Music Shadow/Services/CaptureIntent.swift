import AppIntents
import Foundation

extension Notification.Name {
    static let captureNowPlayingRequested = Notification.Name("captureNowPlayingRequested")
}

/// Remembers that the Action Button, Siri or a Shortcut asked for a capture, so a cold launch that is still
/// behind the sign-in screen does not lose the request.
@MainActor
final class CaptureRequest {
    static let shared = CaptureRequest()
    var isPending = false

    /// Returns true once per request.
    func consume() -> Bool {
        defer { isPending = false }
        return isPending
    }
}

struct LogNowPlayingIntent: AppIntent {
    static let title: LocalizedStringResource = "Log the song that's playing"
    static let description = IntentDescription("Opens Music Shadow and fills in the song that's playing right now.")
    static let openAppWhenRun = true

    @MainActor
    func perform() async throws -> some IntentResult {
        CaptureRequest.shared.isPending = true
        NotificationCenter.default.post(name: .captureNowPlayingRequested, object: nil)
        return .result()
    }
}

struct MusicShadowShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogNowPlayingIntent(),
            phrases: [
                "Log this song in \(.applicationName)",
                "Capture this song in \(.applicationName)"
            ],
            shortTitle: "Log this song",
            systemImageName: "waveform"
        )
    }
}
