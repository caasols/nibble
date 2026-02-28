# Nibble

Nibble sits quietly in your menubar, watching your ethernet so you don't have to. Open-source, no bloat, just the connection info you actually need.

![Nibble Screenshot](screenshot.png)

## Features

- Real-time Ethernet connection status monitoring
- Public IP address display
- Network interface listing (en0, en1, en6, etc.)
- Detailed interface information (MAC address, IP addresses, status)
- "Open at Login" functionality
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
- See your public IP address
- Browse network interfaces
- Access preferences
- Set the app to open at login

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

## Development

### Project Structure

```
nibble/
├── Nibble/
│   ├── NibbleApp.swift            # App entry point
│   ├── AppDelegate.swift          # Menu bar setup
│   ├── Views/
│   │   ├── ContentView.swift      # Main menu view
│   │   ├── InterfaceDetailView.swift
│   │   ├── PreferencesView.swift
│   │   └── AboutView.swift
│   ├── Services/
│   │   └── NetworkMonitor.swift   # Network monitoring
│   └── Utilities/
│       └── LoginItemManager.swift # Login item management
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
- [ ] Network speed monitoring
- [ ] Custom refresh intervals
- [ ] Export network information
- [ ] Dark mode improvements
