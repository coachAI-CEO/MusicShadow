import Foundation

/// Debug mode manager for extra logging and debug features
final class DebugMode {
    static let shared = DebugMode()
    
    private let userDefaultsKey = "debugModeEnabled"
    
    var isEnabled: Bool {
        get {
            UserDefaults.standard.bool(forKey: userDefaultsKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: userDefaultsKey)
        }
    }
    
    private init() {}
    
    /// Log a debug message (only if debug mode is enabled)
    func log(_ message: String, category: String = "DEBUG") {
        guard isEnabled else { return }
        let timestamp = DateFormatter.debugFormatter.string(from: Date())
        print("🔍 [\(timestamp)] [\(category)] \(message)")
    }
    
    /// Format last refresh time for display
    func formatLastRefreshTime(_ date: Date?) -> String? {
        guard let date = date, isEnabled else { return nil }
        return DateFormatter.debugFormatter.string(from: date)
    }
}

extension DateFormatter {
    static let debugFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()
}
