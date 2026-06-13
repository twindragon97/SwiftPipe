// Mirrors: app/src/main/java/org/schabi/newpipe/database/stream/model/StreamStateEntity.kt @ v0.27.x

import GRDB

public struct StreamStateEntity: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "stream_state"

    /// Playback state is not saved if the progress is below this threshold (5 s).
    public static let playbackSaveThresholdStartMillis: Int64 = 5000
    /// A stream counts as finished when the time left is under this threshold (60 s).
    public static let playbackFinishedEndMillis: Int64 = 60000

    public var streamUid: Int64
    public var progressMillis: Int64

    public init(streamUid: Int64, progressMillis: Int64) {
        self.streamUid = streamUid
        self.progressMillis = progressMillis
    }

    public init(row: Row) {
        streamUid = row["stream_id"]
        progressMillis = row["progress_time"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["stream_id"] = streamUid
        container["progress_time"] = progressMillis
    }

    /// Saved only if progress exceeds 5 s or at least 1/4 of the stream length.
    public func isValid(durationInSeconds: Int64) -> Bool {
        progressMillis > Self.playbackSaveThresholdStartMillis
            || progressMillis > durationInSeconds * 1000 / 4
    }

    /// Finished when less than 60 s remain and progress is at least 3/4 through.
    /// The player will not resume a finished stream.
    public func isFinished(durationInSeconds: Int64) -> Bool {
        progressMillis >= durationInSeconds * 1000 - Self.playbackFinishedEndMillis
            && progressMillis >= durationInSeconds * 1000 * 3 / 4
    }
}
