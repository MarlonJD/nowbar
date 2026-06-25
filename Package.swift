// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Nowbar",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ListeningNowCore",
            targets: ["ListeningNowCore"]
        ),
        .executable(
            name: "Nowbar",
            targets: ["Nowbar"]
        )
    ],
    targets: [
        .target(name: "ListeningNowCore"),
        .executableTarget(
            name: "Nowbar",
            dependencies: ["ListeningNowCore"]
        ),
        .testTarget(
            name: "ListeningNowCoreTests",
            dependencies: ["ListeningNowCore"]
        )
    ]
)
