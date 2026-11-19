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
        // 静态库 + C 头 + modulemap，由 core/scripts/build-macos.sh 生成，不入库。
        .binaryTarget(name: "totp_coreFFI", path: "Frameworks/TOTPCoreFFI.xcframework"),
        // UniFFI 生成的 Swift 绑定：xcframework 装不下 Swift 源码，只能当普通 source target 编译。
        .target(name: "TOTPCoreBindings", dependencies: ["totp_coreFFI"]),
        .target(name: "TOTPCore", dependencies: ["TOTPCoreBindings"]),
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
