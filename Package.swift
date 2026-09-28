// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MagicEarthiOS",
    defaultLocalization: "vi",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "MagicEarthiOS",
            targets: ["MagicEarthiOS"]
        )
    ],
    dependencies: [
        .package(
            url: "https://github.com/maplibre/maplibre-gl-native-distribution.git",
            from: "5.13.0"
        )
    ],
    targets: [
        .target(
            name: "MagicEarthiOS",
            dependencies: [
                .product(name: "MapLibre", package: "maplibre-gl-native-distribution")
            ],
            path: "MagicEarthiOS",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
