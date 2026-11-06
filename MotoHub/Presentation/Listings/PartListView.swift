import SwiftUI

/// Spare parts and accessories: one list per category, switched with a segmented control.
struct PartListView: View {
    @State private var category: PartCategory = .sparePart
    @State private var models: [PartCategory: PagedListViewModel<Part, PartFilter>]
    @State private var searchText = ""
    @State private var showFilters = false

    init(repository: any ListingRepository) {
        var models: [PartCategory: PagedListViewModel<Part, PartFilter>] = [:]
        for category in PartCategory.allCases {
            models[category] = PagedListViewModel(query: PartFilter(category: category)) { filter, page in
                try await repository.parts(filter: filter, page: page)
            }
        }
        _models = State(initialValue: models)
    }

    private var model: PagedListViewModel<Part, PartFilter> { models[category]! }

    var body: some View {
        VStack(spacing: 0) {
            Picker("Turkum", selection: $category) {
                ForEach(PartCategory.allCases) { Text($0.title).tag($0) }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)

            PagedGrid(model: model, emptyMessage: "Bu turkumda hozircha e’lon yo‘q") { part in
                NavigationLink(value: Route.part(id: part.id)) {
                    ListingCard(
                        title: part.title,
                        price: Formatting.price(part.price, currency: part.currency),
                        caption: "\(Formatting.label(part.type)) · \(Formatting.label(part.location))",
                        imagePath: part.imagePaths.first
                    )
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("listing-card")
            }
            .id(category) // fresh scroll position and .task per category
        }
        .navigationTitle("Qismlar")
        .searchable(text: $searchText, prompt: "Qism nomi")
        .onSubmit(of: .search) { apply { $0.text = searchText } }
        .onChange(of: searchText) { _, text in
            if text.isEmpty, !model.query.text.isEmpty { apply { $0.text = "" } }
        }
        .onChange(of: category) { _, _ in
            // Carry the search over to the other category.
            if model.query.text != searchText { apply { $0.text = searchText } }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                SortMenu(selection: model.query.sort) { sort in apply { $0.sort = sort } }
                FilterButton(activeCount: model.query.activeCount) { showFilters = true }
            }
        }
        .sheet(isPresented: $showFilters) {
            PartFilterSheet(filter: model.query) { filter in
                Task { await model.update(filter) }
            }
        }
    }

    private func apply(_ change: (inout PartFilter) -> Void) {
        let target = model
        var filter = target.query
        change(&filter)
        Task { await target.update(filter) }
    }
}

struct PartFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: PartFilter
    let onApply: (PartFilter) -> Void

    init(filter: PartFilter, onApply: @escaping (PartFilter) -> Void) {
        _draft = State(initialValue: filter)
        self.onApply = onApply
    }

    var body: some View {
        FilterSheetScaffold {
            ChipSelector(title: "Turi", options: draft.category.types, selection: $draft.types)
            ChipSelector(title: "Brend", options: Catalog.partBrands, selection: $draft.brands)
            ChipSelector(title: "Holati", options: Catalog.partConditions, selection: $draft.conditions)
            ChipSelector(title: "Hudud", options: Catalog.locations, selection: $draft.locations)
        } onReset: {
            draft = draft.cleared()
        } onApply: {
            onApply(draft)
            dismiss()
        }
    }
}
