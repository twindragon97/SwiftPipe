// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/kiosk/KioskList.java @ v0.26.3
//
// Deviation: KioskExtractor instances are held as `any AnyKioskExtractor`
// (see KioskExtractor.swift) because Swift forbids Java's raw generic type.
// The dictionary preserves insertion order so getDefaultKioskExtractor's
// "find any" branch is deterministic (Java HashMap order is arbitrary).

import Foundation

public final class KioskList {
    public typealias KioskExtractorFactory =
        (_ streamingService: StreamingService, _ url: String, _ kioskId: String)
        throws -> any AnyKioskExtractor

    private let service: StreamingService
    private var kioskList: [String: KioskEntry] = [:]
    private var insertionOrder: [String] = []
    private var defaultKiosk: String?
    private var forcedLocalization: Localization?
    private var forcedContentCountry: ContentCountry?

    private struct KioskEntry {
        let extractorFactory: KioskExtractorFactory
        let handlerFactory: ListLinkHandlerFactory
    }

    public struct KioskException: Error {
        public let message: String
    }

    public init(_ service: StreamingService) {
        self.service = service
    }

    public func addKioskEntry(
        _ extractorFactory: @escaping KioskExtractorFactory,
        _ handlerFactory: ListLinkHandlerFactory,
        _ id: String
    ) throws {
        if kioskList[id] != nil {
            throw KioskException(message: "Kiosk with type \(id) already exists.")
        }
        kioskList[id] = KioskEntry(
            extractorFactory: extractorFactory, handlerFactory: handlerFactory)
        insertionOrder.append(id)
    }

    public func setDefaultKiosk(_ kioskType: String) {
        defaultKiosk = kioskType
    }

    public func getDefaultKioskExtractor() throws -> (any AnyKioskExtractor)? {
        try getDefaultKioskExtractor(nil)
    }

    public func getDefaultKioskExtractor(_ nextPage: Page?) throws -> (any AnyKioskExtractor)? {
        try getDefaultKioskExtractor(nextPage, NewPipe.getPreferredLocalization())
    }

    public func getDefaultKioskExtractor(
        _ nextPage: Page?, _ localization: Localization
    ) throws -> (any AnyKioskExtractor)? {
        if let defaultKiosk, !defaultKiosk.isEmpty {
            return try getExtractorById(defaultKiosk, nextPage, localization)
        }
        // if not set get any entry (first by insertion order, deterministic)
        guard let first = insertionOrder.first else {
            return nil
        }
        return try getExtractorById(first, nextPage, localization)
    }

    public func getDefaultKioskId() -> String? {
        defaultKiosk
    }

    public func getExtractorById(
        _ kioskId: String, _ nextPage: Page?
    ) throws -> any AnyKioskExtractor {
        try getExtractorById(kioskId, nextPage, NewPipe.getPreferredLocalization())
    }

    public func getExtractorById(
        _ kioskId: String, _ nextPage: Page?, _ localization: Localization
    ) throws -> any AnyKioskExtractor {
        guard let ke = kioskList[kioskId] else {
            throw ExtractionException("No kiosk found with the type: \(kioskId)")
        }
        let kioskExtractor = try ke.extractorFactory(
            service, try ke.handlerFactory.fromId(kioskId).getUrl(), kioskId)
        if let forcedLocalization {
            kioskExtractor.forceLocalization(forcedLocalization)
        }
        if let forcedContentCountry {
            kioskExtractor.forceContentCountry(forcedContentCountry)
        }
        return kioskExtractor
    }

    public func getAvailableKiosks() -> Set<String> {
        Set(kioskList.keys)
    }

    public func getExtractorByUrl(
        _ url: String, _ nextPage: Page?
    ) throws -> any AnyKioskExtractor {
        try getExtractorByUrl(url, nextPage, NewPipe.getPreferredLocalization())
    }

    public func getExtractorByUrl(
        _ url: String, _ nextPage: Page?, _ localization: Localization
    ) throws -> any AnyKioskExtractor {
        for id in insertionOrder {
            let ke = kioskList[id]!
            if try ke.handlerFactory.acceptUrl(url) {
                return try getExtractorById(
                    try ke.handlerFactory.getId(url), nextPage, localization)
            }
        }
        throw ExtractionException("Could not find a kiosk that fits to the url: \(url)")
    }

    public func getListLinkHandlerFactoryByType(_ type: String) -> ListLinkHandlerFactory {
        kioskList[type]!.handlerFactory
    }

    public func forceLocalization(_ localization: Localization?) {
        forcedLocalization = localization
    }

    public func forceContentCountry(_ contentCountry: ContentCountry?) {
        forcedContentCountry = contentCountry
    }
}
