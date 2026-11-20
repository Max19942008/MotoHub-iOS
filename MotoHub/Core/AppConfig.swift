import Foundation

/// Backend and website addresses come from Info.plist (MHAPIBaseURL / MHSiteURL),
/// which are filled from the API_BASE_URL / SITE_URL build settings.
enum AppConfig {
    static let apiBaseURL = url(forInfoKey: "MHAPIBaseURL", fallback: "https://api.motopresto.online")
    static let siteURL = url(forInfoKey: "MHSiteURL", fallback: "https://motopresto.online")

    static var graphQLURL: URL { apiBaseURL.appendingPathComponent("graphql") }
    static var privacyPolicyURL: URL { siteURL.appendingPathComponent("privacy") }

    /// ws(s):// form of the API address, like the site's REACT_APP_API_WS.
    static var chatSocketURL: URL {
        var components = URLComponents(url: apiBaseURL, resolvingAgainstBaseURL: false)!
        components.scheme = components.scheme == "http" ? "ws" : "wss"
        return components.url!
    }

    /// Videos the website plays (served from the site itself).
    static var heroVideos: [URL] {
        [
            "video/3936776-hd_1920_1080_25fps.mp4",
            "video/5052417-hd_1920_1080_30fps.mp4",
            "video/5052676-hd_1920_1080_30fps.mp4",
        ].map { siteURL.appendingPathComponent($0) }
    }

    static var adVideo: URL {
        siteURL.appendingPathComponent("video/mixkit-motorcyclist-crossing-a-desert-surrounded-by-mountains-39926-hd-ready.mp4")
    }

    static let pageSize = 10

    /// Listing images are full URLs (Cloudinary) or paths relative to the API ("uploads/property/x.jpg").
    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        return URL(string: path, relativeTo: apiBaseURL)?.absoluteURL
    }

    private static func url(forInfoKey key: String, fallback: String) -> URL {
        let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
        return URL(string: raw.isEmpty ? fallback : raw) ?? URL(string: fallback)!
    }
}
