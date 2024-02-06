// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InteractionKit",
    platforms: [.iOS(.v17)],
    products: [.library(name: "InteractionKit", targets: ["InteractionKit"])],
    targets: [
        .target(name: "InteractionKit"),
        .testTarget(
            name: "InteractionKitTests", dependencies: ["InteractionKit"]),
    ]
)
