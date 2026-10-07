import Foundation

struct ITunesMatch: Equatable {
    let trackName: String
    let artistName: String
    let storeURL: URL?
    let previewURL: URL?
}

/// iTunes Search lookup for a play link. No auth needed; MusicKit search stays disabled
/// (see MusicSearchService). Times out quickly so sending never waits on it.
enum ITunesSearchService {
    static func lookup(title: String, artist: String, timeout: TimeInterval = 3) async -> ITunesMatch? {
        let term = "\(title) \(artist)".trimmingCharacters(in: .whitespaces)
        guard !term.isEmpty else { return nil }
        var comps = URLComponents(string: "https://itunes.apple.com/search")
        comps?.queryItems = [
            URLQueryItem(name: "term", value: term),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "3")
        ]
        guard let url = comps?.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            return parse(data)
        } catch {
            return nil
        }
    }

    /// Length of the song in seconds, or nil unless a result clearly is the same song. Live cuts, remixes and
    /// other versions have different lengths, so a loose match is worse than no answer.
    static func duration(title: String, artist: String, timeout: TimeInterval = 4) async -> Int? {
        let cleanTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanArtist = artist.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanTitle.isEmpty, !cleanArtist.isEmpty else { return nil }
        var comps = URLComponents(string: "https://itunes.apple.com/search")
        comps?.queryItems = [
            URLQueryItem(name: "term", value: "\(cleanTitle) \(cleanArtist)"),
            URLQueryItem(name: "entity", value: "song"),
            URLQueryItem(name: "limit", value: "10")
        ]
        guard let url = comps?.url else { return nil }
        var request = URLRequest(url: url)
        request.timeoutInterval = timeout
        guard let (data, _) = try? await URLSession.shared.data(for: request) else { return nil }
        return matchingDuration(in: data, title: cleanTitle, artist: cleanArtist)
    }

    static func matchingDuration(in data: Data, title: String, artist: String) -> Int? {
        struct Response: Decodable {
            struct Item: Decodable {
                let trackName: String?
                let artistName: String?
                let trackTimeMillis: Int?
            }
            let results: [Item]
        }
        guard let response = try? JSONDecoder().decode(Response.self, from: data) else { return nil }
        for item in response.results {
            guard let name = item.trackName, let by = item.artistName, let millis = item.trackTimeMillis,
                  sameTitle(name, title), sameArtist(by, artist) else { continue }
            let seconds = Int((Double(millis) / 1000).rounded())
            if (10...7200).contains(seconds) { return seconds }
        }
        return nil
    }

    /// Case, accents, punctuation and a "Remastered" tag are ignored. "(Live)" or "- Remix" are not.
    static func sameTitle(_ a: String, _ b: String) -> Bool {
        let x = normalizedTitle(a), y = normalizedTitle(b)
        return !x.isEmpty && x == y
    }

    /// One name may carry a feature credit the other leaves out, so either may contain the other.
    static func sameArtist(_ a: String, _ b: String) -> Bool {
        let x = normalizedKey(a), y = normalizedKey(b)
        guard !x.isEmpty, !y.isEmpty else { return false }
        return x == y || x.contains(y) || y.contains(x)
    }

    private static func normalizedTitle(_ s: String) -> String {
        var t = s.lowercased()
        t = t.replacingOccurrences(of: "\\s*[\\(\\[][^\\)\\]]*remaster[^\\)\\]]*[\\)\\]]", with: "", options: .regularExpression)
        t = t.replacingOccurrences(of: "\\s+[-–—]\\s+[^-–—]*remaster.*$", with: "", options: .regularExpression)
        return normalizedKey(t)
    }

    private static func normalizedKey(_ s: String) -> String {
        s.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
            .filter { $0.isLetter || $0.isNumber }
    }

    static func parse(_ data: Data) -> ITunesMatch? {
        struct Response: Decodable {
            struct Item: Decodable {
                let trackName: String?
                let artistName: String?
                let trackViewUrl: String?
                let previewUrl: String?
            }
            let results: [Item]
        }
        guard let response = try? JSONDecoder().decode(Response.self, from: data),
              let first = response.results.first,
              let name = first.trackName, let artist = first.artistName else { return nil }
        return ITunesMatch(
            trackName: name,
            artistName: artist,
            storeURL: AppleMusicLink.normalize(first.trackViewUrl),
            previewURL: first.previewUrl.flatMap(URL.init(string:))
        )
    }
}
