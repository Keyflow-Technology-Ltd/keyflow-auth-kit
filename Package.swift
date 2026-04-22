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
    ],
    dependencies: [],
    targets: [
        .target(
            name: "KeyflowAuthKit",
            dependencies: [],
        ),
        .testTarget(
            name: "KeyflowAuthKitTests",
            dependencies: ["KeyflowAuthKit"],
        ),
    ]
)
