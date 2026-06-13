// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/DeliveryMethod.java @ v0.26.3

public enum DeliveryMethod {
    /// Progressive HTTP streaming.
    case PROGRESSIVE_HTTP
    /// Dynamic Adaptive Streaming over HTTP.
    case DASH
    /// HTTP Live Streaming.
    case HLS
    /// Microsoft SmoothStreaming.
    case SS
    /// Served via a torrent file.
    case TORRENT
}
