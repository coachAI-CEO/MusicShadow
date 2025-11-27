import Foundation

struct SongEvent: Identifiable, Decodable {
    let id: UUID
    let song_title: String?
    let artist: String?
    let created_at: String?
    let body_location: String?
    let somatic_type: String?
    let impulse: String?
    let intensity: Int?
    let body_report: String?
    let impulse_report: String?
    let block_report: String?
    let echo_report: String?
    let belief_report: String?
    let pattern_report: String?
    let interruption_directive: String?
}

