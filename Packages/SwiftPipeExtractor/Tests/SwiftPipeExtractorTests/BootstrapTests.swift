import XCTest
import NanoJSON
@testable import SwiftPipeExtractor

final class BootstrapTests: XCTestCase {
    func testPackageTargetsAreWired() {
        XCTAssertTrue(SwiftPipeExtractor.bootstrap)
        XCTAssertTrue(NanoJSON.bootstrap)
    }
}

#if canImport(JavaScriptCore)
import SwiftPipeExtractorJS

/// Validates the Rhino → JavaScriptCore seam end to end (Apple platforms only;
/// the Linux CI job skips this suite because JavaScriptCore is unavailable).
final class JavaScriptCoreRunnerTests: XCTestCase {
    func testRunInvokesNamedFunctionWithParameters() throws {
        let result = try JavaScriptCoreRunner().run(
            function: "function deobfuscate(sig) { return sig.split('').reverse().join(''); }",
            functionName: "deobfuscate",
            parameters: ["abc123"]
        )
        XCTAssertEqual(result, "321cba")
    }

    func testCompileOrThrowAcceptsValidSource() throws {
        try JavaScriptCoreRunner().compileOrThrow("function f(a) { return a; }")
    }

    func testCompileOrThrowRejectsSyntaxError() {
        XCTAssertThrowsError(
            try JavaScriptCoreRunner().compileOrThrow("function f(a) { return a;")
        )
    }

    func testRunThrowsWhenFunctionMissing() {
        XCTAssertThrowsError(
            try JavaScriptCoreRunner().run(
                function: "function f(a) { return a; }",
                functionName: "missing",
                parameters: []
            )
        )
    }
}
#endif

/// Smoke tests for the freshly ported core utilities.
final class CoreUtilsTests: XCTestCase {
    func testEncodeUrlUtf8MatchesJavaURLEncoder() {
        XCTAssertEqual(Utils.encodeUrlUtf8("a b+ñ/"), "a+b%2B%C3%B1%2F")
        XCTAssertEqual(Utils.encodeUrlUtf8("AZaz09.-*_"), "AZaz09.-*_")
    }

    func testDecodeUrlUtf8MatchesJavaURLDecoder() {
        XCTAssertEqual(Utils.decodeUrlUtf8("a+b%2B%C3%B1%2F"), "a b+ñ/")
    }

    func testMixedNumberWordToLong() throws {
        XCTAssertEqual(try Utils.mixedNumberWordToLong("123"), 123)
        XCTAssertEqual(try Utils.mixedNumberWordToLong("1.23K"), 1230)
        XCTAssertEqual(try Utils.mixedNumberWordToLong("1.23M"), 1_230_000)
        XCTAssertEqual(try Utils.mixedNumberWordToLong("2,1B"), 2_100_000_000)
    }

    func testParserMatchGroup() throws {
        XCTAssertEqual(try Parser.matchGroup1("v=([a-zA-Z0-9_-]{11})",
                                              "https://www.youtube.com/watch?v=dQw4w9WgXcQ"),
                       "dQw4w9WgXcQ")
        XCTAssertThrowsError(try Parser.matchGroup1("(xyz)", "abc")) { error in
            XCTAssertTrue(error is Parser.RegexException)
        }
        XCTAssertTrue(Parser.isMatch("^http", "https://example.com"))
    }

    func testGetBaseUrl() throws {
        XCTAssertEqual(try Utils.getBaseUrl("https://www.youtube.com/watch?v=x"),
                       "https://www.youtube.com")
        XCTAssertEqual(try Utils.getBaseUrl("vnd.youtube://www.youtube.com/watch?v=x"),
                       "vnd.youtube")
    }

    func testMediaFormatLookupPreservesDeclarationOrder() {
        XCTAssertEqual(MediaFormat.getFormatById(0x200), .WEBMA)
        XCTAssertEqual(MediaFormat.MPEG_4.getSuffix(), "mp4")
    }
}

/// Smoke tests for the timeago port (English patterns).
final class TimeAgoTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testParsesRelativePhrases() throws {
        let parser = TimeAgoPatternsManager.getTimeAgoParserFor(Localization("en"), now)
        let weeks = try XCTUnwrap(parser).parse("3 weeks ago")
        XCTAssertTrue(weeks.isApproximation())
        XCTAssertLessThan(weeks.getInstant(), now)
        XCTAssertGreaterThan(
            weeks.getInstant(), now.addingTimeInterval(-23 * 24 * 3600))

        let seconds = try XCTUnwrap(parser).parse("10 seconds ago")
        XCTAssertFalse(seconds.isApproximation())
        XCTAssertEqual(
            seconds.getInstant().timeIntervalSince1970,
            now.timeIntervalSince1970 - 10,
            accuracy: 0.5)
    }

    func testUnparsableDateThrows() throws {
        let parser = try XCTUnwrap(
            TimeAgoPatternsManager.getTimeAgoParserFor(Localization("en"), now))
        XCTAssertThrowsError(try parser.parse("gibberish"))
    }

    func testUnsupportedLocalizationReturnsNil() {
        XCTAssertNil(TimeAgoPatternsManager.getTimeAgoParserFor(Localization("zz"), now))
        // Like Java: "en_GB" has no dedicated pattern class; the
        // language-only fallback lives in StreamingService.getTimeAgoParser.
        XCTAssertNil(TimeAgoPatternsManager.getTimeAgoParserFor(Localization("en", "GB"), now))
    }

    func testDateWrapperParsesIso8601() throws {
        let wrapped = try XCTUnwrap(
            DateWrapper.fromOffsetDateTime("2011-12-03T10:15:30+01:00"))
        XCTAssertEqual(
            wrapped.getInstant().timeIntervalSince1970,
            1_322_903_730, // 2011-12-03T09:15:30Z
            accuracy: 0.5)
        XCTAssertThrowsError(try DateWrapper.fromInstant("not a date"))
    }
}
