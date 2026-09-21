// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Testing",
    products: [
        .library(
            name: "Testing",
            targets: ["Testing"]
        ),
        .executable(
            name: "ttest",
            targets: ["ttest"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/leviouwendijk/Atomos.git",
            branch: "master"
        ),
    ],
    targets: [
        .target(
            name: "Testing",
            dependencies: [
                .product(
                    name: "Atomos",
                    package: "Atomos"
                ),
            ]
        ),
        .executableTarget(
            name: "ttest",
            dependencies: [
                "Testing",
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)
