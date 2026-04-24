// swift-tools-version: 5.9
// KeyflowAuthKit — shared iOS client for auth.keyflowae.com.
// Consumed by LeadsFlow, DealsFlow, and LeaseFlow iOS apps.

import PackageDescription

let package = Package(
    name: "KeyflowAuthKit",
    platforms: [
        .iOS(.v17),
        .macOS(.v13),
    ],
    products: [
        .library(
            name: "KeyflowAuthKit",
            targets: ["KeyflowAuthKit"],
        ),
        .library(
            name: "KeyflowEventsKit",
            targets: ["KeyflowEventsKit"],
        ),
        .library(
            name: "KeyflowAIKit",
            targets: ["KeyflowAIKit"],
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeyflowAuthKit",
            dependencies: [],
        ),
        .target(
            name: "KeyflowEventsKit",
            dependencies: [],
        ),
        .target(
            name: "KeyflowAIKit",
            dependencies: ["KeyflowEventsKit"],
        ),
        .testTarget(
            name: "KeyflowAuthKitTests",
            dependencies: ["KeyflowAuthKit"],
        ),
    ]
)
