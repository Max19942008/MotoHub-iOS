import Foundation

struct Seller: Hashable, Sendable {
    let id: String
    let nick: String
    let phone: String?
    let imagePath: String?
    let type: String?
}

/// A motorbike for sale ("property" on the backend).
struct Motorbike: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var type: String
    var brand: String
    var condition: String
    var location: String
    var address: String
    var price: Double
    var currency: String
    var year: Int
    var engineCc: Int
    var mileage: Int
    var views: Int
    var likes: Int
    var rank: Double = 0
    /// Set only on the detail query, for the logged-in member.
    var liked = false
    var interested = false
    var imagePaths: [String]
    var barter: Bool
    var rent: Bool
    var description: String?
    var createdAt: Date?
    var status: String?
    var seller: Seller?
}

/// A spare part or an accessory.
struct Part: Identifiable, Hashable, Sendable {
    let id: String
    var title: String
    var category: String
    var type: String
    var brand: String
    var condition: String
    var location: String
    var price: Double
    var currency: String
    var stock: Int
    var compatibleBrands: [String]
    var views: Int
    var likes: Int
    var rank: Double = 0
    var liked = false
    var interested = false
    var imagePaths: [String]
    var barter: Bool
    var description: String?
    var createdAt: Date?
    var status: String?
    var seller: Seller?

    var isAccessory: Bool { category == "ACCESSORY" }
}

struct PagedResult<Item: Sendable>: Sendable {
    let items: [Item]
    let total: Int
}

/// A dealer (member of type AGENT).
struct Agent: Identifiable, Hashable, Sendable {
    let id: String
    var nick: String
    var fullName: String?
    var phone: String?
    var imagePath: String?
    var rank: Double = 0
    var type: String?
    var address: String?
    var properties = 0
    var views = 0
    var likes = 0
    var liked = false
    var followed = false

    /// The site gives every agent card one of six color themes from its id.
    var variant: Int { id.unicodeScalars.reduce(0) { $0 + Int($1.value) } % 6 }
}

/// A review under a listing or an article.
struct Comment: Identifiable, Hashable, Sendable {
    let id: String
    let content: String
    let author: String
    let authorImage: String?
    let createdAt: Date?
}

/// A community post (BoardArticle on the backend).
struct Article: Identifiable, Hashable, Sendable {
    let id: String
    var category: String
    var title: String
    var content: String
    var imagePath: String?
    var views = 0
    var likes = 0
    var comments = 0
    var liked = false
    var createdAt: Date?
    var authorId: String?
    var author = ""
    var authorImage: String?
}

/// A row of "Obunachilarim" / "Obunalarim": the other member and my relation.
struct FollowMember: Identifiable, Hashable, Sendable {
    let id: String
    var nick: String
    var imagePath: String?
    var followers = 0
    var followings = 0
    var likes = 0
    var liked = false
    var followed = false
}

/// One row of the notifications page.
struct AppNotification: Identifiable, Hashable, Sendable {
    let id: String
    let type: String
    let title: String
    let description: String?
    var unread: Bool
    let createdAt: Date?
}

/// The signed-in member, as carried in the access token.
struct Member: Hashable, Sendable {
    let id: String
    let nick: String
    let phone: String?
    let imagePath: String?
    let type: String?
    let fullName: String?
    var address: String? = nil

    var isAgent: Bool { type == "AGENT" }
}

struct SignupForm: Sendable {
    var nick: String
    var password: String
    var phone: String
    var isAgent: Bool
}

/// A listing or article the AI assistant cited.
struct AISource: Hashable, Sendable {
    enum Kind: String, Sendable {
        case motorbike = "PROPERTY"
        case part = "PART"
        case article = "ARTICLE"
    }

    let kind: Kind?
    let id: String
    let title: String
    let subtitle: String?
    let price: Double?
    let currency: String?
    let imagePath: String?
    let articleCategory: String?
}

struct ChatMessage: Identifiable, Hashable, Sendable {
    enum Role: Sendable {
        case user, assistant, error
    }

    let id = UUID()
    let role: Role
    let text: String
    var sources: [AISource] = []
}

/// Why a user flags an AI answer (Google Play / App Store AI-content rules).
enum AIReportReason: String, CaseIterable, Identifiable, Sendable {
    case offensive = "OFFENSIVE"
    case wrong = "WRONG"
    case spam = "SPAM"
    case other = "OTHER"

    var id: String { rawValue }

    var label: String {
        switch self {
        case .offensive: "Haqoratli yoki nomaqbul"
        case .wrong: "Noto'g'ri ma'lumot"
        case .spam: "Spam yoki reklama"
        case .other: "Boshqa sabab"
        }
    }
}

/// The sender of a live-chat message, as the server shares it.
struct ChatMember: Hashable, Sendable {
    let id: String
    let nick: String
    let imagePath: String?
}

/// One message of the site's live chat.
struct LiveChatMessage: Identifiable, Hashable, Sendable {
    let id = UUID()
    let text: String
    let member: ChatMember?
    let createdAt: String?
}
