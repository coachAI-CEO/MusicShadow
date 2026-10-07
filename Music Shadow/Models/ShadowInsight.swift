import Foundation

/// Matches the `shadow_insights` table in Supabase
struct ShadowInsight: Identifiable, Codable {
    let id: UUID
    let event_id: UUID
    let user_id: UUID
    let created_at: String?

    let wound_type: String?
    let protector_mode: String?
    let age_range: String?
    let nervous_system: String?
    let core_belief: String?
    let summary: String?
    let suggested_practice: String?

    // The archetype the AI picked for this activation (nil on older insights).
    var archetype: String? = nil
    var archetype_confidence: String? = nil
    var archetype_evidence: String? = nil
}
