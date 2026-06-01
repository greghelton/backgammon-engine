// swift-tools-version: 6.3
import PackageDescription

let package = Package(
    name: "Backgammon",
    platforms: [
        .macOS(.v14),
        .iOS(.v17)
    ],
    products: [
        .library(name: "BackgammonEngine", targets: ["BackgammonEngine"]),
        .executable(name: "BackgammonTrainer", targets: ["BackgammonTrainer"]),
    ],
    targets: [
        .target(
            name: "BackgammonEngine",
            path: "Sources/BackgammonEngine"
        ),
        .executableTarget(
            name: "BackgammonTrainer",
            dependencies: ["BackgammonEngine"],
            path: "Sources/BackgammonTrainer"
        ),
        .testTarget(
            name: "BackgammonEngineTests",
            dependencies: ["BackgammonEngine"],
            path: "Tests/BackgammonEngineTests"
        ),
    ],
    swiftLanguageModes: [.v6]
)
