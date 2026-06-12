#if canImport(JavaScriptCore)
import JavaScriptCore
import SwiftPipeExtractor

/// JavaScriptCore-backed implementation of JavaScriptRunner.
///
/// Behavioral mirror of upstream's utils/JavaScript.java, which runs Rhino in
/// interpreted mode with safe standard objects: each call gets a fresh,
/// isolated context, evaluates the function source, and invokes the named
/// function with string arguments.
public struct JavaScriptCoreRunner: JavaScriptRunner {
    public init() {}

    public func compileOrThrow(_ function: String) throws {
        guard let context = JSContext() else {
            throw JavaScriptRunnerError.engineUnavailable
        }
        var thrown: String?
        context.exceptionHandler = { _, exception in
            thrown = exception?.toString() ?? "unknown JavaScript error"
        }
        // Wrapping in a closure parses and compiles the body without executing
        // it, matching Rhino's Context.compileString semantics.
        context.evaluateScript("(function(){\n" + function + "\n})")
        if let thrown {
            throw JavaScriptRunnerError.compilationFailed(thrown)
        }
    }

    public func run(function: String, functionName: String, parameters: [String]) throws -> String {
        guard let context = JSContext() else {
            throw JavaScriptRunnerError.engineUnavailable
        }
        var thrown: String?
        context.exceptionHandler = { _, exception in
            thrown = exception?.toString() ?? "unknown JavaScript error"
        }

        context.evaluateScript(function)
        if let thrown {
            throw JavaScriptRunnerError.evaluationFailed(thrown)
        }

        guard let jsFunction = context.objectForKeyedSubscript(functionName),
              !jsFunction.isUndefined else {
            throw JavaScriptRunnerError.functionNotFound(functionName)
        }

        let result = jsFunction.call(withArguments: parameters)
        if let thrown {
            throw JavaScriptRunnerError.evaluationFailed(thrown)
        }
        guard let result, !result.isUndefined, let string = result.toString() else {
            throw JavaScriptRunnerError.evaluationFailed("function returned no result")
        }
        return string
    }
}
#endif
