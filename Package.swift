// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWIntelligentAgent",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(name: "WWIntelligentAgent", targets: ["WWIntelligentAgent"]),
    ],
    dependencies: [
        .package(url: "https://github.com/William-Weng/WWSQLite3Manager", .upToNextMinor(from: "2.4.0"))
    ],
    targets: [
        .target(name: "WWIntelligentAgent",
            dependencies: [
                .product(name: "WWSQLite3Manager", package: "WWSQLite3Manager")
            ],
            resources: [.copy("Privacy")]),
    ],
    swiftLanguageModes: [
        .v6
    ]
)
