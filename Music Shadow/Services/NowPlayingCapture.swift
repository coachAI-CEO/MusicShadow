import AVFoundation
import Foundation
import MediaPlayer
import ShazamKit

/// A song the app identified without the user typing it.
struct CapturedSong: Equatable {
    enum Source: String {
        case appleMusic = "Apple Music"
        case shazam = "Shazam"
    }

    let title: String
    let artist: String
    /// Seconds into the track at capture time, or nil when the source cannot tell.
    let seconds: Int?
    let source: Source

    /// Trims the text, drops songs with no title, and keeps the position inside the form's slider range.
    static func make(title: String?, artist: String?, seconds: TimeInterval?, source: Source, maxSeconds: Int = 1200) -> CapturedSong? {
        let cleanTitle = (title ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty else { return nil }
        let cleanArtist = (artist ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        var position: Int?
        if let seconds, seconds.isFinite, seconds >= 0 {
            position = min(Int(seconds), maxSeconds)
        }
        return CapturedSong(title: cleanTitle, artist: cleanArtist, seconds: position, source: source)
    }
}

enum CaptureOutcome: Equatable {
    case song(CapturedSong)
    case nothing
    /// A permission is off. The text says which and what to do.
    case denied(String)

    /// What to tell the person when no song was found.
    var message: String? {
        switch self {
        case .song: return nil
        case .nothing: return "Couldn't tell what's playing. You can type the song in."
        case .denied(let why): return why
        }
    }
}

protocol NowPlayingSource {
    func capture() async -> CaptureOutcome
}

/// Tries each source in order and returns the first song found. A source that is turned off or finds
/// nothing never stops the next one; a permission problem is only reported if no source found a song.
struct NowPlayingCapturer {
    let sources: [any NowPlayingSource]

    static var live: NowPlayingCapturer {
        var sources: [any NowPlayingSource] = [AppleMusicNowPlayingSource()]
        if FeatureFlags.shazamCapture { sources.append(ShazamNowPlayingSource()) }
        return NowPlayingCapturer(sources: sources)
    }

    func capture() async -> CaptureOutcome {
        var firstDenial: String?
        for source in sources {
            switch await source.capture() {
            case .song(let song): return .song(song)
            case .denied(let why): firstDenial = firstDenial ?? why
            case .nothing: continue
            }
        }
        if let firstDenial { return .denied(firstDenial) }
        return .nothing
    }
}

// MARK: - Apple Music

/// Reads what the Music app is playing right now. Spotify and other apps are not visible here.
struct AppleMusicNowPlayingSource: NowPlayingSource {
    func capture() async -> CaptureOutcome {
        var status = MPMediaLibrary.authorizationStatus()
        if status == .notDetermined {
            status = await MPMediaLibrary.requestAuthorization()
        }
        guard status == .authorized else {
            return .denied("Apple Music access is off. You can turn it on in Settings.")
        }

        let player = MPMusicPlayerController.systemMusicPlayer
        // Only a song that is playing counts. A paused or stale item could be from yesterday.
        guard player.playbackState == .playing, let item = player.nowPlayingItem else { return .nothing }
        guard let song = CapturedSong.make(
            title: item.title,
            artist: item.artist,
            seconds: player.currentPlaybackTime,
            source: .appleMusic
        ) else { return .nothing }
        return .song(song)
    }
}

// MARK: - Shazam

/// Listens through the microphone for a few seconds and asks Shazam what it heard. Works for any app,
/// including Spotify. Needs the ShazamKit App Service on the App ID.
struct ShazamNowPlayingSource: NowPlayingSource {
    var listenLimit: Duration = .seconds(12)

    func capture() async -> CaptureOutcome {
        var granted = AVAudioApplication.shared.recordPermission == .granted
        if AVAudioApplication.shared.recordPermission == .undetermined {
            granted = await AVAudioApplication.requestRecordPermission()
        }
        guard granted else {
            return .denied("Microphone access is off. You can turn it on in Settings.")
        }

        let session = SHManagedSession()
        let limit = listenLimit
        let timeout = Task {
            try? await Task.sleep(for: limit)
            session.cancel()
        }
        defer { timeout.cancel() }

        let result = await session.result()
        guard case .match(let match) = result, let item = match.mediaItems.first else { return .nothing }
        guard let song = CapturedSong.make(
            title: item.title,
            artist: item.artist,
            seconds: item.predictedCurrentMatchOffset,
            source: .shazam
        ) else { return .nothing }
        return .song(song)
    }
}
