// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/exceptions/UnsupportedTabException.java @ v0.26.3
//
// Java extends the unchecked UnsupportedOperationException; in Swift it is a
// thrown Error (the link-handler getUrl methods are `throws`).

public struct UnsupportedTabException: Error, CustomStringConvertible {
    public let description: String

    public init(_ unsupportedTab: String) {
        self.description = "Unsupported tab " + unsupportedTab
    }
}
