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
    let title: String
    let type: String
    let brand: String
    let condition: String
    let location: String
    let address: String
    let price: Double
    let currency: String
    let year: Int
    let engineCc: Int
    let mileage: Int
    let views: Int
    let likes: Int
    let imagePaths: [String]
    let barter: Bool
    let rent: Bool
    let description: String?
    let createdAt: Date?
    let seller: Seller?
}

/// A spare part or an accessory.
struct Part: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let category: String
    let type: String
    let brand: String
    let condition: String
    let location: String
    let price: Double
    let currency: String
    let stock: Int
    let compatibleBrands: [String]
    let views: Int
    let likes: Int
    let imagePaths: [String]
    let barter: Bool
    let description: String?
    let createdAt: Date?
    let seller: Seller?
}

struct PagedResult<Item: Sendable>: Sendable {
    let items: [Item]
    let total: Int
}

/// The signed-in member, as carried in the access token.
struct Member: Hashable, Sendable {
    let id: String
    let nick: String
    let phone: String?
    let imagePath: String?
    let type: String?
    let fullName: String?

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
        case .wrong: "Noto‘g‘ri ma’lumot"
        case .spam: "Spam yoki reklama"
        case .other: "Boshqa sabab"
        }
    }
}
