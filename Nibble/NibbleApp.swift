import SwiftUI
import Network

@main
struct NibbleApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            PreferencesView()
                .environmentObject(appDelegate.settings)
                .environmentObject(appDelegate.updateCoordinator)
        }
    }
}
