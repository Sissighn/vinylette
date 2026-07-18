// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Vinylette",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "Vinylette",
            path: "Sources/Vinylette"
        ),
        .testTarget(
            name: "VinyletteTests",
            dependencies: ["Vinylette"],
            path: "Tests/VinyletteTests"
        )
    ]
)
