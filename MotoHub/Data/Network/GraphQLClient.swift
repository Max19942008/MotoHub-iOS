import Foundation

typealias JSONObject = [String: Any]

/// Supplies a valid access token (refreshing it first if needed), or nil for guests.
protocol AccessTokenProviding: Sendable {
    func validAccessToken() async -> String?
}

/// Minimal GraphQL-over-HTTP client for the NestJS/Apollo backend.
/// Requests and answers are plain JSON objects, like the Android app's client.
struct GraphQLClient: Sendable {
    let endpoint: URL
    var session: URLSession = .shared
    var tokenProvider: (any AccessTokenProviding)?

    /// Runs `document` and returns its `data` object.
    func query(_ document: String, variables: JSONObject = [:], authenticated: Bool = true) async throws -> JSONObject {
        var request = URLRequest(url: endpoint, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if authenticated, let token = await tokenProvider?.validAccessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let body: JSONObject = ["query": document, "variables": variables]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        let (data, status) = try await send(request)
        return try Self.parse(data, status: status)
    }

    /// Uploads one image with the GraphQL multipart spec (same as the site's
    /// editor) and returns the stored path, e.g. "uploads/member/x.jpg".
    func uploadImage(_ image: Data, fileName: String, target: String) async throws -> String {
        let boundary = "MotoHub-\(UUID().uuidString)"
        var request = URLRequest(url: endpoint, timeoutInterval: 90)
        request.httpMethod = "POST"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.setValue("true", forHTTPHeaderField: "apollo-require-preflight")
        if let token = await tokenProvider?.validAccessToken(), !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        let operations: JSONObject = [
            "query": "mutation ($file: Upload!, $target: String!) { imageUploader(file: $file, target: $target) }",
            "variables": ["file": NSNull(), "target": target] as JSONObject,
        ]
        let map: JSONObject = ["0": ["variables.file"]]
        let mime = fileName.lowercased().hasSuffix(".png") ? "image/png" : "image/jpeg"

        var body = Data()
        func field(_ name: String, _ value: Data) {
            body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"\(name)\"\r\n\r\n".utf8))
            body.append(value)
            body.append(Data("\r\n".utf8))
        }
        field("operations", try JSONSerialization.data(withJSONObject: operations))
        field("map", try JSONSerialization.data(withJSONObject: map))
        body.append(Data("--\(boundary)\r\nContent-Disposition: form-data; name=\"0\"; filename=\"\(fileName)\"\r\nContent-Type: \(mime)\r\n\r\n".utf8))
        body.append(image)
        body.append(Data("\r\n--\(boundary)--\r\n".utf8))
        request.httpBody = body

        let data: Data
        let status: Int
        do {
            (data, status) = try await send(request)
        } catch let error as AppError where error.isNetwork {
            throw AppError.network("Rasm yuklanmadi: server javob bermadi.")
        }
        let result: JSONObject
        do {
            result = try Self.parse(data, status: status)
        } catch AppError.network(_) {
            throw AppError.server("Rasm yuklanmadi (\(status)).")
        }
        guard let path = result["imageUploader"] as? String, !path.isEmpty else {
            throw AppError.server("Rasm yuklanmadi.")
        }
        return path
    }

    private func send(_ request: URLRequest) async throws -> (Data, Int) {
        do {
            let (data, response) = try await session.data(for: request)
            return (data, (response as? HTTPURLResponse)?.statusCode ?? 0)
        } catch let error as URLError {
            throw Self.map(error)
        }
    }

    /// Errors first (a GraphQL error beats a missing `data`), then data.
    static func parse(_ data: Data, status: Int) throws -> JSONObject {
        guard let body = (try? JSONSerialization.jsonObject(with: data)) as? JSONObject else {
            // An HTML 502/503 page while the server restarts.
            if status >= 500 { throw AppError.network("Server xatosi (\(status)).") }
            throw AppError.server("Server xatosi (\(status)).")
        }
        if let errors = body["errors"] as? [Any], let first = errors.first {
            let raw = (first as? JSONObject)?["message"]
            // class-validator errors arrive as a list of messages.
            let message: String
            if let list = raw as? [Any] {
                message = list.map { "\($0)" }.joined(separator: "\n")
            } else if let text = raw as? String {
                message = text
            } else {
                message = "Server xatosi."
            }
            throw AppError.server(ErrorTranslator.translate(message))
        }
        guard let value = body["data"] as? JSONObject else {
            throw AppError.server("Server bo'sh javob qaytardi.")
        }
        return value
    }

    private static func map(_ error: URLError) -> Error {
        switch error.code {
        case .cancelled:
            return CancellationError()
        case .timedOut:
            return AppError.network("Server javob bermadi. Keyinroq qayta urinib ko'ring.")
        case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
            return AppError.network("Internet aloqasi yo'q.")
        default:
            return AppError.network("Serverga ulanib bo'lmadi.")
        }
    }
}
