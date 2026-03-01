# Nibble

Nibble sits quietly in your menubar, watching your ethernet so you don't have to. Open-source, no bloat, just the connection info you actually need.

![Nibble Screenshot](screenshot.png)

## Features

- Real-time Ethernet connection status monitoring
- Instantaneous download/upload speed display (live throughput, not speedtest max)
- Public IP address display
- Network interface listing (en0, en1, en6, etc.)
- Detailed interface information (MAC address, IP addresses, status)
- Preferences panel for app-level controls (open at login, updates, diagnostics, feedback, about)
- Periodic and manual update checks against official releases
- One-click diagnostics export with sanitized defaults
- In-app feedback form with optional diagnostics preview
- One-click DNS cache flush utility
- One-click Wi-Fi refresh utility (immediate toggle)
- English and Spanish localization support
- Clean, native macOS UI
- Lightweight and efficient

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 14.0 or later (for building)

## Installation

### Download Pre-built App

1. Go to the [Releases](https://github.com/caasols/nibble/releases) page
2. Download the latest release
3. Drag `Nibble.app` to your Applications folder
4. Launch the app

Release artifacts are Developer ID signed, notarized, and validated by CI hygiene checks before publication.

### Build from Source

```bash
git clone https://github.com/caasols/nibble.git
cd nibble
xcodebuild -scheme Nibble -configuration Release
```

The built app will be in `build/Release/Nibble.app`

## Usage

Once launched, Nibble will appear in your menu bar. Click the icon to:

- View Ethernet connection status
- View instantaneous network speed (down/up)
- See your public IP address
- Browse network interfaces
- Access Preferences for updates, diagnostics, feedback, about, and startup behavior

## Public IP Privacy Transparency

- Public IP lookups are optional and controlled by `Show Public IP Address` in Preferences.
- When enabled, Nibble requests the public IP from `api.ipify.org` over HTTPS.
- Requests occur at startup, when the setting is enabled, and on each refresh cycle.
- When disabled, Nibble does not request the public IP.

## Telemetry Controls

- Telemetry sharing is opt-in and disabled by default.
- You can enable or disable telemetry anytime in Preferences.
- Nibble shows how many telemetry events are pending local send.
- You can erase all pending unsent telemetry data in one click from Preferences.

## Telemetry Data Summary

- Nibble only queues allowlisted product events (`app_started`, `open_preferences`, `toggle_telemetry`, `toggle_public_ip`).
- Allowed fields are limited per event and unknown fields are dropped.
- Sensitive network identifiers are excluded by default (for example: public IP, private IP, MAC address, SSID, interface name).
- Telemetry remains local in `UserDefaults` as pending unsent events unless you explicitly opt in.

For the internal telemetry governance map, see `docs/telemetry-map.md`.

## Update Checks

- Nibble checks for updates periodically using the official GitHub releases endpoint.
- You can run an on-demand check from Preferences.
- Before opening a download page, Nibble prompts for confirmation and shows release notes.

## Diagnostics Export

- Export a diagnostics JSON snapshot from the menu with one click.
- By default, export is sanitized and excludes public IP, local IP addresses, and hardware identifiers.
- You can explicitly choose to include sensitive identifiers when needed for deeper troubleshooting.

## In-App Feedback

- Submit bug reports and feature requests from the menu without manually assembling issue templates.
- Optionally attach a diagnostics JSON preview in clipboard-ready feedback text, then open GitHub issue creation without URL-embedded payload data.
- Diagnostics inclusion is explicit and defaults to sanitized export.

## Development

### Project Structure

```
nibble/
├── Nibble/
│   ├── NibbleApp.swift
│   ├── AppDelegate.swift
│   ├── ContentView.swift
│   ├── PreferencesView.swift
│   ├── NetworkMonitor.swift
│   ├── NetworkSpeedSampler.swift
│   ├── DNSFlushService.swift
│   ├── WiFiRefreshService.swift
│   ├── FeedbackComposer.swift
│   ├── DiagnosticsExportBuilder.swift
│   └── ...
├── Tests/NibbleTests/
│   └── ...
└── Package.swift
```

### Building

Open the project in Xcode:

```bash
open Package.swift
```

Or build from command line:

```bash
swift build
```

### Developer Shortcuts

Nibble includes a `Makefile` with convenience commands for common local tasks:

```bash
make build                # swift build with shared scratch path
make run                  # swift run Nibble
make app                  # build app bundle via build.sh
make release              # swift build -c release
make release-hygiene-test # run release artifact hygiene tests
make lint-fix             # auto-fix formatting and lint issues
make lint                 # run lint checks
make clean                # remove scratch build path
```

These commands are optional shortcuts around the same underlying Swift/build scripts.

## Release Process

Nibble uses a dedicated release workflow in `.github/workflows/release.yml` that:

- builds the app bundle
- signs with Developer ID certificate
- notarizes and staples with Apple notarytool
- checks artifact hygiene (signature, bundle ID, archive contents)
- publishes zip and checksum to GitHub Releases

See `CONTRIBUTING.md` for required secrets and release runbook details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

See `CONTRIBUTING.md` for development workflow, CI lane details, and recommended branch protection settings.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

- Inspired by the original wired-status menu bar workflow
- Built with SwiftUI and Combine
- Uses native macOS networking APIs

## Support

If you encounter any issues or have questions:

- Open an [issue](https://github.com/caasols/nibble/issues)
- Join discussions on [GitHub Discussions](https://github.com/caasols/nibble/discussions)

## Roadmap

- [ ] Remove temporary `swift-testing` package dependency once CI and local full-Xcode environments run built-in Swift Testing consistently
- [ ] Wi-Fi status support
- [ ] VPN connection detection
- [ ] Historical interface traffic and trend views
- [ ] Preferences UX polish and structure refinement
- [ ] Improve localization coverage across more languages
