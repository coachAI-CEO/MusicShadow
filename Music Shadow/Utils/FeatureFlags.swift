import Foundation

/// Build-time switches. Partner UI is off for v1: the token-link send flow replaces it
/// (docs/send-receive-plan.md, "Final gate overrides"). Flip only after the item 1 decision.
enum FeatureFlags {
    static let partnerEnabled = false

    /// Listen through the microphone to identify the song. Needs the ShazamKit App Service on the App ID.
    /// If Apple's provisioning does not include the entitlement yet, capture falls back to Apple Music or typing.
    static let shazamCapture = true
}
