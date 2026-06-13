import CoreGraphics

/// A cap on the HLS adaptive resolution. The HLS manifest stays adaptive; this
/// just sets an upper bound (AVPlayerItem.preferredMaximumResolution), so the
/// player won't pick a variant taller than the chosen value. `.auto` removes
/// the cap (CGSize.zero = no preference).
enum StreamQuality: String, CaseIterable, Identifiable, Hashable {
    case auto
    case p1080
    case p720
    case p480
    case p360
    case p240
    case p144

    var id: String { rawValue }

    var label: String {
        switch self {
        case .auto: return "Auto"
        case .p1080: return "1080p"
        case .p720: return "720p"
        case .p480: return "480p"
        case .p360: return "360p"
        case .p240: return "240p"
        case .p144: return "144p"
        }
    }

    /// Upper bound passed to AVPlayerItem.preferredMaximumResolution. `.zero`
    /// means "no cap" (the AVPlayerItem default).
    var maxResolution: CGSize {
        switch self {
        case .auto: return .zero
        case .p1080: return CGSize(width: 1920, height: 1080)
        case .p720: return CGSize(width: 1280, height: 720)
        case .p480: return CGSize(width: 854, height: 480)
        case .p360: return CGSize(width: 640, height: 360)
        case .p240: return CGSize(width: 426, height: 240)
        case .p144: return CGSize(width: 256, height: 144)
        }
    }
}
