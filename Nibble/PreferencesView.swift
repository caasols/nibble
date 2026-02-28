import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var settings: AppSettings
    @EnvironmentObject var updateCoordinator: UpdateCoordinator
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text(LocalizationCatalog.localized("preferences.title"))
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(LocalizationCatalog.localized("common.done")) {
                    dismiss()
                }
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(LocalizationCatalog.localized("preferences.show_public_ip"), isOn: $settings.showPublicIP)

                    Text(settings.publicIPTransparencySummary)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: LocalizationCatalog.localized("preferences.public_ip_provider"), settings.publicIPProviderHost))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationCatalog.localized("preferences.app_mode"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker(LocalizationCatalog.localized("preferences.app_mode"), selection: $settings.appMode) {
                        Text(LocalizationCatalog.localized("preferences.app_mode.menubar_dock")).tag(AppSettings.AppMode.menuBarAndDock)
                        Text(LocalizationCatalog.localized("preferences.app_mode.menubar_only")).tag(AppSettings.AppMode.menuBarOnly)
                    }
                    .pickerStyle(.segmented)

                    Text(settings.appMode == .menuBarOnly
                         ? LocalizationCatalog.localized("preferences.app_mode.help.menubar_only")
                         : LocalizationCatalog.localized("preferences.app_mode.help.menubar_dock"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(String(format: LocalizationCatalog.localized("preferences.refresh_interval"), settings.refreshInterval))
                    Slider(value: .init(
                        get: { Double(settings.refreshInterval) },
                        set: { settings.refreshInterval = Int($0) }
                    ), in: 10...300, step: 10)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationCatalog.localized("preferences.telemetry"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Toggle(LocalizationCatalog.localized("preferences.telemetry.toggle"), isOn: $settings.telemetryEnabled)

                    Text(LocalizationCatalog.localized("preferences.telemetry.help"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(String(format: LocalizationCatalog.localized("preferences.telemetry.pending"), settings.pendingTelemetryEventCount))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button(LocalizationCatalog.localized("preferences.telemetry.erase")) {
                        settings.erasePendingTelemetryData()
                    }
                    .disabled(settings.pendingTelemetryEventCount == 0)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(LocalizationCatalog.localized("preferences.updates"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(LocalizationCatalog.localized("preferences.updates.help"))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 10) {
                        Button(LocalizationCatalog.localized("preferences.updates.check_now")) {
                            Task {
                                await updateCoordinator.checkForUpdatesManually()
                            }
                        }

                        Text(updateCoordinator.statusMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 460, height: 380)
    }
}
