// Mirrors: app/src/main/java/org/schabi/newpipe/database/subscription/SubscriptionDAO.kt @ v0.27.x

import GRDB

public struct SubscriptionDAO {
    let dbWriter: DatabaseWriter

    public init(_ dbWriter: DatabaseWriter) {
        self.dbWriter = dbWriter
    }

    // MARK: Queries

    public func rowCount(_ db: Database) throws -> Int64 {
        try Int64.fetchOne(db, sql: "SELECT COUNT(*) FROM subscriptions") ?? 0
    }

    public func getAll(_ db: Database) throws -> [SubscriptionEntity] {
        try SubscriptionEntity.fetchAll(
            db, sql: "SELECT * FROM subscriptions ORDER BY name COLLATE NOCASE ASC")
    }

    public func getSubscriptionsFiltered(_ db: Database, filter: String) throws -> [SubscriptionEntity] {
        try SubscriptionEntity.fetchAll(db, sql: """
            SELECT * FROM subscriptions WHERE name LIKE '%' || ? || '%'
            ORDER BY name COLLATE NOCASE ASC
            """, arguments: [filter])
    }

    public func getSubscription(_ db: Database, serviceId: Int, url: String) throws -> SubscriptionEntity? {
        try SubscriptionEntity.fetchOne(
            db,
            sql: "SELECT * FROM subscriptions WHERE url LIKE ? AND service_id = ?",
            arguments: [url, serviceId])
    }

    public func getSubscription(_ db: Database, subscriptionId: Int64) throws -> SubscriptionEntity? {
        try SubscriptionEntity.fetchOne(
            db, sql: "SELECT * FROM subscriptions WHERE uid = ?", arguments: [subscriptionId])
    }

    func getSubscriptionIdInternal(_ db: Database, serviceId: Int, url: String) throws -> Int64? {
        try Int64.fetchOne(
            db,
            sql: "SELECT uid FROM subscriptions WHERE url LIKE ? AND service_id = ?",
            arguments: [url, serviceId])
    }

    @discardableResult
    public func deleteAll(_ db: Database) throws -> Int {
        try db.execute(sql: "DELETE FROM subscriptions")
        return db.changesCount
    }

    @discardableResult
    public func deleteSubscription(_ db: Database, serviceId: Int, url: String) throws -> Int {
        try db.execute(
            sql: "DELETE FROM subscriptions WHERE url LIKE ? AND service_id = ?",
            arguments: [url, serviceId])
        return db.changesCount
    }

    @discardableResult
    public func insert(_ db: Database, _ entity: SubscriptionEntity) throws -> Int64 {
        var entity = entity
        try entity.insert(db)
        return entity.uid
    }

    /// Insert each subscription, reusing the existing uid (and updating the row)
    /// on a (service_id, url) conflict. Mirror of SubscriptionDAO.upsertAll.
    @discardableResult
    public func upsertAll(_ db: Database, _ entities: [SubscriptionEntity]) throws -> [SubscriptionEntity] {
        var result = entities
        for index in result.indices {
            try result[index].insert(db, onConflict: .ignore)
            if db.changesCount == 0 {
                // Existed: adopt the stored uid and update in place.
                guard let existingId = try getSubscriptionIdInternal(
                    db, serviceId: result[index].serviceId, url: result[index].url ?? "") else {
                    continue
                }
                result[index].uid = existingId
                try result[index].update(db)
            }
        }
        return result
    }

    // MARK: Convenience wrappers

    public func getAll() throws -> [SubscriptionEntity] {
        try dbWriter.read { db in try getAll(db) }
    }

    public func getSubscription(serviceId: Int, url: String) throws -> SubscriptionEntity? {
        try dbWriter.read { db in try getSubscription(db, serviceId: serviceId, url: url) }
    }

    @discardableResult
    public func insert(_ entity: SubscriptionEntity) throws -> Int64 {
        try dbWriter.write { db in try insert(db, entity) }
    }

    @discardableResult
    public func upsertAll(_ entities: [SubscriptionEntity]) throws -> [SubscriptionEntity] {
        try dbWriter.write { db in try upsertAll(db, entities) }
    }

    @discardableResult
    public func deleteSubscription(serviceId: Int, url: String) throws -> Int {
        try dbWriter.write { db in try deleteSubscription(db, serviceId: serviceId, url: url) }
    }
}
