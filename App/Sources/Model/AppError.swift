import Foundation

/// Lightweight Error carrying a user-facing message, so background extraction
/// work can report failures across `Result` / continuation boundaries.
struct AppError: Error, Sendable {
    let message: String

    init(_ message: String) {
        self.message = message
    }

    init(_ error: Error) {
        self.message = String(describing: error)
    }
}
