// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftPipeGiga",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftPipeGiga", targets: ["SwiftPipeGiga"]),
    ],
    targets: [
        // Mirror of NewPipe's download engine (app/src/main/java/us/shandian/giga)
        // and of the pure-Java muxers in org/schabi/newpipe/streams
        // (Mp4FromDashWriter, WebMWriter, OggFromWebMWriter, SrtFromTtmlWriter,
        // readers and io helpers). The mux/stream logic is pure byte pushing and
        // stays cross-platform; the background-URLSession transport is gated to
        // Apple platforms.
        .target(name: "SwiftPipeGiga"),
        .testTarget(
            name: "SwiftPipeGigaTests",
            dependencies: ["SwiftPipeGiga"]
        ),
    ]
)
