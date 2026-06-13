// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/NewPipe.java @ v0.26.3
//
// Java's NewPipe.init(...) maps to NewPipe.initialize(...) because `init` is
// reserved in Swift (porting convention). The service lookup methods
// (getServices/getService/getServiceByUrl) land together with
// StreamingService/ServiceList in the core phase. ExtractorLogger calls are
// omitted for now.

/// Provides access to streaming services supported by NewPipe.
public enum NewPipe {
    private static var downloader: Downloader?
    private static var preferredLocalization: Localization?
    private static var preferredContentCountry: ContentCountry?

    public static func initialize(_ d: Downloader) {
        initialize(d, Localization.DEFAULT)
    }

    public static func initialize(_ d: Downloader, _ l: Localization) {
        initialize(
            d, l,
            l.getCountryCode().isEmpty
                ? ContentCountry.DEFAULT : ContentCountry(l.getCountryCode()))
    }

    public static func initialize(
        _ d: Downloader, _ l: Localization, _ c: ContentCountry
    ) {
        downloader = d
        preferredLocalization = l
        preferredContentCountry = c
    }

    public static func getDownloader() -> Downloader! {
        downloader
    }

    // MARK: Utils

    public static func getServices() -> [StreamingService] {
        ServiceList.all()
    }

    public static func getService(_ serviceId: Int) throws -> StreamingService {
        guard let service = ServiceList.all().first(where: { $0.getServiceId() == serviceId })
        else {
            throw ExtractionException("There's no service with the id = \"\(serviceId)\"")
        }
        return service
    }

    public static func getService(_ serviceName: String) throws -> StreamingService {
        guard let service = ServiceList.all().first(
            where: { $0.getServiceInfo().getName() == serviceName })
        else {
            throw ExtractionException("There's no service with the name = \"\(serviceName)\"")
        }
        return service
    }

    public static func getServiceByUrl(_ url: String) throws -> StreamingService {
        for service in ServiceList.all() {
            if try service.getLinkTypeByUrl(url) != .NONE {
                return service
            }
        }
        throw ExtractionException("No service can handle the url = \"\(url)\"")
    }

    // MARK: Localization

    public static func setupLocalization(_ thePreferredLocalization: Localization) {
        setupLocalization(thePreferredLocalization, nil)
    }

    public static func setupLocalization(
        _ thePreferredLocalization: Localization,
        _ thePreferredContentCountry: ContentCountry?
    ) {
        preferredLocalization = thePreferredLocalization

        if let thePreferredContentCountry {
            preferredContentCountry = thePreferredContentCountry
        } else {
            preferredContentCountry =
                thePreferredLocalization.getCountryCode().isEmpty
                ? ContentCountry.DEFAULT
                : ContentCountry(thePreferredLocalization.getCountryCode())
        }
    }

    public static func getPreferredLocalization() -> Localization {
        preferredLocalization ?? Localization.DEFAULT
    }

    public static func setPreferredLocalization(_ localization: Localization) {
        preferredLocalization = localization
    }

    public static func getPreferredContentCountry() -> ContentCountry {
        preferredContentCountry ?? ContentCountry.DEFAULT
    }

    public static func setPreferredContentCountry(_ contentCountry: ContentCountry) {
        preferredContentCountry = contentCountry
    }
}
