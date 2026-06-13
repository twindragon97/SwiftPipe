// Mirrors: app/src/main/java/org/schabi/newpipe/database/AppDatabase.kt @ v0.27.x
// plus the Room-generated schema captured in
// app/schemas/org.schabi.newpipe.database.AppDatabase/9.json.
//
// Builds a brand-new database whose sqlite_master is byte-identical to the one
// Room generates for schema version 9 — same table DDL, same index names, and
// the same room_master_table identity hash. We execute the literal `createSql`
// strings exactly as Room emits them (NOT GRDB's migration DSL), because Android
// NewPipe rejects an imported database whose schema identity does not match what
// its compiled-in Room schema expects.

import Foundation
import GRDB

public enum AppDatabase {
    /// Room schema version mirrored by this package (newpipe.db `user_version`).
    public static let version: Int32 = 9

    /// Identity hash Room stores in `room_master_table` for version 9. Android
    /// refuses to open an imported database whose hash does not match its
    /// compiled-in schema, so every database we create or export carries exactly
    /// this value. Source: 9.json `identityHash`.
    public static let identityHash = "7591e8039faa74d8c0517dc867af9d3e"

    /// Database file name — deliberately identical to NewPipe Android.
    public static let databaseFileName = "newpipe.db"

    /// The literal DDL Room runs to build a fresh v9 database, in the exact order
    /// Room emits it (each table immediately followed by its own indices),
    /// mirrored verbatim from 9.json's `createSql` fields with `${TABLE_NAME}`
    /// substituted. Stored byte-for-byte so sqlite_master matches what Room writes.
    static let createStatements: [String] = [
        // subscriptions
        "CREATE TABLE IF NOT EXISTS `subscriptions` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `service_id` INTEGER NOT NULL, `url` TEXT, `name` TEXT, `avatar_url` TEXT, `subscriber_count` INTEGER, `description` TEXT, `notification_mode` INTEGER NOT NULL)",
        "CREATE UNIQUE INDEX IF NOT EXISTS `index_subscriptions_service_id_url` ON `subscriptions` (`service_id`, `url`)",

        // search_history
        "CREATE TABLE IF NOT EXISTS `search_history` (`creation_date` INTEGER, `service_id` INTEGER NOT NULL, `search` TEXT, `id` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL)",
        "CREATE INDEX IF NOT EXISTS `index_search_history_search` ON `search_history` (`search`)",

        // streams
        "CREATE TABLE IF NOT EXISTS `streams` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `service_id` INTEGER NOT NULL, `url` TEXT NOT NULL, `title` TEXT NOT NULL, `stream_type` TEXT NOT NULL, `duration` INTEGER NOT NULL, `uploader` TEXT NOT NULL, `uploader_url` TEXT, `thumbnail_url` TEXT, `view_count` INTEGER, `textual_upload_date` TEXT, `upload_date` INTEGER, `is_upload_date_approximation` INTEGER)",
        "CREATE UNIQUE INDEX IF NOT EXISTS `index_streams_service_id_url` ON `streams` (`service_id`, `url`)",

        // stream_history
        "CREATE TABLE IF NOT EXISTS `stream_history` (`stream_id` INTEGER NOT NULL, `access_date` INTEGER NOT NULL, `repeat_count` INTEGER NOT NULL, PRIMARY KEY(`stream_id`, `access_date`), FOREIGN KEY(`stream_id`) REFERENCES `streams`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE )",
        "CREATE INDEX IF NOT EXISTS `index_stream_history_stream_id` ON `stream_history` (`stream_id`)",

        // stream_state
        "CREATE TABLE IF NOT EXISTS `stream_state` (`stream_id` INTEGER NOT NULL, `progress_time` INTEGER NOT NULL, PRIMARY KEY(`stream_id`), FOREIGN KEY(`stream_id`) REFERENCES `streams`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE )",

        // playlists
        "CREATE TABLE IF NOT EXISTS `playlists` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `name` TEXT, `is_thumbnail_permanent` INTEGER NOT NULL, `thumbnail_stream_id` INTEGER NOT NULL, `display_index` INTEGER NOT NULL)",

        // playlist_stream_join
        "CREATE TABLE IF NOT EXISTS `playlist_stream_join` (`playlist_id` INTEGER NOT NULL, `stream_id` INTEGER NOT NULL, `join_index` INTEGER NOT NULL, PRIMARY KEY(`playlist_id`, `join_index`), FOREIGN KEY(`playlist_id`) REFERENCES `playlists`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED, FOREIGN KEY(`stream_id`) REFERENCES `streams`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED)",
        "CREATE UNIQUE INDEX IF NOT EXISTS `index_playlist_stream_join_playlist_id_join_index` ON `playlist_stream_join` (`playlist_id`, `join_index`)",
        "CREATE INDEX IF NOT EXISTS `index_playlist_stream_join_stream_id` ON `playlist_stream_join` (`stream_id`)",

        // remote_playlists
        "CREATE TABLE IF NOT EXISTS `remote_playlists` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `service_id` INTEGER NOT NULL, `name` TEXT, `url` TEXT, `thumbnail_url` TEXT, `uploader` TEXT, `display_index` INTEGER NOT NULL, `stream_count` INTEGER)",
        "CREATE UNIQUE INDEX IF NOT EXISTS `index_remote_playlists_service_id_url` ON `remote_playlists` (`service_id`, `url`)",

        // feed
        "CREATE TABLE IF NOT EXISTS `feed` (`stream_id` INTEGER NOT NULL, `subscription_id` INTEGER NOT NULL, PRIMARY KEY(`stream_id`, `subscription_id`), FOREIGN KEY(`stream_id`) REFERENCES `streams`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED, FOREIGN KEY(`subscription_id`) REFERENCES `subscriptions`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED)",
        "CREATE INDEX IF NOT EXISTS `index_feed_subscription_id` ON `feed` (`subscription_id`)",

        // feed_group
        "CREATE TABLE IF NOT EXISTS `feed_group` (`uid` INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL, `name` TEXT NOT NULL, `icon_id` INTEGER NOT NULL, `sort_order` INTEGER NOT NULL)",
        "CREATE INDEX IF NOT EXISTS `index_feed_group_sort_order` ON `feed_group` (`sort_order`)",

        // feed_group_subscription_join
        "CREATE TABLE IF NOT EXISTS `feed_group_subscription_join` (`group_id` INTEGER NOT NULL, `subscription_id` INTEGER NOT NULL, PRIMARY KEY(`group_id`, `subscription_id`), FOREIGN KEY(`group_id`) REFERENCES `feed_group`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED, FOREIGN KEY(`subscription_id`) REFERENCES `subscriptions`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED)",
        "CREATE INDEX IF NOT EXISTS `index_feed_group_subscription_join_subscription_id` ON `feed_group_subscription_join` (`subscription_id`)",

        // feed_last_updated
        "CREATE TABLE IF NOT EXISTS `feed_last_updated` (`subscription_id` INTEGER NOT NULL, `last_updated` INTEGER, PRIMARY KEY(`subscription_id`), FOREIGN KEY(`subscription_id`) REFERENCES `subscriptions`(`uid`) ON UPDATE CASCADE ON DELETE CASCADE DEFERRABLE INITIALLY DEFERRED)",
    ]

    /// The `room_master_table` setup, mirrored verbatim from 9.json's
    /// `setupQueries`. Room creates this table last and stamps the identity hash;
    /// without the matching row Android treats the database as corrupt/foreign.
    static let roomMasterStatements: [String] = [
        "CREATE TABLE IF NOT EXISTS room_master_table (id INTEGER PRIMARY KEY,identity_hash TEXT)",
        "INSERT OR REPLACE INTO room_master_table (id,identity_hash) VALUES(42, '\(identityHash)')",
    ]

    /// Creates every table, index and the `room_master_table` row on an empty
    /// database, then stamps `PRAGMA user_version`. Mirrors Room's
    /// `createAllTables` + `updateIdentity`. Idempotent (`IF NOT EXISTS`), but
    /// intended for a fresh file.
    public static func createSchema(_ db: Database) throws {
        for sql in createStatements {
            try db.execute(sql: sql)
        }
        for sql in roomMasterStatements {
            try db.execute(sql: sql)
        }
        // Room/SQLiteOpenHelper tracks the schema version here; Android reads it
        // on import to decide whether a migration is required.
        try db.execute(sql: "PRAGMA user_version = \(version)")
    }
}
