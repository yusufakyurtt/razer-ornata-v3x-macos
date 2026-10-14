// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RazerControl",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "RazerControl",
            targets: ["RazerControl"]
        ),
        .library(
            name: "RazerControlKit",
            targets: ["RazerControlKit"]
        )
    ],
    targets: [
        .target(
            name: "RazerControlKit",
            resources: [
                .process("Resources")
            ]
        ),
        .executableTarget(
            name: "RazerControl",
            dependencies: ["RazerControlKit"]
        ),
        .testTarget(
            name: "RazerControlTests",
            dependencies: ["RazerControlKit"]
        )
    ]
)
