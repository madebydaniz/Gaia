import Foundation
import UserNotifications

protocol UpdateNotifying: Sendable {
    func notifyIfNeeded(latestVersion: String, releaseURL: URL, preferences: PreferencesService) async
}

struct UpdateNotificationService: UpdateNotifying {
    func notifyIfNeeded(latestVersion: String, releaseURL: URL, preferences: PreferencesService) async {
        guard preferences.notifyOnUpdate else { return }
        guard preferences.lastNotifiedUpdateVersion != latestVersion else { return }

        let center = UNUserNotificationCenter.current()
        do {
            let settings = await center.notificationSettings()
            if settings.authorizationStatus == .notDetermined {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                if !granted { return }
            } else if settings.authorizationStatus != .authorized {
                return
            }

            let content = UNMutableNotificationContent()
            content.title = String(localized: "update.notification.title")
            content.body = String(format: NSLocalizedString("update.notification.body", comment: ""), latestVersion)
            content.sound = .default
            content.userInfo = ["releaseURL": releaseURL.absoluteString]

            let request = UNNotificationRequest(
                identifier: "gaia.update.\(latestVersion)",
                content: content,
                trigger: nil
            )
            try await center.add(request)
            preferences.lastNotifiedUpdateVersion = latestVersion
        } catch {
            // Keep update checks silent when notifications fail.
        }
    }
}
