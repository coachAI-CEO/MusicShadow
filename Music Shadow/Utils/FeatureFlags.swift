import Foundation

/// Build-time switches. Partner linking (invite code, level-limited shared feed) is on; the database side is
/// supabase/migrations/20261008000001_partner_pairing.sql.
enum FeatureFlags {
    static let partnerEnabled = true

    /// Listen through the microphone to identify the song. Needs the ShazamKit App Service on the App ID.
    /// If Apple's provisioning does not include the entitlement yet, capture falls back to Apple Music or typing.
    static let shazamCapture = true
}
