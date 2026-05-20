// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "WWIntelligentAgent",
    platforms: [
        .iOS(.v26)
    ],
    products: [
        .library(name: "WWIntelligentAgent", targets: ["WWIntelligentAgent"]),
    ],
    targets: [
        .target(name: "WWIntelligentAgent", resources: [.copy("Privacy")]),
    ],
    swiftLanguageModes: [
        .v6
    ]
)
