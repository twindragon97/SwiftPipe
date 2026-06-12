// SwiftPipePlayer — UI-free playback core for SwiftPipe.
//
// Lands in Phase 5. Resume-position semantics must match Android's
// StreamStateEntity exactly so an imported newpipe.db behaves identically:
//  - save state when progress > 5000 ms OR > 1/4 of the duration
//  - consider finished when remaining < 60 s AND progress >= 3/4

import AVFoundation

public enum SwiftPipePlayer {
    /// Placeholder used by the Phase 0 bootstrap tests.
    public static let bootstrap = true
}
