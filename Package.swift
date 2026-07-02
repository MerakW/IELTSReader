// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "IELTSReader",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "IELTSReader", targets: ["IELTSReader"])
    ],
    targets: [
        .executableTarget(name: "IELTSReader")
    ]
)
