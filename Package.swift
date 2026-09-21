// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Testing",
    products: [
        .library(
            name: "Testing",
            targets: ["Testing"]
        ),
    ],
    targets: [
        .target(
            name: "Testing"
        ),
    ],
    swiftLanguageModes: [.v6]
)
