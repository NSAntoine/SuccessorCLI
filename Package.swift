// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SuccessorCLI",
    platforms: [.iOS(.v14)],
    targets: [
        .target(
           name: "SuccessorCLI",
           path: "src",
           publicHeadersPath: "src/Bridge.h"),
    ]
)
