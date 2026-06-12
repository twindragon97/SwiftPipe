// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/InfoItemExtractor.java @ v0.26.3

public protocol InfoItemExtractor {
    func getName() throws -> String
    func getUrl() throws -> String
    func getThumbnails() throws -> [Image]
}
