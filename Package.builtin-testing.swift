// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "EthernetStatus",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "EthernetStatus", targets: ["EthernetStatus"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "EthernetStatus",
            dependencies: [],
            path: "EthernetStatus",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "EthernetStatusTests",
            dependencies: ["EthernetStatus"]
        )
    ]
)
