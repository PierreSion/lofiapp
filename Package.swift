// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LofiApp",
    platforms: [
        .macOS(.v14)
    ],
    targets: [
        .executableTarget(
            name: "LofiApp",
            path: "LofiApp",
            exclude: ["Info.plist", "LofiApp.entitlements", "AppIcon.icns"]
        )
    ]
)
