// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "PomodoroApp",
    platforms: [
        .macOS(.v12)
    ],
    targets: [
        .executableTarget(
            name: "PomodoroApp",
            path: "Sources/PomodoroApp"
        )
    ]
)
