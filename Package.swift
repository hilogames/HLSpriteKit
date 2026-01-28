// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "HLSpriteKit",
    platforms: [
      .iOS(.v12),
      .macOS(.v10_13)
    ],
    products: [
        .library(
            name: "HLSpriteKit",
            targets: ["HLSpriteKit"]
        ),
    ],
    targets: [
        .target(
            name: "HLSpriteKit",
        ),
        .testTarget(
            name: "HLSpriteKitTests",
            dependencies: ["HLSpriteKit"]
        ),
    ]
)
