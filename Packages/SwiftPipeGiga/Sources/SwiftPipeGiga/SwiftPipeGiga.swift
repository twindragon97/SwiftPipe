// SwiftPipeGiga — mirror of NewPipe's giga download engine and stream muxers.
//
// Phase 7 ports, in this order:
//  - org/schabi/newpipe/streams: DataReader, io/ (ChunkFileInputStream,
//    CircularFileWriter, ...), Mp4DashReader/Mp4FromDashWriter,
//    WebMReader/WebMWriter, OggFromWebMWriter, SrtFromTtmlWriter.
//  - us/shandian/giga: DownloadMission state machine, MissionRecoveryInfo,
//    FinishedMissionStore (own downloads.db, kept out of backups, like Android),
//    postprocessing/ (Mp4FromDashMuxer, WebMMuxer, OggFromWebmDemuxer,
//    TtmlConverter, M4aNoDash).
//
// Transport on iOS: preallocated output file, contiguous 2–20 MB blocks, one
// URLSessionDownloadTask with a Range header per block on a background session;
// a coordinator writes finished blocks at their offsets. Pause cancels tasks
// (completed blocks stay recorded), resume re-enqueues pending blocks.

public enum SwiftPipeGiga {
    /// Placeholder used by the Phase 0 bootstrap tests.
    public static let bootstrap = true
}
