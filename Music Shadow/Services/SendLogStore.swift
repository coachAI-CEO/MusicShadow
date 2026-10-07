import Foundation
import Combine

/// Phase 0 measurement log. Stored on device only; the founder reads it out after the test.
struct SendLogEntry: Identifiable, Codable, Equatable {
    var id = UUID()
    var date = Date()
    var songTitle: String
    var artist: String
    var noteLength: Int
    var matched: Bool
    var receiverPlatform: String?   // "Apple Music", "Spotify", "Other"
    var responded: Bool?
    var feltRight: Bool?
}

@MainActor
final class SendLogStore: ObservableObject {
    static let shared = SendLogStore()
    private let key = "phase0SendLog.v1"
    @Published private(set) var entries: [SendLogEntry] = []

    init() { load() }

    func add(_ entry: SendLogEntry) {
        entries.insert(entry, at: 0)
        save()
    }

    func update(_ entry: SendLogEntry) {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return }
        entries[index] = entry
        save()
    }

    func summaryText() -> String {
        let responded = entries.filter { $0.responded == true }.count
        let right = entries.filter { $0.feltRight == true }.count
        var lines = ["Music Shadow Phase 0 send log",
                     "Sends: \(entries.count)  Responses reported: \(responded)  Felt right: \(right)"]
        let f = ISO8601DateFormatter()
        for e in entries.reversed() {
            lines.append("\(f.string(from: e.date)) | \(e.songTitle) | note \(e.noteLength) chars | match \(e.matched ? "yes" : "no") | platform \(e.receiverPlatform ?? "?") | responded \(e.responded.map { $0 ? "yes" : "no" } ?? "?") | felt right \(e.feltRight.map { $0 ? "yes" : "no" } ?? "?")")
        }
        return lines.joined(separator: "\n")
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([SendLogEntry].self, from: data) else { return }
        entries = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
