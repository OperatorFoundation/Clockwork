// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Clockwork",
    platforms: [.macOS(.v13)],
    products: [
        .plugin(name: "Clockwork", targets: ["ClockworkBuildTool"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.1.4"),

        .package(url: "https://github.com/OperatorFoundation/Gardener", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Spacetime", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/Transmission", branch: "main"),
        .package(url: "https://github.com/OperatorFoundation/TransmissionTypes", branch: "main"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Clockwork",
            dependencies: [
                "Gardener",
            ]
        ),
        .target(
            name: "ClockworkExamples",
            dependencies: [
                "Transmission",
                "TransmissionTypes",

                .product(name: "Simulation", package: "Spacetime"),
                .product(name: "Spacetime", package: "Spacetime"),
                .product(name: "Universe", package: "Spacetime"),
            ],
            plugins: [.plugin(name: "Clockwork")]
        ),
        .executableTarget(
            name: "ClockworkCommandLine",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),

                "Clockwork",
                "Gardener",
            ]
        ),
        .executableTarget(
            name: "ClockworkSpacetimeCommandLine",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),

                "Clockwork",
                "Gardener",
            ]
        ),
        .plugin(
            name: "ClockworkBuildTool",
            capability: .buildTool(),
            dependencies: [
                .target(name: "ClockworkCommandLine")
            ]
        ),
        .testTarget(
            name: "ClockworkTests",
            dependencies: [
                "Transmission",
                "TransmissionTypes",

                "Clockwork",
                "ClockworkExamples",
            ]
        ),
    ],
    swiftLanguageVersions: [.v5]
)
