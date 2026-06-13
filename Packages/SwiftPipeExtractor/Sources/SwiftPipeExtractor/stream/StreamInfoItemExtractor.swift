// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/stream/StreamInfoItemExtractor.java @ v0.26.3
//
// Java default methods become protocol-extension defaults.

public protocol StreamInfoItemExtractor: InfoItemExtractor {
    func getStreamType() throws -> StreamType
    func isAd() throws -> Bool
    func getDuration() throws -> Int64
    func getViewCount() throws -> Int64
    func getUploaderName() throws -> String?
    func getUploaderUrl() throws -> String?
    func getUploaderAvatars() throws -> [Image]
    func isUploaderVerified() throws -> Bool
    func getTextualUploadDate() throws -> String?
    func getUploadDate() throws -> DateWrapper?
    func getShortDescription() throws -> String?
    func isShortFormContent() throws -> Bool
    func getContentAvailability() throws -> ContentAvailability
}

public extension StreamInfoItemExtractor {
    func getUploaderAvatars() throws -> [Image] {
        []
    }

    func getShortDescription() throws -> String? {
        nil
    }

    func isShortFormContent() throws -> Bool {
        false
    }

    func getContentAvailability() throws -> ContentAvailability {
        .UNKNOWN
    }
}
