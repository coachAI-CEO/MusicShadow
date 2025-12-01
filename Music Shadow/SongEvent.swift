import Foundation

struct SongEvent: Identifiable, Decodable {
    let id: UUID

    // Song meta
    let song_title: String?
    let artist: String?

    // Timestamps
    let created_at: String?          // Supabase ISO string
    let timestamp_seconds: Int?      // the “spike time” in the track

    // Somatic fields
    let body_location: String?
    let somatic_type: String?
    let impulse: String?
    let intensity: Int?

    // Guided journal
    let body_report: String?
    let impulse_report: String?
    let block_report: String?
    let echo_report: String?
    let belief_report: String?
    let pattern_report: String?
    let interruption_directive: String?

    // Free-form journal
    let free_journal: String?
}
