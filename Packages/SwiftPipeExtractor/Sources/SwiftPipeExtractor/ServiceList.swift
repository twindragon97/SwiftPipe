// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/ServiceList.java @ v0.26.3
//
// The concrete service singletons (YouTube id 0, SoundCloud id 1, ...) are
// registered here as each service is ported. Until then `all()` is empty.
// When creating a new service, put it at the end of this list and give it the
// next free id.

public enum ServiceList {
    // TODO(P1-youtube): public static let YouTube = YoutubeService(0)

    private static let SERVICES: [StreamingService] = [
        // YouTube, SoundCloud, MediaCCC, PeerTube, Bandcamp
    ]

    /// All the supported services.
    public static func all() -> [StreamingService] {
        SERVICES
    }
}
