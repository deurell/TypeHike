// swift-tools-version: 5.8
import PackageDescription

let package = Package(
    name: "TypeHike",
    products: [
        .library(
            name: "TypeHike",
            targets: ["TypeHike"]
        ),
    ],
    targets: [
        .target(
            name: "TypeHike",
            path: "Sources",
            resources: [.process("Resources")]
        )
    ]
)
