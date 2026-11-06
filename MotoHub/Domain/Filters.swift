import Foundation

enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case newest, cheapest, priciest, popular

    var id: String { rawValue }

    var title: String {
        switch self {
        case .newest: "Eng yangi"
        case .cheapest: "Arzonroq"
        case .priciest: "Qimmatroq"
        case .popular: "Ommabop"
        }
    }

    /// Backend sort field; price and views are prefixed per entity ("propertyPrice", "partViews").
    func field(prefix: String) -> String {
        switch self {
        case .newest: "createdAt"
        case .cheapest, .priciest: "\(prefix)Price"
        case .popular: "\(prefix)Views"
        }
    }

    var direction: String { self == .cheapest ? "ASC" : "DESC" }
}

struct MotorbikeFilter: Equatable, Sendable {
    var text = ""
    var brands: Set<String> = []
    var types: Set<String> = []
    var conditions: Set<String> = []
    var locations: Set<String> = []
    var minPrice: Int?
    var maxPrice: Int?
    var sort: SortOption = .newest

    var activeCount: Int {
        brands.count + types.count + conditions.count + locations.count + (minPrice != nil || maxPrice != nil ? 1 : 0)
    }

    /// Clears the filter sheet's choices but keeps search text and sorting.
    func cleared() -> MotorbikeFilter { MotorbikeFilter(text: text, sort: sort) }
}

enum PartCategory: String, CaseIterable, Identifiable, Sendable {
    case sparePart = "SPARE_PART"
    case accessory = "ACCESSORY"

    var id: String { rawValue }
    var title: String { self == .sparePart ? "Ehtiyot qismlar" : "Aksessuarlar" }
    var types: [String] { self == .sparePart ? Catalog.sparePartTypes : Catalog.accessoryTypes }
}

struct PartFilter: Equatable, Sendable {
    let category: PartCategory
    var text = ""
    var types: Set<String> = []
    var brands: Set<String> = []
    var conditions: Set<String> = []
    var locations: Set<String> = []
    var sort: SortOption = .newest

    var activeCount: Int { types.count + brands.count + conditions.count + locations.count }

    func cleared() -> PartFilter { PartFilter(category: category, text: text, sort: sort) }
}

/// Enum values the backend accepts.
enum Catalog {
    static let motorbikeBrands = ["HONDA", "YAMAHA", "SUZUKI", "KAWASAKI", "DUCATI", "BMW", "HARLEY_DAVIDSON"]
    static let motorbikeTypes = ["SPORT", "CRUISER", "SCOOTER"]
    static let motorbikeConditions = ["NEW", "USED"]

    static let partBrands = motorbikeBrands + ["UNIVERSAL", "OTHER"]
    static let partConditions = ["NEW", "USED", "REFURBISHED"]
    static let sparePartTypes = [
        "ENGINE", "EXHAUST", "BRAKE", "SUSPENSION", "TIRE", "BATTERY", "FILTER", "CHAIN", "ELECTRICAL", "BODY_PANEL", "OTHER",
    ]
    static let accessoryTypes = ["HELMET", "GLOVES", "JACKET", "BOOTS", "LUGGAGE", "PHONE_MOUNT", "COVER", "OTHER"]

    static let locations = [
        "TASHKENT", "ANDIJAN", "BUKHARA", "FERGANA", "JIZZAKH", "KHOREZM", "NAMANGAN",
        "NAVOI", "KASHKADARYA", "SAMARKAND", "SIRDARYA", "SURKHANDARYA", "KARAKALPAKSTAN",
    ]
}
