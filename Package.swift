// swift-tools-version:5.2
import PackageDescription

let package = Package(
    name: "WorkTimer",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "work-timer", targets: ["WorkTimerCli"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", .exact("0.0.6")),
        .package(url: "https://github.com/apple/swift-tools-support-core", .exact("0.1.3")),
    ],
    targets: [
        .target(
            name: "WorkTimerCli",
            dependencies: [
                "WorkTimerCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")]),
        .target(
            name: "WorkTimerCore",
            dependencies: [
                .product(name: "SwiftToolsSupport-auto", package: "swift-tools-support-core")
        ]),
        .testTarget(
            name: "WorkTimerCoreTests",
            dependencies: ["WorkTimerCore"]),
        .testTarget(
            name: "WorkTimerCliTests",
            dependencies: ["WorkTimerCli"]),
    ]
)
