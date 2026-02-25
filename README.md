# Ethernet Status

An open source macOS menu bar application for monitoring Ethernet connections and network interfaces.

![Ethernet Status Screenshot](screenshot.png)

## Features

- Real-time Ethernet connection status monitoring
- Public IP address display
- Network interface listing (en0, en1, en6, etc.)
- Detailed interface information (MAC address, IP addresses, status)
- "Open at Login" functionality
- Clean, native macOS UI
- Lightweight and efficient

## Requirements

- macOS 12.0 (Monterey) or later
- Xcode 14.0 or later (for building)

## Installation

### Download Pre-built App

1. Go to the [Releases](https://github.com/yourusername/EthernetStatus/releases) page
2. Download the latest release
3. Drag `EthernetStatus.app` to your Applications folder
4. Launch the app

### Build from Source

```bash
git clone https://github.com/yourusername/EthernetStatus.git
cd EthernetStatus
xcodebuild -scheme EthernetStatus -configuration Release
```

The built app will be in `build/Release/EthernetStatus.app`

## Usage

Once launched, Ethernet Status will appear in your menu bar. Click the icon to:

- View Ethernet connection status
- See your public IP address
- Browse network interfaces
- Access preferences
- Set the app to open at login

## Development

### Project Structure

```
EthernetStatus/
├── EthernetStatus/
│   ├── EthernetStatusApp.swift    # App entry point
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

- Inspired by the original Ethernet Status app
- Built with SwiftUI and Combine
- Uses native macOS networking APIs

## Support

If you encounter any issues or have questions:

- Open an [issue](https://github.com/yourusername/EthernetStatus/issues)
- Join discussions on [GitHub Discussions](https://github.com/yourusername/EthernetStatus/discussions)

## Roadmap

- [ ] Remove temporary `swift-testing` package dependency once CI and local full-Xcode environments run built-in Swift Testing consistently
- [ ] Wi-Fi status support
- [ ] VPN connection detection
- [ ] Network speed monitoring
- [ ] Custom refresh intervals
- [ ] Export network information
- [ ] Dark mode improvements
