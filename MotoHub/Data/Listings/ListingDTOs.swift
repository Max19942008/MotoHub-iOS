import Foundation

// Wire formats of the backend's GraphQL types, mapped to domain entities.
// Every field is optional: one bad listing must not break a whole page.

struct SellerDTO: Decodable {
    let id: String
    let memberNick: String?
    let memberPhone: String?
    let memberImage: String?
    let memberType: String?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case memberNick, memberPhone, memberImage, memberType
    }

    func toDomain() -> Seller {
        Seller(id: id, nick: memberNick ?? "", phone: memberPhone, imagePath: memberImage, type: memberType)
    }
}

struct MotorbikeDTO: Decodable {
    let id: String
    let propertyType: String?
    let propertyLocation: String?
    let propertyBrand: String?
    let propertyCondition: String?
    let propertyAddress: String?
    let propertyTitle: String?
    let propertyPrice: Double?
    let propertyCurrency: String?
    let propertyYear: Double?
    let propertyEngineCc: Double?
    let propertyMileAge: Double?
    let propertyViews: Double?
    let propertyLikes: Double?
    let propertyImages: [String]?
    let propertyDesc: String?
    let propertyBarter: Bool?
    let propertyRent: Bool?
    let createdAt: String?
    let memberData: SellerDTO?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case propertyType, propertyLocation, propertyBrand, propertyCondition, propertyAddress, propertyTitle
        case propertyPrice, propertyCurrency, propertyYear, propertyEngineCc, propertyMileAge, propertyViews
        case propertyLikes, propertyImages, propertyDesc, propertyBarter, propertyRent, createdAt, memberData
    }

    func toDomain() -> Motorbike {
        Motorbike(
            id: id,
            title: (propertyTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            type: propertyType ?? "",
            brand: propertyBrand ?? "",
            condition: propertyCondition ?? "",
            location: propertyLocation ?? "",
            address: propertyAddress ?? "",
            price: propertyPrice ?? 0,
            currency: propertyCurrency ?? "USD",
            year: Int(propertyYear ?? 0),
            engineCc: Int(propertyEngineCc ?? 0),
            mileage: Int(propertyMileAge ?? 0),
            views: Int(propertyViews ?? 0),
            likes: Int(propertyLikes ?? 0),
            imagePaths: propertyImages ?? [],
            barter: propertyBarter ?? false,
            rent: propertyRent ?? false,
            description: propertyDesc,
            createdAt: ISODate.parse(createdAt),
            seller: memberData?.toDomain()
        )
    }
}

struct PartDTO: Decodable {
    let id: String
    let partCategory: String?
    let partType: String?
    let partLocation: String?
    let partBrand: String?
    let partCondition: String?
    let partTitle: String?
    let partPrice: Double?
    let partCurrency: String?
    let partStockCount: Double?
    let partCompatibleBrands: [String]?
    let partViews: Double?
    let partLikes: Double?
    let partImages: [String]?
    let partDesc: String?
    let partBarter: Bool?
    let createdAt: String?
    let memberData: SellerDTO?

    enum CodingKeys: String, CodingKey {
        case id = "_id"
        case partCategory, partType, partLocation, partBrand, partCondition, partTitle, partPrice, partCurrency
        case partStockCount, partCompatibleBrands, partViews, partLikes, partImages, partDesc, partBarter
        case createdAt, memberData
    }

    func toDomain() -> Part {
        Part(
            id: id,
            title: (partTitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines),
            category: partCategory ?? "",
            type: partType ?? "",
            brand: partBrand ?? "",
            condition: partCondition ?? "",
            location: partLocation ?? "",
            price: partPrice ?? 0,
            currency: partCurrency ?? "USD",
            stock: Int(partStockCount ?? 1),
            compatibleBrands: partCompatibleBrands ?? [],
            views: Int(partViews ?? 0),
            likes: Int(partLikes ?? 0),
            imagePaths: partImages ?? [],
            barter: partBarter ?? false,
            description: partDesc,
            createdAt: ISODate.parse(createdAt),
            seller: memberData?.toDomain()
        )
    }
}

struct ListDTO<Item: Decodable>: Decodable {
    struct Counter: Decodable { let total: Double? }

    let list: [Item]
    let metaCounter: [Counter]?

    var total: Int { Int(metaCounter?.first?.total ?? 0) }
}

// MARK: - Requests

struct Inquiry<Search: Encodable>: Encodable {
    let page: Int
    let limit: Int
    let sort: String
    let direction: String
    let search: Search
}

struct InquiryVariables<Search: Encodable>: Encodable {
    let input: Inquiry<Search>
}

struct IDVariables: Encodable {
    let id: String
}

/// Empty lists and blank text are left out (`nil` keys are not encoded).
struct MotorbikeSearchDTO: Encodable, Equatable {
    struct PriceRange: Encodable, Equatable {
        let start: Int
        let end: Int
    }

    var text: String?
    var brandList: [String]?
    var typeList: [String]?
    var conditionList: [String]?
    var locationList: [String]?
    var pricesRange: PriceRange?

    init(_ filter: MotorbikeFilter) {
        text = filter.text.trimmedOrNil
        brandList = filter.brands.sortedOrNil
        typeList = filter.types.sortedOrNil
        conditionList = filter.conditions.sortedOrNil
        locationList = filter.locations.sortedOrNil
        if filter.minPrice != nil || filter.maxPrice != nil {
            pricesRange = PriceRange(start: filter.minPrice ?? 0, end: filter.maxPrice ?? 100_000_000)
        }
    }
}

struct PartSearchDTO: Encodable, Equatable {
    var categoryList: [String]
    var text: String?
    var typeList: [String]?
    var brandList: [String]?
    var conditionList: [String]?
    var locationList: [String]?

    init(_ filter: PartFilter) {
        categoryList = [filter.category.rawValue]
        text = filter.text.trimmedOrNil
        typeList = filter.types.sortedOrNil
        brandList = filter.brands.sortedOrNil
        conditionList = filter.conditions.sortedOrNil
        locationList = filter.locations.sortedOrNil
    }
}

private extension String {
    var trimmedOrNil: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

private extension Set where Element == String {
    var sortedOrNil: [String]? { isEmpty ? nil : sorted() }
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
