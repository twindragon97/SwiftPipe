// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftPipeDatabase",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftPipeDatabase", targets: ["SwiftPipeDatabase"]),
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "SwiftPipeDatabase",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
            ]
        ),
        .testTarget(
            name: "SwiftPipeDatabaseTests",
            dependencies: ["SwiftPipeDatabase"]
        ),
    ]
)
