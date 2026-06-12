// JS execution seam for the extractor core.
//
// Upstream isolates its JavaScript engine (Rhino) behind
// extractor/src/main/java/org/schabi/newpipe/extractor/utils/JavaScript.java.
// The Swift mirror of that class will route through this protocol instead, so
// the core target never depends on JavaScriptCore and keeps compiling on
// Linux/Windows. The Apple implementation lives in SwiftPipeExtractorJS and is
// injected at app startup, alongside the Downloader (NewPipe.init style).

public protocol JavaScriptRunner: Sendable {
    /// Compiles the given function source, throwing on syntax errors without
    /// executing it. Mirror of JavaScript.compileOrThrow.
    func compileOrThrow(_ function: String) throws

    /// Evaluates the given source, then calls `functionName` with the given
    /// string parameters and returns the result coerced to a string.
    /// Mirror of JavaScript.run.
    func run(function: String, functionName: String, parameters: [String]) throws -> String
}

public enum JavaScriptRunnerError: Error, Sendable {
    case engineUnavailable
    case compilationFailed(String)
    case evaluationFailed(String)
    case functionNotFound(String)
}
