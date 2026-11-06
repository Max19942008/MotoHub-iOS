import Foundation

/// Reads the (unverified) payload of the backend's access token. The server
/// signs the member document into it, so the app needs no separate profile call.
enum JWT {
    static func payload(_ token: String) -> [String: Any]? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2 else { return nil }
        var base64 = String(parts[1])
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }
        guard let data = Data(base64Encoded: base64) else { return nil }
        return (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
    }

    static func expiry(_ token: String) -> Date? {
        guard let exp = payload(token)?["exp"] as? NSNumber else { return nil }
        return Date(timeIntervalSince1970: exp.doubleValue)
    }

    static func member(_ token: String) -> Member? {
        guard let p = payload(token), let id = p["_id"] else { return nil }
        return Member(
            id: "\(id)",
            nick: p["memberNick"] as? String ?? "",
            phone: p["memberPhone"] as? String,
            imagePath: p["memberImage"] as? String,
            type: p["memberType"] as? String,
            fullName: p["memberFullName"] as? String
        )
    }
}
