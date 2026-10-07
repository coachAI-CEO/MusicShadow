import Foundation

/// Build-time switches. Partner UI is off for v1: the token-link send flow replaces it
/// (docs/send-receive-plan.md, "Final gate overrides"). Flip only after the item 1 decision.
enum FeatureFlags {
    static let partnerEnabled = false
}
