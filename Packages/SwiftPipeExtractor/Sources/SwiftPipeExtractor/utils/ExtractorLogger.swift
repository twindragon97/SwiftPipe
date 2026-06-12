// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/ExtractorLogger.java @ v0.26.3
//
// Deviation: upstream is a pluggable logging facade; this port is a no-op
// for now (the full pluggable logger lands with the app's error reporter).

public enum ExtractorLogger {
    public static func d(_ tag: String, _ message: String, _ args: Any?...) {}
}
