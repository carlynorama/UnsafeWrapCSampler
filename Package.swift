// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UnsafeWrapCSampler",
    products: [
        .library(
            name: "UWCSampler",
            targets: ["UWCSamplerC", "UWCSampler"]),
    ],
    targets: [
        .target(
            name: "UWCSamplerC",
            path: "Sources/C"
            ),
        .target(
            name: "UWCSampler",
            dependencies: ["UWCSamplerC"],
            path: "Sources/Swift"
        )
    ]
)
