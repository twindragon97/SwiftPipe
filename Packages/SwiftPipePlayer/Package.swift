// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "SwiftPipePlayer",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
    ],
    products: [
        .library(name: "SwiftPipePlayer", targets: ["SwiftPipePlayer"]),
    ],
    targets: [
        // UI-free player core (Phase 5): port of org/schabi/newpipe/player/playqueue
        // (PlayQueue, PlayQueueItem, Single/Playlist/ChannelTab queues, repeat/
        // shuffle), the stream source resolvers (HLS first, progressive fallback),
        // resume-position logic matching StreamStateEntity thresholds, and the
        // sleep timer. A single AVPlayer is driven by a custom queue manager —
        // AVQueuePlayer is unsuitable because stream URLs expire and items must
        // be resolved lazily right before playback.
        .target(name: "SwiftPipePlayer"),
        .testTarget(
            name: "SwiftPipePlayerTests",
            dependencies: ["SwiftPipePlayer"]
        ),
    ]
)
