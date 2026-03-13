// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SpeedMenuBar",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(
            name: "SpeedMenuBar",
            targets: ["SpeedMenuBar"]
        )
    ],
    targets: [
        .target(
            name: "SpeedCore"
        ),
        .executableTarget(
            name: "SpeedMenuBar",
            dependencies: ["SpeedCore"]
        ),
        .testTarget(
            name: "SpeedCoreTests",
            dependencies: ["SpeedCore"]
        )
    ]
)
