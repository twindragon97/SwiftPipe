// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/Parser.java @ v0.26.3
//
// Deviation: matchGroup throws RegexException when the requested group did
// not participate in the match (Java would return null despite @Nonnull);
// call sites that check for null (e.g. getStringResultFromRegexArray) treat
// the throw the same way they treated null.

public enum Parser {
    public final class RegexException: ParsingException {}

    @discardableResult
    public static func matchOrThrow(_ pattern: Pattern, _ input: String) throws -> Matcher {
        let matcher = pattern.matcher(input)
        if matcher.find() {
            return matcher
        }
        var errorMessage = "Failed to find pattern \"\(pattern.pattern())\""
        if input.count <= 1024 {
            errorMessage += " inside of \"\(input)\""
        }
        throw RegexException(errorMessage)
    }

    public static func matchGroup1(_ pattern: String, _ input: String) throws -> String {
        try matchGroup(pattern, input, 1)
    }

    public static func matchGroup1(_ pattern: Pattern, _ input: String) throws -> String {
        try matchGroup(pattern, input, 1)
    }

    public static func matchGroup(
        _ pattern: String, _ input: String, _ group: Int
    ) throws -> String {
        try matchGroup(Pattern.compile(pattern), input, group)
    }

    public static func matchGroup(
        _ pattern: Pattern, _ input: String, _ group: Int
    ) throws -> String {
        guard let result = try matchOrThrow(pattern, input).group(group) else {
            throw RegexException(
                "Group \(group) did not participate in match of pattern "
                + "\"\(pattern.pattern())\"")
        }
        return result
    }

    public static func matchGroup1MultiplePatterns(
        _ patterns: [Pattern], _ input: String
    ) throws -> String {
        guard let result = try matchMultiplePatterns(patterns, input).group(1) else {
            throw RegexException("Group 1 did not participate in match")
        }
        return result
    }

    public static func matchMultiplePatterns(
        _ patterns: [Pattern], _ input: String
    ) throws -> Matcher {
        var exception: RegexException?
        for pattern in patterns {
            let matcher = pattern.matcher(input)
            if matcher.find() {
                return matcher
            } else if exception == nil {
                // only pass input to exception message when it is not too long
                exception = RegexException(
                    "Failed to find pattern \"\(pattern.pattern())\""
                    + (input.count <= 1000 ? "inside of \"\(input)\"" : ""))
            }
        }
        throw exception
            ?? RegexException("Empty patterns array passed to matchMultiplePatterns")
    }

    public static func isMatch(_ pattern: String, _ input: String) -> Bool {
        isMatch(Pattern.compile(pattern), input)
    }

    public static func isMatch(_ pattern: Pattern, _ input: String) -> Bool {
        pattern.matcher(input).find()
    }

    public static func compatParseMap(_ input: String) -> [String: String] {
        var map: [String: String] = [:]
        for arg in input.components(separatedBy: "&") {
            let splitArg = arg.components(separatedBy: "=")
            if splitArg.count > 1 {
                map[splitArg[0]] = Utils.decodeUrlUtf8(splitArg[1])
            }
        }
        return map
    }
}
