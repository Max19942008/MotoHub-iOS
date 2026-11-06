import Foundation

struct GraphQLListingRepository: ListingRepository {
    let client: GraphQLClient

    func motorbikes(filter: MotorbikeFilter, page: Int) async throws -> PagedResult<Motorbike> {
        struct Response: Decodable { let getProperties: ListDTO<MotorbikeDTO> }
        let variables = InquiryVariables(input: Inquiry(
            page: page,
            limit: AppConfig.pageSize,
            sort: filter.sort.field(prefix: "property"),
            direction: filter.sort.direction,
            search: MotorbikeSearchDTO(filter)
        ))
        let result = try await client.execute(GraphQLOperation<_, Response>(document: Self.motorbikesQuery, variables: variables))
        return PagedResult(items: result.getProperties.list.map { $0.toDomain() }, total: result.getProperties.total)
    }

    func motorbike(id: String) async throws -> Motorbike {
        struct Response: Decodable { let getProperty: MotorbikeDTO }
        let result = try await client.execute(GraphQLOperation<_, Response>(document: Self.motorbikeQuery, variables: IDVariables(id: id)))
        return result.getProperty.toDomain()
    }

    func parts(filter: PartFilter, page: Int) async throws -> PagedResult<Part> {
        struct Response: Decodable { let getParts: ListDTO<PartDTO> }
        let variables = InquiryVariables(input: Inquiry(
            page: page,
            limit: AppConfig.pageSize,
            sort: filter.sort.field(prefix: "part"),
            direction: filter.sort.direction,
            search: PartSearchDTO(filter)
        ))
        let result = try await client.execute(GraphQLOperation<_, Response>(document: Self.partsQuery, variables: variables))
        return PagedResult(items: result.getParts.list.map { $0.toDomain() }, total: result.getParts.total)
    }

    func part(id: String) async throws -> Part {
        struct Response: Decodable { let getPart: PartDTO }
        let result = try await client.execute(GraphQLOperation<_, Response>(document: Self.partQuery, variables: IDVariables(id: id)))
        return result.getPart.toDomain()
    }

    // MARK: - Documents

    private static let sellerFields = "memberData { _id memberNick memberPhone memberImage memberType }"

    private static let motorbikeFields = """
    _id propertyType propertyLocation propertyBrand propertyCondition propertyAddress
    propertyTitle propertyPrice propertyCurrency propertyYear propertyEngineCc
    propertyMileAge propertyViews propertyLikes propertyImages propertyDesc
    propertyBarter propertyRent createdAt
    \(sellerFields)
    """

    private static let partFields = """
    _id partCategory partType partLocation partBrand partCondition partTitle
    partPrice partCurrency partStockCount partCompatibleBrands partViews partLikes
    partImages partDesc partBarter createdAt
    \(sellerFields)
    """

    private static let motorbikesQuery = """
    query ($input: PropertiesInquiry!) {
      getProperties(input: $input) { list { \(motorbikeFields) } metaCounter { total } }
    }
    """

    private static let motorbikeQuery = """
    query ($id: String!) { getProperty(propertyId: $id) { \(motorbikeFields) } }
    """

    private static let partsQuery = """
    query ($input: PartsInquiry!) {
      getParts(input: $input) { list { \(partFields) } metaCounter { total } }
    }
    """

    private static let partQuery = """
    query ($id: String!) { getPart(partId: $id) { \(partFields) } }
    """
}
