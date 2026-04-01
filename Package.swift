// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GHLauncher",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .executable(
            name: "GHLauncher",
            targets: ["GHLauncher"]
        ),
    ],
    targets: [
        .executableTarget(
            name: "GHLauncher",
            path: "GHLauncher",
            resources: [.process("Resources")]
        )
    ]
)
