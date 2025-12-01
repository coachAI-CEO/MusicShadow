import Foundation
import UserNotifications

final class NotificationManager {
    static let shared = NotificationManager()
    private init() {}

    private let radarIdentifier = "shadowRadarDaily"

    func requestAuthorization(completion: ((Bool) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("🔔 Notification auth error:", error)
            }
            DispatchQueue.main.async {
                completion?(granted)
            }
        }
    }

    func scheduleDailyRadar(at hour: Int = 21, minute: Int = 0) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [radarIdentifier])

        let content = UNMutableNotificationContent()
        content.title = "Shadow radar check-in"
        content.body = "Your shadow was active today. Want a grounding practice?"
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: radarIdentifier,
            content: content,
            trigger: trigger
        )

        center.add(request) { error in
            if let error = error {
                print("🔔 Failed to schedule radar:", error)
            } else {
                print("🔔 Scheduled daily radar at \(hour):\(minute)")
            }
        }
    }

    func cancelDailyRadar() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [radarIdentifier])
    }
}//
//  NotificationManager.swift
//  Music Shadow
//
//  Created by macbook on 11/26/25.
//

