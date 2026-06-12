// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftPipeExtractor",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftPipeExtractor", targets: ["SwiftPipeExtractor"]),
        .library(name: "SwiftPipeExtractorJS", targets: ["SwiftPipeExtractorJS"]),
        .library(name: "NanoJSON", targets: ["NanoJSON"]),
        .library(name: "TimeAgoParser", targets: ["TimeAgoParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.7.0"),
    ],
    targets: [
        // Faithful port of TeamNewPipe/nanojson (MIT). JsonObject preserves key
        // insertion order and JsonWriter output is byte-identical to the Java
        // implementation — required for mock-based tests that compare POST bodies.
        .target(name: "NanoJSON"),

        // Port of NewPipeExtractor's timeago-parser module.
        .target(name: "TimeAgoParser"),

        // 1:1 mirror of extractor/src/main/java/org/schabi/newpipe/extractor.
        // Cross-platform (Linux/Windows/Apple); JS execution goes through the
        // JavaScriptRunner protocol so this target never imports JavaScriptCore.
        .target(
            name: "SwiftPipeExtractor",
            dependencies: [
                "NanoJSON",
                "TimeAgoParser",
                .product(name: "SwiftSoup", package: "SwiftSoup"),
            ]
        ),

        // JavaScriptCore-backed JavaScriptRunner (Apple platforms only; compiles
        // to an empty module elsewhere). Injected at app startup.
        .target(
            name: "SwiftPipeExtractorJS",
            dependencies: ["SwiftPipeExtractor"]
        ),

        .testTarget(
            name: "SwiftPipeExtractorTests",
            dependencies: [
                "SwiftPipeExtractor",
                "SwiftPipeExtractorJS",
                "NanoJSON",
                "TimeAgoParser",
            ]
        ),
    ]
)
