import Foundation

/// A typed GraphQL operation: the document, its variables and the shape of `data`.
struct GraphQLOperation<Variables: Encodable, Response: Decodable> {
    let document: String
    let variables: Variables
}

struct NoVariables: Encodable {}

/// Supplies a valid access token (refreshing it first if needed), or nil for guests.
protocol AccessTokenProviding: Sendable {
    func validAccessToken() async -> String?
}

/// Minimal GraphQL-over-HTTP client for the NestJS/Apollo backend.
/// The backend runs on Render's free tier, which sleeps when idle and can take
/// ~50 s to wake, hence the long timeout.
struct GraphQLClient: Sendable {
    let endpoint: URL
    var session: URLSession = .shared
    var tokenProvider: (any AccessTokenProviding)?

    func execute<V, R>(_ operation: GraphQLOperation<V, R>) async throws -> R {
        var request = URLRequest(url: endpoint, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let token = await tokenProvider?.validAccessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONEncoder().encode(RequestBody(query: operation.document, variables: operation.variables))

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch let error as URLError {
            throw Self.map(error)
        }
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        return try Self.decode(R.self, from: data, status: status)
    }

    /// Errors first (so a GraphQL error is not hidden by a `data` shape mismatch), then data.
    static func decode<R: Decodable>(_ type: R.Type, from data: Data, status: Int) throws -> R {
        let decoder = JSONDecoder()
        guard let errors = try? decoder.decode(ErrorEnvelope.self, from: data) else {
            // Render answers with an HTML 502/503 page while the instance boots.
            if status >= 500 { throw AppError.network("Server hozir uyg‘onmoqda. Biroz kutib, qayta urinib ko‘ring.") }
            throw AppError.server("Server xatosi (\(status)).")
        }
        if let message = errors.errors?.first?.message {
            throw AppError.server(ErrorTranslator.translate(message))
        }
        do {
            guard let value = try decoder.decode(DataEnvelope<R>.self, from: data).data else {
                throw AppError.server("Server bo‘sh javob qaytardi.")
            }
            return value
        } catch let error as AppError {
            throw error
        } catch {
            throw AppError.server("Server javobini o‘qib bo‘lmadi.")
        }
    }

    private static func map(_ error: URLError) -> Error {
        switch error.code {
        case .cancelled:
            return CancellationError()
        case .timedOut:
            return AppError.network("Server javob bermadi. Keyinroq qayta urinib ko‘ring.")
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return AppError.network("Internet aloqasi yo‘q.")
        default:
            return AppError.network("Serverga ulanib bo‘lmadi.")
        }
    }

    private struct RequestBody<V: Encodable>: Encodable {
        let query: String
        let variables: V
    }

    private struct DataEnvelope<T: Decodable>: Decodable {
        let data: T?
    }

    struct ErrorEnvelope: Decodable {
        let errors: [GraphQLErrorDTO]?
    }
}

/// `message` is a string, or a list of strings for class-validator errors.
struct GraphQLErrorDTO: Decodable {
    let message: String

    private enum CodingKeys: String, CodingKey { case message }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let text = try? container.decode(String.self, forKey: .message) {
            message = text
        } else if let list = try? container.decode([String].self, forKey: .message) {
            message = list.joined(separator: "\n")
        } else {
            message = "Server xatosi."
        }
    }
}
