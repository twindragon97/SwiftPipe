// SwiftPipeExtractor — 1:1 Swift mirror of TeamNewPipe/NewPipeExtractor.
//
// Mirroring conventions live in docs/PORTING.md. In short: one Java file maps
// to one Swift file with the same name, folder, type and member names, and a
// header line `// Mirrors: <upstream path> @ <upstream tag>` so that upstream
// fixes can be replicated mechanically.
//
// The port begins in Phase 1 with the core packages (exceptions, utils,
// downloader, localization, linkhandler, collectors) followed by the YouTube
// service. This file only hosts the Phase 0 bootstrap marker.

public enum SwiftPipeExtractor {
    /// Placeholder used by the Phase 0 bootstrap tests.
    public static let bootstrap = true
}
