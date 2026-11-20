import Foundation

/// RAG assistant on the backend (`askAssistant`): answers from MotoHub listings.
struct GraphQLAssistantRepository: AssistantRepository {
    let client: GraphQLClient

    func ask(_ message: String, history: [ChatMessage]) async throws -> ChatMessage {
        // Failed turns are local UI only; the model never saw them.
        let turns: [JSONObject] = history.compactMap { turn in
            switch turn.role {
            case .user: ["role": "user", "content": turn.text]
            case .assistant: ["role": "assistant", "content": turn.text]
            case .error: nil
            }
        }
        let data = try await client.query(
            """
            mutation ($input: AiChatInput!) {
              askAssistant(input: $input) {
                answer
                sources { sourceType sourceId title subtitle price currency image articleCategory }
              }
            }
            """,
            variables: ["input": ["message": message, "history": Array(turns.suffix(20))] as JSONObject]
        )
        let result = data.object("askAssistant") ?? [:]
        return ChatMessage(role: .assistant, text: result.text("answer"), sources: result.objects("sources").map(AISource.init(json:)))
    }

    func report(reason: AIReportReason, question: String, answer: String, comment: String) async throws {
        var input: JSONObject = [
            "reason": reason.rawValue,
            "question": String(question.prefix(1000)),
            "answer": String(answer.prefix(8000)),
            "platform": "ios",
        ]
        let trimmed = comment.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty { input["comment"] = String(trimmed.prefix(500)) }
        _ = try await client.query("mutation ($input: AiReportInput!) { reportAssistantAnswer(input: $input) }",
                                   variables: ["input": input])
    }
}
