// Mirrors: nanojson:src/main/java/com/grack/nanojson/JsonTokener.java @ c7a6c1c
//
// Java tokenizes from a streaming Reader with an internal char buffer; the
// extractor only ever parses from String, so this port operates on the
// string's UTF-16 code units in a single buffer (matching Java char
// semantics, including surrogate pairs from \uXXXX escapes). Token grammar,
// the number-validation state machine and all error messages/positions are
// mirrored exactly. The streaming InputStream/charset-detection paths are not
// ported (documented deviation).

final class JsonTokener {
    static let BUFFER_ROOM = 256
    static let MAX_ESCAPE = 5 // uXXXX (don't need the leading slash)

    private var linePos = 1
    private var rowPos = 0
    private var charOffset = 0
    private var utf8adjust = 0
    private var tokenCharPos = 0
    private var tokenCharOffset = 0

    private var eof: Bool
    private var index = 0
    private let buffer: [UInt16]
    private let bufferLength: Int

    private(set) var reusableBuffer: [UInt16] = []
    private(set) var isDouble = false

    // ASCII code units
    private static let chQuote: UInt16 = 0x22, chBackslash: UInt16 = 0x5C
    private static let chSlash: UInt16 = 0x2F, chPlus: UInt16 = 0x2B
    private static let chMinus: UInt16 = 0x2D, chDot: UInt16 = 0x2E
    private static let ch0: UInt16 = 0x30, ch9: UInt16 = 0x39

    static let TRUE: [UInt16] = [0x72, 0x75, 0x65]        // "rue"
    static let FALSE: [UInt16] = [0x61, 0x6C, 0x73, 0x65] // "alse"
    static let NULL: [UInt16] = [0x75, 0x6C, 0x6C]        // "ull"

    static let TOKEN_EOF = 0
    static let TOKEN_COMMA = 1
    static let TOKEN_COLON = 2
    static let TOKEN_OBJECT_END = 3
    static let TOKEN_ARRAY_END = 4
    static let TOKEN_NULL = 5
    static let TOKEN_TRUE = 6
    static let TOKEN_FALSE = 7
    static let TOKEN_STRING = 8
    static let TOKEN_NUMBER = 9
    static let TOKEN_OBJECT_START = 10
    static let TOKEN_ARRAY_START = 11
    static let TOKEN_VALUE_MIN = TOKEN_NULL

    init(_ string: String) {
        buffer = Array(string.utf16)
        bufferLength = buffer.count
        eof = bufferLength == 0
        consumeWhitespace()
    }

    /// The current token's text (string contents or number literal).
    func takeBufferedString() -> String {
        String(decoding: reusableBuffer, as: UTF16.self)
    }

    /// Expects a given keyword tail at the current position.
    func consumeKeyword(_ first: UInt16, _ expected: [UInt16]) throws {
        if ensureBuffer(expected.count) < expected.count {
            throw createHelpfulException(first, expected, 0)
        }

        for i in 0..<expected.count {
            let c = buffer[index]
            index += 1
            if c != expected[i] {
                throw createHelpfulException(first, expected, i)
            }
        }

        fixupAfterRawBufferRead()

        // The token should end with something other than an ASCII letter
        if isAsciiLetter(peekChar()) {
            throw createHelpfulException(first, expected, expected.count)
        }
    }

    /// Steps through to the end of the current number token (a non-digit token).
    func consumeTokenNumber(_ savedChar: UInt16) throws {
        reusableBuffer.removeAll(keepingCapacity: true)
        reusableBuffer.append(savedChar)
        isDouble = false

        // The JSON spec is way stricter about number formats than a plain
        // double parser. This is the same hand-rolled pseudo-parser as Java's.
        var state: Int
        if savedChar == Self.chMinus {
            state = 1
        } else if savedChar == Self.ch0 {
            state = 3
        } else {
            state = 2
        }

        outer: while true {
            let n = ensureBuffer(Self.BUFFER_ROOM)
            if n == 0 {
                break outer
            }

            for _ in 0..<n {
                let nc = buffer[index]
                if !isDigitCharacter(Int(nc)) {
                    break outer
                }

                var ns = -1
                switch state {
                case 1: // start leading negative
                    if nc == Self.ch0 {
                        ns = 3
                    } else if nc > Self.ch0 && nc <= Self.ch9 {
                        ns = 2
                    }
                case 2, 3: // no leading zero / leading zero
                    if nc >= Self.ch0 && nc <= Self.ch9 && state == 2 {
                        ns = 2
                    } else if nc == Self.chDot {
                        isDouble = true
                        ns = 4
                    } else if nc == 0x65 || nc == 0x45 { // e / E
                        isDouble = true
                        ns = 6
                    }
                case 4, 5: // after period (/ one digit read)
                    if nc >= Self.ch0 && nc <= Self.ch9 {
                        ns = 5
                    } else if (nc == 0x65 || nc == 0x45) && state == 5 {
                        isDouble = true
                        ns = 6
                    }
                case 6, 7: // after exponent (/ and sign)
                    // Java: (nc == '+' || nc == '-' && state == 6) — precedence preserved
                    if nc == Self.chPlus || (nc == Self.chMinus && state == 6) {
                        ns = 7
                    } else if nc >= Self.ch0 && nc <= Self.ch9 {
                        ns = 8
                    }
                case 8: // after digits
                    if nc >= Self.ch0 && nc <= Self.ch9 {
                        ns = 8
                    }
                default:
                    assertionFailure("Impossible")
                }
                reusableBuffer.append(nc)
                index += 1
                if ns == -1 {
                    throw createParseException(
                        "Malformed number: \(takeBufferedString())", tokenPos: true)
                }
                state = ns
            }
        }

        if state != 2 && state != 3 && state != 5 && state != 8 {
            throw createParseException(
                "Malformed number: \(takeBufferedString())", tokenPos: true)
        }

        // Special case for -0
        if state == 3 && savedChar == Self.chMinus {
            isDouble = true
        }

        fixupAfterRawBufferRead()
    }

    /// Steps through to the end of the current string token (the unescaped
    /// double quote).
    func consumeTokenString() throws {
        reusableBuffer.removeAll(keepingCapacity: true)

        while true {
            if index >= bufferLength {
                eof = true
                throw createParseException(
                    "String was not terminated before end of input", tokenPos: true)
            }

            let c = try stringChar()
            switch c {
            case Self.chQuote:
                fixupAfterRawBufferRead()
                return
            case Self.chBackslash:
                if index >= bufferLength {
                    throw createParseException(
                        "EOF encountered in the middle of a string escape", tokenPos: false)
                }
                let escape = buffer[index]
                index += 1
                switch escape {
                case 0x62: reusableBuffer.append(0x08) // \b
                case 0x66: reusableBuffer.append(0x0C) // \f
                case 0x6E: reusableBuffer.append(0x0A) // \n
                case 0x72: reusableBuffer.append(0x0D) // \r
                case 0x74: reusableBuffer.append(0x09) // \t
                case Self.chQuote, Self.chSlash, Self.chBackslash:
                    reusableBuffer.append(escape)
                case 0x75: // \uXXXX
                    if bufferLength - index < 4 {
                        index = bufferLength
                        throw createParseException(
                            "EOF encountered in the middle of a string escape", tokenPos: false)
                    }
                    var escaped = 0
                    for _ in 0..<4 {
                        escaped <<= 4
                        let digit = Int(buffer[index])
                        index += 1
                        if digit >= 0x30 && digit <= 0x39 {
                            escaped |= digit - 0x30
                        } else if digit >= 0x41 && digit <= 0x46 { // A-F
                            escaped |= (digit - 0x41) + 10
                        } else if digit >= 0x61 && digit <= 0x66 { // a-f
                            escaped |= (digit - 0x61) + 10
                        } else {
                            throw createParseException(
                                "Expected unicode hex escape character: \(charString(digit)) (\(digit))",
                                tokenPos: false)
                        }
                    }
                    reusableBuffer.append(UInt16(escaped))
                default:
                    throw createParseException(
                        "Invalid escape: \\\(charString(Int(escape)))", tokenPos: false)
                }
            default:
                reusableBuffer.append(c)
            }
        }
    }

    /// Advances a character, throwing if it is illegal in the context of a
    /// JSON string.
    private func stringChar() throws -> UInt16 {
        let c = buffer[index]
        index += 1
        if c < 32 {
            try throwControlCharacterException(c)
        }
        return c
    }

    private func throwControlCharacterException(_ c: UInt16) throws -> Never {
        // Need to ensure that we position this at the correct location for the error
        if c == 0x0A { // \n
            linePos += 1
            rowPos = index + 1 + charOffset
            utf8adjust = 0
        }
        throw createParseException(
            "Strings may not contain control characters: 0x\(String(c, radix: 16))",
            tokenPos: false)
    }

    /// Quick test for digit characters.
    private func isDigitCharacter(_ c: Int) -> Bool {
        (c >= 0x30 && c <= 0x39) || c == 0x65 || c == 0x45 || c == 0x2E || c == 0x2B || c == 0x2D
    }

    /// Quick test for whitespace characters.
    func isWhitespace(_ c: Int) -> Bool {
        c == 0x20 || c == 0x0A || c == 0x0D || c == 0x09
    }

    /// Quick test for ASCII letter characters.
    func isAsciiLetter(_ c: Int) -> Bool {
        (c >= 0x41 && c <= 0x5A) || (c >= 0x61 && c <= 0x7A)
    }

    /// Peek one char ahead, don't advance, returns -1 on end of input.
    /// Bounds-checked beyond Java's eof flag: consumeKeyword advances index
    /// manually, so index may reach bufferLength with eof still false (Java
    /// reads harmless slack from its 32K buffer there; Swift arrays trap).
    private func peekChar() -> Int {
        (eof || index >= bufferLength) ? -1 : Int(buffer[index])
    }

    /// Returns how many of the next n chars are available in the buffer.
    private func ensureBuffer(_ n: Int) -> Int {
        min(n, bufferLength - index)
    }

    /// Advance one character ahead, or return -1 on end of input.
    /// Bounds-checked beyond Java's eof flag (see peekChar).
    private func advanceChar() -> Int {
        if eof || index >= bufferLength {
            eof = true
            return -1
        }

        let c = Int(buffer[index])
        if c == 0x0A {
            linePos += 1
            rowPos = index + 1 + charOffset
            utf8adjust = 0
        }

        index += 1
        if index >= bufferLength {
            eof = true
        }
        return c
    }

    private func consumeWhitespace() {
        while index < bufferLength {
            let c = Int(buffer[index])
            if !isWhitespace(c) {
                return
            }
            if c == 0x0A {
                linePos += 1
                rowPos = index + 1 + charOffset
                utf8adjust = 0
            }
            index += 1
        }
        eof = true
    }

    /// Consumes a token, first eating up any whitespace ahead of it. Note that
    /// number tokens are not necessarily valid numbers.
    func advanceToToken() throws -> Int {
        var c = advanceChar()
        while isWhitespace(c) {
            c = advanceChar()
        }

        tokenCharPos = index + charOffset - rowPos - utf8adjust
        tokenCharOffset = charOffset + index

        switch c {
        case -1:
            return Self.TOKEN_EOF
        case 0x5B: // [
            return Self.TOKEN_ARRAY_START
        case 0x5D: // ]
            return Self.TOKEN_ARRAY_END
        case 0x2C: // ,
            return Self.TOKEN_COMMA
        case 0x3A: // :
            return Self.TOKEN_COLON
        case 0x7B: // {
            return Self.TOKEN_OBJECT_START
        case 0x7D: // }
            return Self.TOKEN_OBJECT_END
        case 0x74: // t
            try consumeKeyword(UInt16(c), Self.TRUE)
            return Self.TOKEN_TRUE
        case 0x66: // f
            try consumeKeyword(UInt16(c), Self.FALSE)
            return Self.TOKEN_FALSE
        case 0x6E: // n
            try consumeKeyword(UInt16(c), Self.NULL)
            return Self.TOKEN_NULL
        case 0x22: // "
            try consumeTokenString()
            return Self.TOKEN_STRING
        case 0x2D, 0x30...0x39: // - 0-9
            try consumeTokenNumber(UInt16(c))
            return Self.TOKEN_NUMBER
        case 0x2B, 0x2E: // + .
            throw createParseException(
                "Numbers may not start with '\(charString(c))'", tokenPos: true)
        default:
            if isAsciiLetter(c) {
                throw createHelpfulException(UInt16(c), nil, 0)
            }
            throw createParseException("Unexpected character: \(charString(c))", tokenPos: true)
        }
    }

    /// Helper function to fixup eof after reading buffer directly.
    private func fixupAfterRawBufferRead() {
        if index >= bufferLength {
            eof = true
        }
    }

    /// Throws a helpful exception based on the current alphanumeric token.
    func createHelpfulException(
        _ first: UInt16, _ expected: [UInt16]?, _ failurePosition: Int
    ) -> JsonParserException {
        // Build the first part of the token
        var errorToken = charString(Int(first))
            + String(decoding: (expected ?? [])[0..<failurePosition], as: UTF16.self)

        // Consume the whole pseudo-token to make a better error message
        while isAsciiLetter(peekChar()) && errorToken.count < 15 {
            errorToken.append(charString(advanceChar()))
        }

        let suggestion = expected == nil
            ? ""
            : ". Did you mean '\(charString(Int(first)))\(String(decoding: expected!, as: UTF16.self))'?"
        return createParseException("Unexpected token '\(errorToken)'" + suggestion, tokenPos: true)
    }

    /// Creates a JsonParserException filled from the current line and char position.
    func createParseException(_ message: String, tokenPos: Bool) -> JsonParserException {
        if tokenPos {
            return JsonParserException(
                message: message + " on line \(linePos), char \(tokenCharPos)",
                linePosition: linePos, charPosition: tokenCharPos, charOffset: tokenCharOffset)
        } else {
            let charPos = max(1, index + charOffset - rowPos - utf8adjust)
            return JsonParserException(
                message: message + " on line \(linePos), char \(charPos)",
                linePosition: linePos, charPosition: charPos, charOffset: index + charOffset)
        }
    }

    private func charString(_ c: Int) -> String {
        guard c >= 0, let scalar = Unicode.Scalar(UInt32(c)) else { return "?" }
        return String(Character(scalar))
    }
}
