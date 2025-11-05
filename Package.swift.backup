// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "IngredientCheck",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "IngredientCheck",
            targets: ["IngredientCheck"]
        )
    ],
    dependencies: [
        // No external dependencies initially - using URLSession for networking
        // Dependencies will be added as needed via Swift Package Manager
    ],
    targets: [
        .target(
            name: "IngredientCheck",
            dependencies: []
        ),
        .testTarget(
            name: "IngredientCheckTests",
            dependencies: ["IngredientCheck"]
        )
    ]
)
