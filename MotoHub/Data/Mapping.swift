import Foundation

// Wire format -> domain entities. Every field is optional on the wire:
// one bad listing must not break a whole page.

extension Dictionary where Key == String, Value == Any {
    func string(_ key: String) -> String? {
        switch self[key] {
        case let s as String: s
        case let n as NSNumber: n.stringValue
        default: nil
        }
    }

    func text(_ key: String, _ fallback: String = "") -> String { string(key) ?? fallback }

    /// nil for missing and empty strings ("" means "no photo" on the backend).
    func nonEmpty(_ key: String) -> String? {
        guard let s = string(key), !s.isEmpty else { return nil }
        return s
    }

    func double(_ key: String) -> Double? { (self[key] as? NSNumber)?.doubleValue }
    func int(_ key: String, _ fallback: Int = 0) -> Int { (self[key] as? NSNumber)?.intValue ?? fallback }
    func bool(_ key: String) -> Bool { (self[key] as? Bool) ?? false }
    func object(_ key: String) -> JSONObject? { self[key] as? JSONObject }
    func objects(_ key: String) -> [JSONObject] { (self[key] as? [Any])?.compactMap { $0 as? JSONObject } ?? [] }
    func strings(_ key: String) -> [String] { (self[key] as? [Any])?.map { "\($0)" } ?? [] }
    func date(_ key: String) -> Date? { ISODate.parse(string(key)) }

    /// meLiked: [{myFavorite: true}] -> true
    func flag(_ list: String, _ key: String) -> Bool {
        (self[list] as? [Any])?.first.flatMap { ($0 as? JSONObject)?[key] as? Bool } ?? false
    }

    /// metaCounter: [{total: 42}] -> 42
    func counter(_ key: String = "metaCounter") -> Int {
        (self[key] as? [Any])?.first.flatMap { ($0 as? JSONObject)?.int("total") } ?? 0
    }
}

enum ISODate {
    static func parse(_ value: String?) -> Date? {
        guard let value else { return nil }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: value) { return date }
        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: value)
    }
}

extension Seller {
    init?(json: JSONObject?) {
        guard let j = json else { return nil }
        self.init(id: j.text("_id"), nick: j.text("memberNick"), phone: j.string("memberPhone"),
                  imagePath: j.nonEmpty("memberImage"), type: j.string("memberType"))
    }
}

extension Motorbike {
    init(json j: JSONObject) {
        self.init(
            id: j.text("_id"),
            title: j.text("propertyTitle").trimmingCharacters(in: .whitespacesAndNewlines),
            type: j.text("propertyType"),
            brand: j.text("propertyBrand"),
            condition: j.text("propertyCondition"),
            location: j.text("propertyLocation"),
            address: j.text("propertyAddress"),
            price: j.double("propertyPrice") ?? 0,
            currency: j.text("propertyCurrency", "USD"),
            year: j.int("propertyYear"),
            engineCc: j.int("propertyEngineCc"),
            mileage: j.int("propertyMileAge"),
            views: j.int("propertyViews"),
            likes: j.int("propertyLikes"),
            rank: j.double("propertyRank") ?? 0,
            liked: j.flag("meLiked", "myFavorite"),
            interested: j.flag("meInterested", "myInterest"),
            imagePaths: j.strings("propertyImages"),
            barter: j.bool("propertyBarter"),
            rent: j.bool("propertyRent"),
            description: j.string("propertyDesc"),
            createdAt: j.date("createdAt"),
            status: j.string("propertyStatus"),
            seller: Seller(json: j.object("memberData"))
        )
    }
}

extension Part {
    init(json j: JSONObject) {
        self.init(
            id: j.text("_id"),
            title: j.text("partTitle").trimmingCharacters(in: .whitespacesAndNewlines),
            category: j.text("partCategory"),
            type: j.text("partType"),
            brand: j.text("partBrand"),
            condition: j.text("partCondition"),
            location: j.text("partLocation"),
            price: j.double("partPrice") ?? 0,
            currency: j.text("partCurrency", "USD"),
            stock: j.int("partStockCount", 1),
            compatibleBrands: j.strings("partCompatibleBrands"),
            views: j.int("partViews"),
            likes: j.int("partLikes"),
            rank: j.double("partRank") ?? 0,
            liked: j.flag("meLiked", "myFavorite"),
            interested: j.flag("meInterested", "myInterest"),
            imagePaths: j.strings("partImages"),
            barter: j.bool("partBarter"),
            description: j.string("partDesc"),
            createdAt: j.date("createdAt"),
            status: j.string("partStatus"),
            seller: Seller(json: j.object("memberData"))
        )
    }
}

extension Agent {
    init(json j: JSONObject) {
        self.init(
            id: j.text("_id"),
            nick: j.text("memberNick"),
            fullName: j.string("memberFullName"),
            phone: j.string("memberPhone"),
            imagePath: j.nonEmpty("memberImage"),
            rank: j.double("memberRank") ?? 0,
            type: j.string("memberType"),
            address: j.string("memberAddress"),
            properties: j.int("memberProperties"),
            views: j.int("memberViews"),
            likes: j.int("memberLikes"),
            liked: j.flag("meLiked", "myFavorite"),
            followed: j.flag("meFollowed", "myFollowing")
        )
    }
}

extension Comment {
    init(json j: JSONObject) {
        let member = j.object("memberData")
        self.init(id: j.text("_id"), content: j.text("commentContent"), author: member?.text("memberNick") ?? "",
                  authorImage: member?.nonEmpty("memberImage"), createdAt: j.date("createdAt"))
    }
}

extension Article {
    init(json j: JSONObject) {
        let member = j.object("memberData")
        self.init(
            id: j.text("_id"),
            category: j.text("articleCategory", "FREE"),
            title: j.text("articleTitle"),
            content: j.text("articleContent"),
            imagePath: j.nonEmpty("articleImage"),
            views: j.int("articleViews"),
            likes: j.int("articleLikes"),
            comments: j.int("articleComments"),
            liked: j.flag("meLiked", "myFavorite"),
            createdAt: j.date("createdAt"),
            authorId: member?.string("_id"),
            author: member?.text("memberNick") ?? "",
            authorImage: member?.nonEmpty("memberImage")
        )
    }
}

extension FollowMember {
    /// `key` is followerData (followers list) or followingData (followings list).
    init(json j: JSONObject, key: String) {
        let m = j.object(key) ?? [:]
        self.init(
            id: m.text("_id"),
            nick: m.text("memberNick"),
            imagePath: m.nonEmpty("memberImage"),
            followers: m.int("memberFollowers"),
            followings: m.int("memberFollowings"),
            likes: m.int("memberLikes"),
            liked: j.flag("meLiked", "myFavorite"),
            followed: j.flag("meFollowed", "myFollowing")
        )
    }
}

extension AppNotification {
    init(json j: JSONObject) {
        self.init(id: j.text("_id"), type: j.text("notificationType"), title: j.text("notificationTitle"),
                  description: j.string("notificationDesc"), unread: j.string("notificationStatus") == "WAIT",
                  createdAt: j.date("createdAt"))
    }
}

extension AISource {
    init(json j: JSONObject) {
        self.init(kind: Kind(rawValue: j.text("sourceType")), id: j.text("sourceId"), title: j.text("title"),
                  subtitle: j.string("subtitle"), price: j.double("price"), currency: j.string("currency"),
                  imagePath: j.nonEmpty("image"), articleCategory: j.string("articleCategory"))
    }
}

extension LiveChatMessage {
    /// One message as the socket sends it ({text, memberData, createdAt}).
    init?(json: Any?) {
        guard let j = json as? JSONObject, let text = j["text"] as? String else { return nil }
        var member: ChatMember?
        if let m = j.object("memberData"), let id = m["_id"] as? String, let nick = m["memberNick"] as? String {
            member = ChatMember(id: id, nick: nick, imagePath: m.nonEmpty("memberImage"))
        }
        self.init(text: text, member: member, createdAt: j["createdAt"] as? String)
    }
}
