import Foundation
import Observation

@MainActor
@Observable
final class DetailViewModel<Item: Sendable> {
    enum Phase {
        case loading
        case loaded(Item)
        case failed(String)
    }

    private(set) var phase: Phase = .loading
    private let loader: @Sendable () async throws -> Item

    init(loader: @escaping @Sendable () async throws -> Item) {
        self.loader = loader
    }

    func load() async {
        if case .loaded = phase { return }
        phase = .loading
        do {
            phase = .loaded(try await loader())
        } catch is CancellationError {
            // View went away.
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func retry() async {
        phase = .loading
        await load()
    }
}
