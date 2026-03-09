import UIKit

/// Lightweight haptic feedback for Music Shadow
enum HapticManager {
    enum Trigger {
        case light
        case medium
        case heavy
        case success
        case warning
        case error
    }

    static func trigger(_ trigger: Trigger) {
        let generator: UIImpactFeedbackGenerator?
        switch trigger {
        case .light:
            let g = UIImpactFeedbackGenerator(style: .light)
            g.prepare()
            g.impactOccurred()
        case .medium:
            let g = UIImpactFeedbackGenerator(style: .medium)
            g.prepare()
            g.impactOccurred()
        case .heavy:
            let g = UIImpactFeedbackGenerator(style: .heavy)
            g.prepare()
            g.impactOccurred()
        case .success:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.success)
        case .warning:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.warning)
        case .error:
            let g = UINotificationFeedbackGenerator()
            g.prepare()
            g.notificationOccurred(.error)
        }
    }
}
