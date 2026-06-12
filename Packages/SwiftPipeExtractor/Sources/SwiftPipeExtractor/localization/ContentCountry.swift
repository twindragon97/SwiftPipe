// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/localization/ContentCountry.java @ v0.26.3

public final class ContentCountry: Hashable, CustomStringConvertible {
    public static let DEFAULT = ContentCountry(Localization.DEFAULT.getCountryCode())

    private let countryCode: String

    public static func listFrom(_ countryCodeList: String...) -> [ContentCountry] {
        countryCodeList.map { ContentCountry($0) }
    }

    public init(_ countryCode: String) {
        self.countryCode = countryCode
    }

    public func getCountryCode() -> String {
        countryCode
    }

    public var description: String {
        getCountryCode()
    }

    public static func == (lhs: ContentCountry, rhs: ContentCountry) -> Bool {
        lhs.countryCode == rhs.countryCode
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(countryCode)
    }
}
