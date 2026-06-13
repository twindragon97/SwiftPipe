// Mirrors: app/src/main/java/org/schabi/newpipe/database/history/model/SearchHistoryEntry.kt @ v0.27.x

import Foundation
import GRDB

public struct SearchHistoryEntry: FetchableRecord, MutablePersistableRecord, Equatable {
    public static let databaseTableName = "search_history"

    /// Stored as epoch-millis (UTC). Nullable to match Room.
    public var creationDate: Date?
    public var serviceId: Int
    public var search: String?
    public var id: Int64

    public init(creationDate: Date?, serviceId: Int, search: String?, id: Int64 = 0) {
        self.creationDate = creationDate
        self.serviceId = serviceId
        self.search = search
        self.id = id
    }

    public init(row: Row) {
        creationDate = (row["creation_date"] as Int64?).map(Converters.date(fromTimestamp:))
        serviceId = row["service_id"]
        search = row["search"]
        id = row["id"]
    }

    public func encode(to container: inout PersistenceContainer) {
        container["creation_date"] = creationDate.map(Converters.timestamp(from:))
        container["service_id"] = serviceId
        container["search"] = search
        container["id"] = id == 0 ? nil : id
    }

    public mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// Mirror of `hasEqualValues`: same service and query text (ignores date/id).
    public func hasEqualValues(_ other: SearchHistoryEntry) -> Bool {
        serviceId == other.serviceId && search == other.search
    }
}
