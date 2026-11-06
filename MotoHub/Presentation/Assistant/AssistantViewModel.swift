import Foundation
import Observation

@MainActor
@Observable
final class AssistantViewModel {
    private(set) var messages: [ChatMessage] = []
    private(set) var isSending = false
    var draft = ""

    let suggestions = [
        "Toshkentda 5000$ gacha sport mototsikl bormi?",
        "Honda uchun tormoz qismlari",
        "Yangi boshlovchiga qaysi mototsikl mos?",
    ]

    private let repository: any AssistantRepository

    init(repository: any AssistantRepository) {
        self.repository = repository
    }

    var canSend: Bool {
        !isSending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func send(_ text: String? = nil) async {
        let question = (text ?? draft).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !question.isEmpty, !isSending else { return }
        let history = messages
        messages.append(ChatMessage(role: .user, text: String(question.prefix(1000))))
        draft = ""
        isSending = true
        defer { isSending = false }
        do {
            messages.append(try await repository.ask(String(question.prefix(1000)), history: history))
        } catch is CancellationError {
            return
        } catch {
            messages.append(ChatMessage(role: .error, text: error.localizedDescription))
        }
    }

    func clear() {
        messages = []
    }
}
