// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Vinylette",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Vinylette",
            path: "Sources/Vinylette",
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "VinyletteTests",
            dependencies: ["Vinylette"],
            path: "Tests/VinyletteTests"
        )
    ]
)
