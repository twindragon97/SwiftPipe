// NanoJSON — faithful Swift port of TeamNewPipe/nanojson (MIT).
//
// The real port lands in Phase 1. Two hard requirements, see docs/PORTING.md:
//  - JsonObject must preserve key insertion order (Java: LinkedHashMap).
//  - JsonWriter output must be byte-identical to the Java implementation,
//    because extractor mock tests match recorded requests by exact POST body.

public enum NanoJSON {
    /// Placeholder used by the Phase 0 bootstrap tests.
    public static let bootstrap = true
}
