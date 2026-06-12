// NanoJSON — faithful Swift port of TeamNewPipe/nanojson (Apache-2.0).
// Copyright 2011 The nanojson Authors; Swift port for SwiftPipe (GPL-3.0).
//
// Fidelity requirements (see docs/PORTING.md):
//  - JsonObject preserves key insertion order (Java: LinkedHashMap).
//  - JsonWriter output is byte-identical to the Java implementation for the
//    value types the extractor emits (strings, integers, booleans, nested
//    objects/arrays, null).
//
// Documented deviations from upstream (kept rare and behavior-preserving):
//  - Numbers/strings are parsed eagerly (upstream defaults to JsonLazyNumber/
//    LazyString as a perf optimization; consumers observe identical values).
//  - Integers beyond Int64 parse as Double (upstream: BigInteger). InnerTube
//    payloads never reach that range.
//  - Double formatting uses Swift's shortest round-trip form, which differs
//    from Java's Double.toString at exponent boundaries. Request bodies built
//    by the extractor contain no doubles.
//  - Streaming I/O entry points (JsonReader, JsonAppendableWriter, InputStream
//    sources) are not ported; the extractor only parses from String.
//  - Java's unchecked JsonWriterException maps to preconditionFailure with the
//    same messages (programmer error, never caught by the extractor).

public enum NanoJSON {
    /// Marker kept for the Phase 0 bootstrap test.
    public static let bootstrap = true
}
