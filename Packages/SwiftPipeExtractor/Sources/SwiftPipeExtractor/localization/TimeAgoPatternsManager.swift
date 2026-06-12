// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/localization/TimeAgoPatternsManager.java @ v0.26.3

import Foundation
import TimeAgoParser

public enum TimeAgoPatternsManager {
    private static func getPatternsFor(_ localization: Localization) -> PatternsHolder? {
        PatternsManager.getPatterns(
            localization.getLanguageCode(), localization.getCountryCode())
    }

    public static func getTimeAgoParserFor(_ localization: Localization) -> TimeAgoParser? {
        getTimeAgoParserFor(localization, Date())
    }

    public static func getTimeAgoParserFor(
        _ localization: Localization, _ now: Date
    ) -> TimeAgoParser? {
        guard let holder = getPatternsFor(localization) else { return nil }
        return TimeAgoParser(holder, now)
    }
}
