#if os(macOS)
import AppKit
import ServiceManagement

@MainActor
enum MenuBarLoginItem {
    private static let configuredKey = "menuBarLoginConfigured"

    static func configure(isVisible: Bool, userChangedPreference: Bool = false) {
        let defaults = UserDefaults.standard
        let service = SMAppService.mainApp

        do {
            if isVisible {
                // Register once automatically. Respect later changes made in System Settings.
                if service.status == .notRegistered &&
                    (userChangedPreference || !defaults.bool(forKey: configuredKey)) {
                    try service.register()
                    defaults.set(true, forKey: configuredKey)
                }
            } else {
                if service.status == .enabled || service.status == .requiresApproval {
                    try service.unregister()
                }
                defaults.set(false, forKey: configuredKey)
            }
            refreshStatus()
        } catch {
            defaults.set("Unable to update launch at login: \(error.localizedDescription)", forKey: "menuBarLoginStatus")
        }
    }

    static func refreshStatus() {
        let message: String
        switch SMAppService.mainApp.status {
        case .enabled:
            message = "BunnyPad will launch at login to restore the menu bar icon."
        case .requiresApproval:
            message = "Allow BunnyPad in System Settings → General → Login Items to restore the icon after restarting."
        case .notRegistered:
            message = "Launch at login is off. Enable it to restore the icon after restarting."
        case .notFound:
            message = "macOS could not find the login item. Install BunnyPad in Applications and try again."
        @unknown default:
            message = "Check BunnyPad’s launch-at-login status in System Settings."
        }
        UserDefaults.standard.set(message, forKey: "menuBarLoginStatus")
    }

    static func openSettings() {
        SMAppService.openSystemSettingsLoginItems()
    }
}
#endif
