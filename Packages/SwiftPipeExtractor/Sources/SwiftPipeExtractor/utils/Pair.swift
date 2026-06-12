// Mirrors: extractor/src/main/java/org/schabi/newpipe/extractor/utils/Pair.java @ v0.26.3

public final class Pair<F: Hashable, S: Hashable>: Hashable, CustomStringConvertible {
    private var firstObject: F
    private var secondObject: S

    public init(_ first: F, _ second: S) {
        firstObject = first
        secondObject = second
    }

    public func setFirst(_ first: F) {
        firstObject = first
    }

    public func setSecond(_ second: S) {
        secondObject = second
    }

    public func getFirst() -> F {
        firstObject
    }

    public func getSecond() -> S {
        secondObject
    }

    public var description: String {
        "{\(firstObject), \(secondObject)}"
    }

    public static func == (lhs: Pair<F, S>, rhs: Pair<F, S>) -> Bool {
        lhs.firstObject == rhs.firstObject && lhs.secondObject == rhs.secondObject
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(firstObject)
        hasher.combine(secondObject)
    }
}
