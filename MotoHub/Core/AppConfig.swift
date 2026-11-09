import Foundation

/// Backend and website addresses come from Info.plist (MHAPIBaseURL / MHSiteURL),
/// which are filled from the API_BASE_URL / SITE_URL build settings.
enum AppConfig {
    static let apiBaseURL = url(forInfoKey: "MHAPIBaseURL", fallback: "https://api.motopresto.online")
    static let siteURL = url(forInfoKey: "MHSiteURL", fallback: "https://motopresto.online")

    static var graphQLURL: URL { apiBaseURL.appendingPathComponent("graphql") }
    static var privacyPolicyURL: URL { siteURL.appendingPathComponent("privacy") }

    static let pageSize = 10

    /// Listing images are full URLs (Cloudinary) or paths relative to the API ("uploads/property/x.jpg").
    static func imageURL(_ path: String?) -> URL? {
        guard let path, !path.isEmpty else { return nil }
        if path.hasPrefix("http://") || path.hasPrefix("https://") { return URL(string: path) }
        return URL(string: path, relativeTo: apiBaseURL)?.absoluteURL
    }

    static func articleURL(id: String, category: String?) -> URL? {
        var components = URLComponents(url: siteURL.appendingPathComponent("community/detail"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "articleCategory", value: category ?? "FREE"),
            URLQueryItem(name: "id", value: id),
        ]
        return components?.url
    }

    private static func url(forInfoKey key: String, fallback: String) -> URL {
        let raw = (Bundle.main.object(forInfoDictionaryKey: key) as? String) ?? ""
        return URL(string: raw.isEmpty ? fallback : raw) ?? URL(string: fallback)!
    }
}
