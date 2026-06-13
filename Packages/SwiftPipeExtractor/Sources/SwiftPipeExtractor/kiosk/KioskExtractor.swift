// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/kiosk/KioskExtractor.java @ v0.26.3
//
// Deviation: Java's KioskList uses the raw type `KioskExtractor` (unchecked);
// Swift forbids generics as raw types, so KioskList holds `any
// AnyKioskExtractor` (this protocol) for the surface it needs.

/// Type-erased view of a KioskExtractor for KioskList's storage.
public protocol AnyKioskExtractor: AnyObject {
    func forceLocalization(_ localization: Localization)
    func forceContentCountry(_ contentCountry: ContentCountry)
}

open class KioskExtractor<T: InfoItem>: ListExtractor<T>, AnyKioskExtractor {
    private let id: String

    public init(
        _ streamingService: StreamingService,
        _ linkHandler: ListLinkHandler,
        _ kioskId: String
    ) {
        self.id = kioskId
        super.init(streamingService, linkHandler)
    }

    open override func getId() throws -> String {
        id
    }

    open override func getName() throws -> String {
        preconditionFailure("KioskExtractor.getName must be overridden")
    }
}
