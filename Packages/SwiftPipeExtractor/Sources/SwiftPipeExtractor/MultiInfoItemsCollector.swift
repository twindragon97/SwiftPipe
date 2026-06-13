// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/MultiInfoItemsCollector.java @ v0.26.3
//
// Java's `instanceof` dispatch maps to Swift type checks. The extractor type
// parameter is `any InfoItemExtractor` (a protocol existential) since the
// concrete sub-protocol is determined at runtime.

public final class MultiInfoItemsCollector:
    InfoItemsCollector<InfoItem, any InfoItemExtractor> {

    private let streamCollector: StreamInfoItemsCollector
    private let userCollector: ChannelInfoItemsCollector
    private let playlistCollector: PlaylistInfoItemsCollector

    public init(_ serviceId: Int) {
        streamCollector = StreamInfoItemsCollector(serviceId)
        userCollector = ChannelInfoItemsCollector(serviceId)
        playlistCollector = PlaylistInfoItemsCollector(serviceId)
        super.init(serviceId)
    }

    public override func getErrors() -> [Error] {
        var errors = super.getErrors()
        errors.append(contentsOf: streamCollector.getErrors())
        errors.append(contentsOf: userCollector.getErrors())
        errors.append(contentsOf: playlistCollector.getErrors())
        return errors
    }

    public override func reset() {
        super.reset()
        streamCollector.reset()
        userCollector.reset()
        playlistCollector.reset()
    }

    public override func extract(_ extractor: any InfoItemExtractor) throws -> InfoItem {
        // Use the corresponding collector for each item extractor type
        if let streamExtractor = extractor as? StreamInfoItemExtractor {
            return try streamCollector.extract(streamExtractor)
        } else if let channelExtractor = extractor as? ChannelInfoItemExtractor {
            return try userCollector.extract(channelExtractor)
        } else if let playlistExtractor = extractor as? PlaylistInfoItemExtractor {
            return try playlistCollector.extract(playlistExtractor)
        } else {
            preconditionFailure("Invalid extractor type: \(extractor)")
        }
    }
}
