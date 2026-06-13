// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/suggestion/SuggestionExtractor.java @ v0.26.3

open class SuggestionExtractor {
    private let service: StreamingService
    private var forcedLocalization: Localization?
    private var forcedContentCountry: ContentCountry?

    public init(_ service: StreamingService) {
        self.service = service
    }

    open func suggestionList(_ query: String) throws -> [String] {
        preconditionFailure("SuggestionExtractor.suggestionList must be overridden")
    }

    public func getServiceId() -> Int {
        service.getServiceId()
    }

    public func getService() -> StreamingService {
        service
    }

    // TODO: Create a more general Extractor class
    public func forceLocalization(_ localization: Localization?) {
        forcedLocalization = localization
    }

    public func forceContentCountry(_ contentCountry: ContentCountry?) {
        forcedContentCountry = contentCountry
    }

    public func getExtractorLocalization() -> Localization {
        forcedLocalization ?? getService().getLocalization()
    }

    public func getExtractorContentCountry() -> ContentCountry {
        forcedContentCountry ?? getService().getContentCountry()
    }
}
