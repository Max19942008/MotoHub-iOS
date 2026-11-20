import Foundation

/// Sort options, same as the website's sort menu.
enum SortOption: String, CaseIterable, Identifiable, Sendable {
    case recent, oldest, likes, views

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "So'nggi"
        case .oldest: "Eng eski"
        case .likes: "Yoqtirishlar"
        case .views: "Ko'rishlar"
        }
    }

    /// "createdAt", or the per-entity field ("propertyLikes", "partViews").
    func field(prefix: String) -> String {
        switch self {
        case .recent, .oldest: "createdAt"
        case .likes: "\(prefix)Likes"
        case .views: "\(prefix)Views"
        }
    }

    var direction: String { self == .oldest ? "ASC" : "DESC" }
}

/// Filters for the motorbike list. Empty = no filter.
struct MotorbikeFilter: Equatable, Sendable {
    var text = ""
    var brands: Set<String> = []
    var types: Set<String> = []
    var conditions: Set<String> = []
    var locations: Set<String> = []
    var minPrice: Int?
    var maxPrice: Int?
    var minYear: Int?
    var maxYear: Int?
    /// nil = not chosen yet (the site's button then reads "Yangi").
    var sort: SortOption?

    var effectiveSort: SortOption { sort ?? .recent }

    var activeCount: Int {
        brands.count + types.count + conditions.count + locations.count
            + (minPrice != nil || maxPrice != nil ? 1 : 0)
            + (minYear != nil || maxYear != nil ? 1 : 0)
    }

    /// The `search` object of PropertiesInquiry; empty fields are left out.
    var search: [String: Any] {
        var s: [String: Any] = [:]
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { s["text"] = trimmed }
        if !brands.isEmpty { s["brandList"] = brands.sorted() }
        if !types.isEmpty { s["typeList"] = types.sorted() }
        if !conditions.isEmpty { s["conditionList"] = conditions.sorted() }
        if !locations.isEmpty { s["locationList"] = locations.sorted() }
        if minPrice != nil || maxPrice != nil {
            s["pricesRange"] = ["start": minPrice ?? 0, "end": maxPrice ?? 2_000_000]
        }
        if minYear != nil || maxYear != nil {
            s["yearRange"] = ["start": minYear ?? 1970, "end": maxYear ?? Calendar.current.component(.year, from: .now)]
        }
        return s
    }
}

/// Filters for the parts list. `category` is SPARE_PART, ACCESSORY or ALL.
struct PartFilter: Equatable, Sendable {
    let category: String
    var text = ""
    var types: Set<String> = []
    var brands: Set<String> = []
    var conditions: Set<String> = []
    var locations: Set<String> = []
    var minPrice: Int?
    var maxPrice: Int?
    var sort: SortOption?

    var effectiveSort: SortOption { sort ?? .recent }

    var activeCount: Int {
        types.count + brands.count + conditions.count + locations.count
            + (minPrice != nil || maxPrice != nil ? 1 : 0)
    }

    var search: [String: Any] {
        var s: [String: Any] = [:]
        if category != "ALL" { s["categoryList"] = [category] }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { s["text"] = trimmed }
        if !types.isEmpty { s["typeList"] = types.sorted() }
        if !brands.isEmpty { s["brandList"] = brands.sorted() }
        if !conditions.isEmpty { s["conditionList"] = conditions.sorted() }
        if !locations.isEmpty { s["locationList"] = locations.sorted() }
        if minPrice != nil || maxPrice != nil {
            s["pricesRange"] = ["start": minPrice ?? 0, "end": maxPrice ?? 2_000_000]
        }
        return s
    }
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

    static func partTypes(_ category: String) -> [String] {
        switch category {
        case "SPARE_PART": sparePartTypes
        case "ACCESSORY": accessoryTypes
        default: sparePartTypes + accessoryTypes.filter { !sparePartTypes.contains($0) }
        }
    }

    static let locations = [
        "TASHKENT", "ANDIJAN", "BUKHARA", "FERGANA", "JIZZAKH", "KHOREZM", "NAMANGAN",
        "NAVOI", "KASHKADARYA", "SAMARKAND", "SIRDARYA", "SURKHANDARYA", "KARAKALPAKSTAN",
    ]

    /// Price options of the site's price menu.
    static let minPriceOptions = [0, 500, 1000, 2000, 5000, 10000, 20000, 50000, 100_000, 200_000]
    static let maxPriceOptions = [500, 1000, 2000, 5000, 10000, 20000, 50000, 100_000, 200_000, 500_000]

    /// Years in the site's year menu (newest first).
    static var yearOptions: [Int] {
        let year = Calendar.current.component(.year, from: .now)
        return Array(stride(from: year, through: 2000, by: -1))
    }
}
