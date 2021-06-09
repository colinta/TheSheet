// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "TheSheet",
    platforms: [
        .macOS(.v10_14),
    ],
    products: [
        .executable(name: "sheet", targets: ["TheSheet"]),
    ],
    dependencies: [
        // .package(url: "https://github.com/colinta/Ashen.git", .branch("main")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "0.3.0"),
        .package(path: "../Ashen"),
    ],
    targets: [
        .target(name: "TheSheet", dependencies: ["Ashen", "ArgumentParser"]),
    ]
)
