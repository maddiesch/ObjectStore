// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ObjectStore",
    platforms: [
        .iOS(.v14),
        .macOS(.v11)
    ],
    products: [
        .library(name: "ObjectStore", targets: ["ObjectStore"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "ObjectStore", dependencies: []),
        .testTarget(name: "ObjectStoreTests", dependencies: ["ObjectStore"]),
    ]
)
