import Foundation
import Observation

/// Infinite-scroll list state for any query → page loader.
/// A generation counter drops responses that arrive after the query changed.
@MainActor
@Observable
final class PagedListViewModel<Item: Identifiable & Sendable, Query: Equatable & Sendable> {
    typealias Loader = @Sendable (Query, Int) async throws -> PagedResult<Item>

    private(set) var items: [Item] = []
    private(set) var total = 0
    private(set) var query: Query
    private(set) var isLoading = false
    private(set) var isLoadingMore = false
    private(set) var errorMessage: String?
    /// True when the first page takes long — the free backend is probably waking up.
    private(set) var isSlow = false

    private let loader: Loader
    private var page = 0
    private var generation = 0

    init(query: Query, loader: @escaping Loader) {
        self.query = query
        self.loader = loader
    }

    var canLoadMore: Bool { items.count < total }

    func loadIfNeeded() async {
        guard items.isEmpty, !isLoading, errorMessage == nil else { return }
        await reload()
    }

    func update(_ newQuery: Query) async {
        guard newQuery != query else { return }
        query = newQuery
        await reload()
    }

    func reload() async {
        generation += 1
        let current = generation
        isLoading = true
        isSlow = false
        errorMessage = nil

        let slowTimer = Task { [weak self] in
            try? await Task.sleep(for: .seconds(6))
            guard let self, !Task.isCancelled, self.generation == current, self.isLoading else { return }
            self.isSlow = true
        }
        defer { slowTimer.cancel() }

        do {
            let result = try await loader(query, 1)
            guard current == generation else { return }
            items = result.items
            total = result.total
            page = 1
        } catch is CancellationError {
            guard current == generation else { return }
        } catch {
            guard current == generation else { return }
            errorMessage = error.localizedDescription
        }
        isLoading = false
        isSlow = false
    }

    /// Call from each row's onAppear; fetches the next page when the last row shows.
    func loadMoreIfNeeded(after item: Item) async {
        guard item.id == items.last?.id, canLoadMore, !isLoading, !isLoadingMore else { return }
        let current = generation
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let result = try await loader(query, page + 1)
            guard current == generation else { return }
            items += result.items
            total = result.total
            page += 1
        } catch {
            // Scrolling back to the end retries.
        }
    }
}
