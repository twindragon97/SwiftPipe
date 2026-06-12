// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/Utils.java @ v0.26.3
//
// Deviations:
//  - encode/decodeUrlUtf8 reimplement java.net.URLEncoder/URLDecoder form
//    semantics (space <-> '+', uppercase %XX) over Foundation.
//  - stringToURL/getBaseUrl map java.net.URL parsing onto Foundation URL;
//    getBaseUrl keeps Java's unknown-protocol hack (returns just the scheme
//    for non-http(s) urls like vnd.youtube).
//  - mixedNumberWordToLong throws ParsingException where Java would throw an
//    unchecked NumberFormatException.
//  - join sorts map keys for determinism (Java HashMap order is arbitrary
//    but stable per-JVM; Swift Dictionary order is randomized per-process,
//    which would break recorded-mock matching).

import Foundation
import NanoJSON

public enum Utils {
    public static let HTTP = "http://"
    public static let HTTPS = "https://"

    private static let M_PATTERN = Pattern.compile("(https?)?://m\\.")
    private static let WWW_PATTERN = Pattern.compile("(https?)?://www\\.")

    private static let HEX_UPPER: [Character] = [
        "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "A", "B", "C", "D", "E", "F",
    ]

    public struct MalformedURLException: Error {
        public let message: String
    }

    /// Encodes a string to URL format using the UTF-8 character set
    /// (java.net.URLEncoder semantics: form encoding).
    public static func encodeUrlUtf8(_ string: String) -> String {
        var out = ""
        for byte in Array(string.utf8) {
            switch byte {
            case 0x30...0x39, 0x41...0x5A, 0x61...0x7A, // 0-9 A-Z a-z
                 0x2E, 0x2D, 0x2A, 0x5F: // . - * _
                out.append(Character(UnicodeScalar(byte)))
            case 0x20: // space
                out.append("+")
            default:
                out.append("%")
                out.append(HEX_UPPER[Int(byte >> 4)])
                out.append(HEX_UPPER[Int(byte & 0xF)])
            }
        }
        return out
    }

    /// Decodes a URL using the UTF-8 character set
    /// (java.net.URLDecoder semantics: '+' becomes space).
    public static func decodeUrlUtf8(_ url: String) -> String {
        let plusReplaced = url.replacingOccurrences(of: "+", with: " ")
        return plusReplaced.removingPercentEncoding ?? plusReplaced
    }

    /// Remove all non-digit characters from a string.
    public static func removeNonDigitCharacters(_ toRemove: String) -> String {
        toRemove.replacingOccurrences(of: "\\D+", with: "", options: .regularExpression)
    }

    /// Convert a mixed number word to a long: 123 -> 123, 1.23K -> 1230,
    /// 1.23M -> 1230000.
    public static func mixedNumberWordToLong(_ numberWord: String) throws -> Int64 {
        var multiplier = ""
        do {
            multiplier = try Parser.matchGroup(
                "[\\d]+([\\.,][\\d]+)?([KMBkmb])+", numberWord, 2)
        } catch is ParsingException {
            // ignored
        }
        let countString = try Parser.matchGroup1("([\\d]+([\\.,][\\d]+)?)", numberWord)
            .replacingOccurrences(of: ",", with: ".")
        guard let count = Double(countString) else {
            throw ParsingException("Malformed number: \(numberWord)")
        }
        switch multiplier.uppercased() {
        case "K":
            return Int64(count * 1e3)
        case "M":
            return Int64(count * 1e6)
        case "B":
            return Int64(count * 1e9)
        default:
            return Int64(count)
        }
    }

    /// Check if the url matches the pattern.
    public static func checkUrl(_ pattern: String, _ url: String) throws {
        try checkUrl(Pattern.compile(pattern), url)
    }

    /// Check if the url matches the pattern.
    public static func checkUrl(_ pattern: Pattern, _ url: String) throws {
        precondition(!isNullOrEmpty(url), "Url can't be null or empty")
        if !Parser.isMatch(pattern, url.lowercased()) {
            throw ParsingException("Url doesn't match the pattern")
        }
    }

    public static func replaceHttpWithHttps(_ url: String?) -> String? {
        guard let url else { return nil }
        if url.hasPrefix(HTTP) {
            return HTTPS + url.dropFirst(HTTP.count)
        }
        return url
    }

    /// Get the value of a URL-query by name; if a query is given multiple
    /// times, only the value of the first query is returned.
    public static func getQueryValue(_ url: URL, _ parameterName: String) -> String? {
        guard let urlQuery = url.query else { return nil }
        for param in urlQuery.components(separatedBy: "&") {
            let params = param.components(separatedBy: "=")
            let query = decodeUrlUtf8(params[0])
            if query == parameterName {
                return params.count > 1 ? decodeUrlUtf8(params[1]) : ""
            }
        }
        return nil
    }

    /// Convert a string to a URL object; defaults to HTTPS if no protocol is
    /// given.
    public static func stringToURL(_ url: String) throws -> URL {
        guard let parsed = URL(string: url) else {
            throw MalformedURLException(message: "malformed url: \(url)")
        }
        if parsed.scheme == nil {
            guard let retried = URL(string: HTTPS + url) else {
                throw MalformedURLException(message: "malformed url: \(url)")
            }
            return retried
        }
        return parsed
    }

    public static func isHTTP(_ url: URL) -> Bool {
        // Make sure it's HTTP or HTTPS
        guard let scheme = url.scheme, scheme == "http" || scheme == "https" else {
            return false
        }
        guard let port = url.port else {
            return true // sets no port
        }
        return (scheme == "http" && port == 80) || (scheme == "https" && port == 443)
    }

    public static func removeMAndWWWFromUrl(_ url: String) -> String {
        if M_PATTERN.matcher(url).find() {
            return url.replacingOccurrences(of: "m.", with: "")
        }
        if WWW_PATTERN.matcher(url).find() {
            return url.replacingOccurrences(of: "www.", with: "")
        }
        return url
    }

    public static func removeUTF8BOM(_ s: String) -> String {
        var result = s
        if result.hasPrefix("\u{FEFF}") {
            result = String(result.dropFirst())
        }
        if result.hasSuffix("\u{FEFF}") {
            result = String(result.dropLast())
        }
        return result
    }

    public static func getBaseUrl(_ url: String) throws -> String {
        let uri: URL
        do {
            uri = try stringToURL(url)
        } catch is MalformedURLException {
            throw ParsingException("Malformed url: \(url)")
        }
        guard let scheme = uri.scheme else {
            throw ParsingException("Malformed url: \(url)")
        }
        if scheme == "http" || scheme == "https" {
            var authority = uri.host ?? ""
            if let port = uri.port {
                authority += ":\(port)"
            }
            return scheme + "://" + authority
        }
        // Mirror of Java's unknown-protocol path: return just the protocol
        // (e.g. vnd.youtube)
        return scheme
    }

    /// If the provided url is a Google search redirect, extract and return
    /// the actual url, otherwise return the original url.
    public static func followGoogleRedirectIfNeeded(_ url: String) -> String {
        if let decoded = try? stringToURL(url),
           let host = decoded.host,
           host.contains("google"), decoded.path == "/url",
           let target = try? Parser.matchGroup1("&url=([^&]+)(?:&|$)", url) {
            return decodeUrlUtf8(target)
        }
        // URL is not a Google search redirect
        return url
    }

    public static func isNullOrEmpty(_ str: String?) -> Bool {
        str == nil || str!.isEmpty
    }

    public static func isNullOrEmpty<T>(_ collection: [T]?) -> Bool {
        collection == nil || collection!.isEmpty
    }

    public static func isNullOrEmpty<K, V>(_ map: [K: V]?) -> Bool {
        map == nil || map!.isEmpty
    }

    public static func isNullOrEmpty(_ array: JsonArray?) -> Bool {
        array == nil || array!.isEmpty
    }

    public static func isNullOrEmpty(_ object: JsonObject?) -> Bool {
        object == nil || object!.isEmpty
    }

    public static func isBlank(_ string: String?) -> Bool {
        guard let string else { return true }
        return string.allSatisfy { $0.isWhitespace }
    }

    /// Joins map entries as "key<mapJoin>value" separated by delimiter.
    /// Deviation: keys are sorted for determinism (see file header).
    public static func join(
        _ delimiter: String, _ mapJoin: String, _ elements: [String: String]
    ) -> String {
        elements.keys.sorted()
            .map { "\($0)\(mapJoin)\(elements[$0]!)" }
            .joined(separator: delimiter)
    }

    /// Concatenate all non-null, non-empty strings which are not equal to
    /// "null".
    public static func nonEmptyAndNullJoin(
        _ delimiter: String, _ elements: String?...
    ) -> String {
        elements
            .compactMap { $0 }
            .filter { !$0.isEmpty && $0 != "null" }
            .joined(separator: delimiter)
    }

    public static func getStringResultFromRegexArray(
        _ input: String, _ regexes: [String?], _ group: Int = 0
    ) throws -> String {
        try getStringResultFromRegexArray(
            input, regexes.compactMap { $0 }.map(Pattern.compile), group)
    }

    public static func getStringResultFromRegexArray(
        _ input: String, _ regexes: [Pattern], _ group: Int = 0
    ) throws -> String {
        for regex in regexes {
            do {
                return try Parser.matchGroup(regex, input, group)
            } catch is Parser.RegexException {
                // Continue with the next pattern
            }
        }
        throw Parser.RegexException("No regex matched the input on group \(group)")
    }
}
