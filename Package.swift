// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "Testing",
    products: [
        .library(
            name: "Testing",
            targets: ["Testing"]
        ),

        // test executables
        .executable(
            name: "t_tm",
            targets: ["TestMain"]
        ),
        .executable(
            name: "t_tstream",
            targets: ["TestStream"]
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
            name: "TestMain",
            dependencies: [
                "Testing",
            ],
            path: "Sources/TestExecutable/TestMain"
        ),
        .executableTarget(
            name: "TestStream",
            dependencies: [
                "Testing",
                .product(
                    name: "Atomos",
                    package: "Atomos"
                ),
            ],
            path: "Sources/TestExecutable/TestStream"
        ),
    ],
    swiftLanguageModes: [.v6]
)
