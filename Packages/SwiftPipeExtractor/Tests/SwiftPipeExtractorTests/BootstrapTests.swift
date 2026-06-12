import XCTest
import NanoJSON
import TimeAgoParser
@testable import SwiftPipeExtractor

final class BootstrapTests: XCTestCase {
    func testPackageTargetsAreWired() {
        XCTAssertTrue(SwiftPipeExtractor.bootstrap)
        XCTAssertTrue(NanoJSON.bootstrap)
        XCTAssertTrue(TimeAgoParser.bootstrap)
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
