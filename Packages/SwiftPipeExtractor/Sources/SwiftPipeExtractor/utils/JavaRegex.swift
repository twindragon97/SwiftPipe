// No direct Java counterpart: a minimal shim of java.util.regex
// (Pattern/Matcher) over NSRegularExpression, so mirrored code keeps its
// `Pattern.compile(...)` constants and `matcher.find()/group(n)` call sites
// verbatim. NSRange/NSString are UTF-16 based, matching Java char semantics.
// Invalid patterns are programmer errors (Java: unchecked
// PatternSyntaxException) -> preconditionFailure.

import Foundation

public final class Pattern {
    let regex: NSRegularExpression
    private let patternString: String

    public static func compile(_ pattern: String) -> Pattern {
        Pattern(pattern)
    }

    init(_ pattern: String) {
        patternString = pattern
        do {
            regex = try NSRegularExpression(pattern: pattern)
        } catch {
            preconditionFailure("Invalid regex pattern: \(pattern) — \(error)")
        }
    }

    public func pattern() -> String {
        patternString
    }

    public func matcher(_ input: String) -> Matcher {
        Matcher(regex, input)
    }
}

public final class Matcher {
    private let regex: NSRegularExpression
    private let input: String
    private let nsInput: NSString
    private var searchStart = 0
    private var lastMatch: NSTextCheckingResult?

    init(_ regex: NSRegularExpression, _ input: String) {
        self.regex = regex
        self.input = input
        self.nsInput = input as NSString
    }

    /// Finds the next match, continuing after the previous one (Java semantics).
    @discardableResult
    public func find() -> Bool {
        guard searchStart <= nsInput.length else {
            lastMatch = nil
            return false
        }
        let range = NSRange(location: searchStart, length: nsInput.length - searchStart)
        guard let match = regex.firstMatch(in: input, range: range) else {
            lastMatch = nil
            return false
        }
        lastMatch = match
        searchStart = match.range.location + match.range.length
        if match.range.length == 0 {
            searchStart += 1 // avoid infinite loop on empty matches, like Java
        }
        return true
    }

    /// Whether the entire input matches the pattern.
    public func matches() -> Bool {
        let fullRange = NSRange(location: 0, length: nsInput.length)
        guard let match = regex.firstMatch(in: input, range: fullRange),
              match.range == fullRange else {
            return false
        }
        lastMatch = match
        return true
    }

    /// The whole match (group 0) of the last find().
    public func group() -> String? {
        group(0)
    }

    /// The given group of the last find(); nil if the group did not
    /// participate in the match (Java returns null there).
    public func group(_ index: Int) -> String? {
        guard let lastMatch else {
            preconditionFailure("No match available")
        }
        guard index >= 0 && index < lastMatch.numberOfRanges else {
            preconditionFailure("No group \(index)")
        }
        let range = lastMatch.range(at: index)
        if range.location == NSNotFound {
            return nil
        }
        return nsInput.substring(with: range)
    }
}
