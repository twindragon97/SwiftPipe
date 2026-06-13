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
        // Local mirror of NewPipeExtractor — StreamEntity stores its StreamType,
        // exactly as Android's app module depends on the extractor.
        .package(path: "../SwiftPipeExtractor"),
    ],
    targets: [
        .target(
            name: "SwiftPipeDatabase",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift"),
                .product(name: "SwiftPipeExtractor", package: "SwiftPipeExtractor"),
            ]
        ),
        .testTarget(
            name: "SwiftPipeDatabaseTests",
            dependencies: ["SwiftPipeDatabase"],
            resources: [
                // Authoritative Room v9 schema, copied verbatim from
                // upstream/NewPipe/app/schemas. The schema test compares the
                // database we build against this ground truth.
                .copy("Resources/room-schema-9.json")
            ]
        ),
    ]
)
