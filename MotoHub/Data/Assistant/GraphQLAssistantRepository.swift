import Foundation

/// RAG assistant on the backend (`askAssistant`): answers from MotoHub listings.
struct GraphQLAssistantRepository: AssistantRepository {
    let client: GraphQLClient

    func ask(_ message: String, history: [ChatMessage]) async throws -> ChatMessage {
        // Failed turns are local UI only; the model never saw them.
        let turns: [Turn] = history.compactMap { turn in
            switch turn.role {
            case .user: return Turn(role: "user", content: turn.text)
            case .assistant: return Turn(role: "assistant", content: turn.text)
            case .error: return nil
            }
        }
        let variables = Variables(input: Input(message: message, history: Array(turns.suffix(20))))
        let result = try await client.execute(GraphQLOperation<_, Response>(document: Self.document, variables: variables))
        return ChatMessage(
            role: .assistant,
            text: result.askAssistant.answer,
            sources: result.askAssistant.sources.map { $0.toDomain() }
        )
    }

    private struct Turn: Encodable {
        let role: String
        let content: String
    }

    private struct Input: Encodable {
        let message: String
        let history: [Turn]
    }

    private struct Variables: Encodable { let input: Input }

    private struct Response: Decodable {
        struct Answer: Decodable {
            let answer: String
            let sources: [SourceDTO]
        }
        let askAssistant: Answer
    }

    struct SourceDTO: Decodable {
        let sourceType: String
        let sourceId: String
        let title: String?
        let subtitle: String?
        let price: Double?
        let currency: String?
        let image: String?
        let articleCategory: String?

        func toDomain() -> AISource {
            AISource(
                kind: AISource.Kind(rawValue: sourceType),
                id: sourceId,
                title: title ?? "",
                subtitle: subtitle,
                price: price,
                currency: currency,
                imagePath: image,
                articleCategory: articleCategory
            )
        }
    }

    private static let document = """
    mutation ($input: AiChatInput!) {
      askAssistant(input: $input) {
        answer
        sources { sourceType sourceId title subtitle price currency image articleCategory }
      }
    }
    """
}
