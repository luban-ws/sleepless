// swift-tools-version: 5.9
// Sleepless：SwiftPM 可执行目标 + 脚本组装 .app（见 scripts/build-app.sh）

import PackageDescription

let package = Package(
    name: "Sleepless",
    platforms: [
        .macOS(.v13),
    ],
    products: [
        .executable(name: "Sleepless", targets: ["Sleepless"]),
    ],
    targets: [
        .executableTarget(
            name: "Sleepless",
            path: "Sources/Sleepless",
            linkerSettings: [
                .linkedFramework("ServiceManagement"),
                .linkedFramework("IOKit"),
                // 直接运行 Mach-O 时嵌入 Info，与正式 .app 的 Contents/Info.plist 一致
                .unsafeFlags(
                    [
                        "-Xlinker", "-sectcreate",
                        "-Xlinker", "__TEXT",
                        "-Xlinker", "__info_plist",
                        "-Xlinker", "Resources/Info.plist",
                    ],
                    .when(platforms: [.macOS])
                ),
            ]
        ),
        .testTarget(
            name: "SleeplessTests",
            dependencies: ["Sleepless"],
            path: "Tests/SleeplessTests"
        ),
    ]
)
