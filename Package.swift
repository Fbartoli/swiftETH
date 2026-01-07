// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "swiftETH",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "swiftETH",
            targets: ["swiftETH"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Boilertalk/secp256k1.swift.git", from: "0.1.0"),
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0")
    ],
    targets: [
        .target(
            name: "swiftETH",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift"),
                .product(name: "CryptoSwift", package: "CryptoSwift")
            ]
        ),
        .testTarget(
            name: "swiftETHTests",
            dependencies: ["swiftETH"]
        ),
    ]
)
