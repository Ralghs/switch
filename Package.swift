// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Switch",
    defaultLocalization: "en",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Switch", targets: ["Switch"])
    ],
    targets: [
        .executableTarget(
            name: "Switch",
            path: "Switch",
            exclude: ["Info.plist", "Switch.entitlements", "Assets.xcassets"],
            resources: [.process("Resources")],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("Carbon"),
                .linkedFramework("ServiceManagement")
            ]
        ),
        .testTarget(
            name: "SwitchTests",
            dependencies: ["Switch"],
            path: "SwitchTests"
        )
    ]
)
