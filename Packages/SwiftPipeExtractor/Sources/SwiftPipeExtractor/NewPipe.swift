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

    // TODO(P1-core): getServices/getService(id)/getService(name)/getServiceByUrl
    // arrive with StreamingService and ServiceList.

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
