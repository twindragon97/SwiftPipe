// No direct Java counterpart: helpers replicating java.lang.Number coercion
// semantics (intValue/longValue/doubleValue narrowing) for values stored as
// Swift Any. Java narrows long->int by truncation and double->int/long by
// saturation (NaN -> 0), per JLS 5.1.3.

enum JavaNumber {
    static func isNumber(_ v: Any) -> Bool {
        switch v {
        case is Int, is Int64, is Int32, is UInt, is UInt32, is UInt64, is Double, is Float:
            return true
        default:
            return false
        }
    }

    static func intValue(_ v: Any) -> Int? {
        switch v {
        case let i as Int: return Int(Int32(truncatingIfNeeded: i))
        case let i as Int64: return Int(Int32(truncatingIfNeeded: i))
        case let i as Int32: return Int(i)
        case let i as UInt: return Int(Int32(truncatingIfNeeded: Int64(bitPattern: UInt64(i))))
        case let d as Double: return saturatingInt32(d)
        case let f as Float: return saturatingInt32(Double(f))
        default: return nil
        }
    }

    static func longValue(_ v: Any) -> Int64? {
        switch v {
        case let i as Int: return Int64(i)
        case let i as Int64: return i
        case let i as Int32: return Int64(i)
        case let i as UInt: return Int64(bitPattern: UInt64(i))
        case let d as Double: return saturatingInt64(d)
        case let f as Float: return saturatingInt64(Double(f))
        default: return nil
        }
    }

    static func doubleValue(_ v: Any) -> Double? {
        switch v {
        case let i as Int: return Double(i)
        case let i as Int64: return Double(i)
        case let i as Int32: return Double(i)
        case let i as UInt: return Double(i)
        case let d as Double: return d
        case let f as Float: return Double(f)
        default: return nil
        }
    }

    static func floatValue(_ v: Any) -> Float? {
        doubleValue(v).map { Float($0) }
    }

    /// Java Number.toString() for the writer. Integer types match Java
    /// exactly; Double uses Swift's formatting (documented deviation).
    static func toJavaString(_ v: Any) -> String? {
        switch v {
        case let i as Int: return String(i)
        case let i as Int64: return String(i)
        case let i as Int32: return String(i)
        case let i as UInt: return String(i)
        case let d as Double: return String(d)
        case let f as Float: return String(f)
        default: return nil
        }
    }

    static func isNaNOrInfinite(_ v: Any) -> Bool {
        switch v {
        case let d as Double: return d.isNaN || d.isInfinite
        case let f as Float: return f.isNaN || f.isInfinite
        default: return false
        }
    }

    private static func saturatingInt32(_ d: Double) -> Int {
        if d.isNaN { return 0 }
        if d >= 2147483647 { return 2147483647 }
        if d <= -2147483648 { return -2147483648 }
        return Int(d)
    }

    private static func saturatingInt64(_ d: Double) -> Int64 {
        if d.isNaN { return 0 }
        if d >= 9223372036854775807 { return Int64.max }
        if d <= -9223372036854775808 { return Int64.min }
        return Int64(d)
    }
}
