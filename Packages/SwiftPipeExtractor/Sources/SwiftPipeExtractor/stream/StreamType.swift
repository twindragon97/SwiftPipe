// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamType.java @ v0.26.3

public enum StreamType {
    /// Internal placeholder: the stream type was not checked yet.
    case NONE
    /// A normal video stream, usually with audio.
    case VIDEO_STREAM
    /// An audio-only stream (no VideoStreams should be available).
    case AUDIO_STREAM
    /// A video live stream, usually with audio.
    case LIVE_STREAM
    /// An audio-only live stream.
    case AUDIO_LIVE_STREAM
    /// A video live stream that just ended but is not yet re-encoded.
    case POST_LIVE_STREAM
    /// An audio live stream that just ended but is not yet re-encoded.
    case POST_LIVE_AUDIO_STREAM
}
