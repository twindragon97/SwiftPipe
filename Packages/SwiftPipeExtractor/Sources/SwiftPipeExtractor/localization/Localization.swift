// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/localization/Localization.java @ v0.26.3
//
// Deviation: fromLocale/fromLocalizationCode parse identifiers directly
// instead of going through java.util.Locale/LocaleCompat (ported with the
// localization package in the core phase). getLocaleFromThreeLetterCode is
// deferred until the localization package lands.

import Foundation

public final class Localization: Hashable, CustomStringConvertible {
    public static let DEFAULT = Localization("en", "GB")

    private let languageCode: String
    private let countryCode: String?

    public init(_ languageCode: String, _ countryCode: String? = nil) {
        self.languageCode = languageCode
        self.countryCode = countryCode
    }

    /// Returns a list of Localization objects from localization codes
    /// formatted like getLocalizationCode().
    public static func listFrom(_ localizationCodeList: String...) -> [Localization] {
        localizationCodeList.map { code in
            guard let localization = fromLocalizationCode(code) else {
                preconditionFailure("Not a localization code: \(code)")
            }
            return localization
        }
    }

    /// A Localization, if the code was valid (e.g. "en" or "en-GB").
    public static func fromLocalizationCode(_ localizationCode: String) -> Localization? {
        let parts = localizationCode.split(
            whereSeparator: { $0 == "-" || $0 == "_" }
        ).map(String.init)
        switch parts.count {
        case 1:
            return Localization(parts[0])
        case 2...:
            return Localization(parts[0], parts[1])
        default:
            return nil
        }
    }

    public static func fromLocale(_ locale: Locale) -> Localization {
        fromLocalizationCode(locale.identifier) ?? DEFAULT
    }

    public func getLanguageCode() -> String {
        languageCode
    }

    public func getCountryCode() -> String {
        countryCode ?? ""
    }

    /// A formatted string in the form of "language-Country", or just
    /// "language" if country is nil.
    public func getLocalizationCode() -> String {
        languageCode + (countryCode == nil ? "" : "-" + countryCode!)
    }

    public var description: String {
        "Localization[\(getLocalizationCode())]"
    }

    public static func == (lhs: Localization, rhs: Localization) -> Bool {
        lhs.languageCode == rhs.languageCode && lhs.countryCode == rhs.countryCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(languageCode)
        hasher.combine(countryCode)
    }
}
