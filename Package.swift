// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "EthernetStatus",
    platforms: [.macOS(.v12)],
    products: [
        .executable(name: "EthernetStatus", targets: ["EthernetStatus"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "EthernetStatus",
            dependencies: [],
            path: "EthernetStatus",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "EthernetStatusTests",
            dependencies: [
                "EthernetStatus",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
