// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MyScreen",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "MyScreen", targets: ["MyScreen"])
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "MyScreen",
            dependencies: [],
            path: "Sources/MyScreen",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
