// Mirrors: timeago-parser/src/main/java/org/schabi/newpipe/extractor/timeago/PatternsManager.java @ v0.26.3
//
// Java resolves the generated locale class by name; Swift uses an explicit
// registry. Locales are added here as their pattern classes are ported.

public enum PatternsManager {
    /// Returns a holder object containing all the patterns, or nil if the
    /// localization has no patterns ported yet.
    public static func getPatterns(
        _ languageCode: String, _ countryCode: String?
    ) -> PatternsHolder? {
        let targetName = languageCode
            + ((countryCode == nil || countryCode!.isEmpty) ? "" : "_" + countryCode!)
        return PatternMap.getPattern(targetName)
    }
}

enum PatternMap {
    private static let patterns: [String: PatternsHolder] = [
        "en": en.getInstance()
    ]

    static func getPattern(_ name: String) -> PatternsHolder? {
        patterns[name]
    }
}
