// Mirrors: app/src/main/java/org/schabi/newpipe/database/subscription/NotificationMode.kt @ v0.27.x
//
// Stored as INTEGER in subscriptions.notification_mode. Other values are
// reserved for the future, so this is an open Int rather than a closed enum.

public enum NotificationMode {
    public static let disabled = 0
    public static let enabled = 1
}
