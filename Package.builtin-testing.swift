// swift-tools-version:6.2
import PackageDescription

let package = Package(
    name: "Nibble",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Nibble", targets: ["Nibble"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "Nibble",
            dependencies: [],
            path: "Nibble",
            exclude: ["Resources"]
        ),
        .testTarget(
            name: "NibbleTests",
            dependencies: ["Nibble"]
        )
    ]
)
