// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "totp",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "TOTPCore", targets: ["TOTPCore"]),
        .executable(name: "TOTPApp", targets: ["TOTPApp"]),
    ],
    targets: [
        .target(name: "TOTPCore"),
        .executableTarget(
            name: "TOTPApp",
            dependencies: ["TOTPCore"],
            exclude: ["Info.plist"],
            linkerSettings: [
                .unsafeFlags([
                    "-Xlinker", "-sectcreate",
                    "-Xlinker", "__TEXT",
                    "-Xlinker", "__info_plist",
                    "-Xlinker", "Sources/TOTPApp/Info.plist",
                ]),
            ]
        ),
        .testTarget(
            name: "TOTPCoreTests",
            dependencies: ["TOTPCore"]
        ),
    ]
)
