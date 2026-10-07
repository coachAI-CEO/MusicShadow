import Foundation

// Pure helpers for the send flow. No UIKit or network here so they are unit tested.

/// Note length rules. Postgres `char_length` counts Unicode code points, so the client counts
/// unicode scalars (not Swift Characters) to keep client and database caps identical.
enum NoteRules {
    static let maxScalars = 500
    static let warnAtScalars = 400

    static func scalarCount(_ text: String) -> Int {
        text.unicodeScalars.count
    }

    /// Truncates to `maxScalars` on a scalar boundary, dropping a dangling zero-width joiner.
    static func clamp(_ text: String, to limit: Int = maxScalars) -> String {
        guard scalarCount(text) > limit else { return text }
        var scalars = Array(text.unicodeScalars.prefix(limit))
        while let last = scalars.last, last.value == 0x200D { scalars.removeLast() }
        var view = String.UnicodeScalarView()
        view.append(contentsOf: scalars)
        return String(view)
    }

    static func isSendable(_ text: String) -> Bool {
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && scalarCount(text) <= maxScalars
    }
}

/// The five starter prompts. Inserted only on tap, never auto-filled.
enum StarterPrompts {
    static let all: [String] = [
        "What did your body do when it started?",
        "What does this song say that I can't?",
        "What do I wish you knew?",
        "What memory or moment is this?",
        "What do I want you to feel hearing it?"
    ]

    /// Appends a prompt on a new line (SwiftUI's TextEditor exposes no cursor position).
    static func insert(_ prompt: String, into note: String) -> String {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        let combined = trimmed.isEmpty ? prompt + " " : note + (note.hasSuffix("\n") ? "" : "\n") + prompt + " "
        return NoteRules.clamp(combined)
    }
}

enum AppleMusicLink {
    /// Normalizes an iTunes Search store link to a clean https://music.apple.com link, or nil.
    static func normalize(_ raw: String?) -> URL? {
        guard let raw, var comps = URLComponents(string: raw), comps.scheme == "https" else { return nil }
        guard let host = comps.host?.lowercased() else { return nil }
        guard host == "music.apple.com" || host == "itunes.apple.com" else { return nil }
        comps.host = "music.apple.com"
        comps.queryItems = comps.queryItems?.filter { $0.name != "uo" }
        if comps.queryItems?.isEmpty == true { comps.queryItems = nil }
        return comps.url
    }

    /// Fallback when there is no match: Apple Music search for the title and artist.
    static func searchURL(title: String, artist: String) -> URL? {
        var comps = URLComponents(string: "https://music.apple.com/search")
        comps?.queryItems = [URLQueryItem(name: "term", value: "\(title) \(artist)".trimmingCharacters(in: .whitespaces))]
        return comps?.url
    }

    /// Spotify search link, built at render time and never stored. Lands on search results.
    static func spotifySearchURL(title: String, artist: String) -> URL? {
        let term = "\(title) \(artist)".trimmingCharacters(in: .whitespaces)
        guard let encoded = term.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed.subtracting(CharacterSet(charactersIn: "/"))) else { return nil }
        return URL(string: "https://open.spotify.com/search/\(encoded)")
    }
}

enum ShareMessage {
    static let maxSignatureScalars = 40

    /// Phase 0 message: the sender's own words first, then an optional signature, then the song and a link.
    /// The review screen shows exactly this string, and exactly this string is handed to the share sheet.
    static func build(note: String, title: String, artist: String, link: URL?, signature: String? = nil) -> String {
        var lines: [String] = [note.trimmingCharacters(in: .whitespacesAndNewlines)]
        if let name = cleanSignature(signature) { lines.append("\u{2014} \(name)") }
        lines.append("")
        lines.append(artist.isEmpty ? "\"\(title)\"" : "\"\(title)\" by \(artist)")
        if let link { lines.append(link.absoluteString) }
        return lines.joined(separator: "\n")
    }

    /// Trimmed, single-line, capped at 40 Unicode scalars; nil when empty.
    static func cleanSignature(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let oneLine = raw.replacingOccurrences(of: "\n", with: " ").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !oneLine.isEmpty else { return nil }
        return NoteRules.clamp(oneLine, to: maxSignatureScalars)
    }
}

/// The plain-language disclosure on the review screen: what is shared, when, to whom, and for how long.
/// Phase 0 sends an ordinary message, so the honest answer to "how long" is: it can't be turned off.
enum ShareDisclosure {
    static let whatTitle = "What you're sharing"
    static let notSharedTitle = "What stays private"
    static let notShared = "Your AI reflection, your journal entries, your body and intensity ratings, and your other songs. Only the message above leaves the app."
    static let whenTitle = "When it goes"
    static let when = "Nothing is sent yet. Next you pick who gets it in the share sheet, and it goes only when you send it there."
    static let howLongTitle = "How long"
    static let howLong = "It's a normal message. It stays in their chat until they delete it, and you can't turn it off or take it back once it's sent."
    static let linkNote = "The link doesn't expire. It opens Apple Music, so people who use Spotify may not be able to play the full song."

    static func linkDescription(matched: Bool) -> String {
        matched
            ? "Link: opens this song in Apple Music."
            : "Link: searches Apple Music for this song. We couldn't find an exact match."
    }
}

/// Labels for the insight chips. A positive hit reads as what opened, not as a wound.
enum InsightLabels {
    struct Set { let first: String; let second: String; let third: String }

    static func labels(forValence valence: String?) -> Set {
        (valence ?? "").lowercased() == "positive"
            ? Set(first: "Opened", second: "Receives it as", third: "Affirms")
            : Set(first: "Wound", second: "Protector", third: "Belief")
    }
}
