// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/LocaleCompat.java @ v0.26.3
//
// Deviation: Java's Locale.forLanguageTag compatibility shim maps onto
// Foundation Locale. BCP-47 tags ("en", "en-GB", "fil") become Locale
// identifiers with "_" separators; empty/blank tags return nil.

import Foundation

public enum LocaleCompat {
    public static func forLanguageTag(_ languageTag: String) -> Locale? {
        let trimmed = languageTag.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        let identifier = trimmed.replacingOccurrences(of: "-", with: "_")
        return Locale(identifier: identifier)
    }
}
