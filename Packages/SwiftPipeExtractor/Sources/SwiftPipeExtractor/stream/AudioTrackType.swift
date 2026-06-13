// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/AudioTrackType.java @ v0.26.3

public enum AudioTrackType {
    /// An original audio track of a video.
    case ORIGINAL
    /// An audio track with the original voices replaced (typically another language).
    case DUBBED
    /// A descriptive audio track (accessibility).
    case DESCRIPTIVE
    /// A secondary audio track.
    case SECONDARY
}
