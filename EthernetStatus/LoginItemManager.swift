import Foundation
import ServiceManagement

class LoginItemManager {
    static func setOpenAtLogin(enabled: Bool) {
        // For macOS 13+ (Ventura and later)
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            do {
                if enabled {
                    try service.register()
                } else {
                    try service.unregister()
                }
            } catch {
                print("Failed to \(enabled ? "register" : "unregister") login item: \(error)")
            }
        } else {
            // For older macOS versions, use the legacy API
            // This requires a helper app in the main app bundle
            setLegacyLoginItem(enabled: enabled)
        }
    }
    
    static func isOpenAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            let service = SMAppService.mainApp
            return service.status == .enabled
        } else {
            return isLegacyLoginItemEnabled()
        }
    }
    
    private static func setLegacyLoginItem(enabled: Bool) {
        // Legacy implementation using SMLoginItemSetEnabled
        // This is a simplified version - in production you'd want to properly implement this
        print("Legacy login item setting: \(enabled)")
    }
    
    private static func isLegacyLoginItemEnabled() -> Bool {
        // Check if the app is in login items
        return false
    }
}