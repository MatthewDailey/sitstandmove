// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SitStandMove",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "SitStandMove",
            path: "Sources/SitStandMove"
        )
    ]
)
