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
