// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Nibble",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Nibble", targets: ["Nibble"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-testing.git", from: "0.6.0")
    ],
    targets: [
        .executableTarget(
            name: "Nibble",
            dependencies: [],
            path: "Nibble",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "NibbleTests",
            dependencies: [
                "Nibble",
                .product(name: "Testing", package: "swift-testing")
            ]
        )
    ]
)
