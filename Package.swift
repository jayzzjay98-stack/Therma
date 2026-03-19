// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Therma",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "Therma",
            path: "Sources/RamCleaner"
        ),
        .testTarget(
            name: "ThermaTests",
            dependencies: ["Therma"],
            path: "Tests/RamCleanerTests"
        )
    ]
)
