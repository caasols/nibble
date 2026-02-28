import Foundation

struct MenuBarIconDescriptor: Equatable {
    let systemSymbolName: String
    let accessibilityDescription: String

    static func forConnectionState(_ state: EthernetConnectionState) -> MenuBarIconDescriptor {
        switch state {
        case .active:
            return MenuBarIconDescriptor(
                systemSymbolName: "network",
                accessibilityDescription: LocalizationCatalog.localized("menubar.icon.active")
            )
        case .inactive:
            return MenuBarIconDescriptor(
                systemSymbolName: "exclamationmark.network",
                accessibilityDescription: LocalizationCatalog.localized("menubar.icon.inactive")
            )
        case .disconnected:
            return MenuBarIconDescriptor(
                systemSymbolName: "network.slash",
                accessibilityDescription: LocalizationCatalog.localized("menubar.icon.disconnected")
            )
        }
    }
}
