// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "PyPasteKit",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "PyPasteDomain", targets: ["PyPasteDomain"]),
        .library(name: "PyPasteCore", targets: ["PyPasteCore"]),
        .library(name: "PyPasteData", targets: ["PyPasteData"]),
        .library(name: "PyPasteSharedUI", targets: ["PyPasteSharedUI"]),
        .library(name: "PyPasteFeatures", targets: ["PyPasteFeatures"]),
    ],
    targets: [
        .target(name: "PyPasteDomain"),
        .target(
            name: "PyPasteCore",
            dependencies: ["PyPasteDomain"],
            linkerSettings: [.linkedFramework("Carbon")]
        ),
        .target(
            name: "PyPasteData",
            dependencies: ["PyPasteDomain"],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .target(name: "PyPasteSharedUI"),
        .target(
            name: "PyPasteFeatures",
            dependencies: ["PyPasteDomain", "PyPasteSharedUI"]
        ),
        .testTarget(
            name: "PyPasteDataTests",
            dependencies: ["PyPasteData", "PyPasteDomain"]
        ),
        .testTarget(
            name: "PyPasteCoreTests",
            dependencies: ["PyPasteCore", "PyPasteDomain"]
        ),
        .testTarget(
            name: "PyPasteFeaturesTests",
            dependencies: ["PyPasteFeatures", "PyPasteDomain"]
        ),
        .testTarget(
            name: "PyPasteSharedUITests",
            dependencies: ["PyPasteSharedUI"]
        ),
    ]
)
