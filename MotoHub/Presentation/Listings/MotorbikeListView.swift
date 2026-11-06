import SwiftUI

struct MotorbikeListView: View {
    @State private var model: PagedListViewModel<Motorbike, MotorbikeFilter>
    @State private var searchText = ""
    @State private var showFilters = false

    init(repository: any ListingRepository) {
        _model = State(initialValue: PagedListViewModel(query: MotorbikeFilter()) { filter, page in
            try await repository.motorbikes(filter: filter, page: page)
        })
    }

    var body: some View {
        PagedGrid(model: model, emptyMessage: "Mos mototsikl topilmadi") { bike in
            NavigationLink(value: Route.motorbike(id: bike.id)) {
                ListingCard(
                    title: bike.title,
                    price: Formatting.price(bike.price, currency: bike.currency),
                    caption: [bike.year > 0 ? "\(bike.year)" : nil, Formatting.label(bike.location)]
                        .compactMap { $0 }
                        .joined(separator: " · "),
                    imagePath: bike.imagePaths.first
                )
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Mototsikllar")
        .searchable(text: $searchText, prompt: "Model yoki brend")
        .onSubmit(of: .search) { apply { $0.text = searchText } }
        .onChange(of: searchText) { _, text in
            if text.isEmpty, !model.query.text.isEmpty { apply { $0.text = "" } }
        }
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                SortMenu(selection: model.query.sort) { sort in apply { $0.sort = sort } }
                FilterButton(activeCount: model.query.activeCount) { showFilters = true }
            }
        }
        .sheet(isPresented: $showFilters) {
            MotorbikeFilterSheet(filter: model.query) { filter in
                Task { await model.update(filter) }
            }
        }
    }

    private func apply(_ change: (inout MotorbikeFilter) -> Void) {
        var filter = model.query
        change(&filter)
        Task { await model.update(filter) }
    }
}

struct MotorbikeFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var draft: MotorbikeFilter
    @State private var minPrice: String
    @State private var maxPrice: String
    let onApply: (MotorbikeFilter) -> Void

    init(filter: MotorbikeFilter, onApply: @escaping (MotorbikeFilter) -> Void) {
        _draft = State(initialValue: filter)
        _minPrice = State(initialValue: filter.minPrice.map(String.init) ?? "")
        _maxPrice = State(initialValue: filter.maxPrice.map(String.init) ?? "")
        self.onApply = onApply
    }

    var body: some View {
        FilterSheetScaffold {
            ChipSelector(title: "Brend", options: Catalog.motorbikeBrands, selection: $draft.brands)
            ChipSelector(title: "Turi", options: Catalog.motorbikeTypes, selection: $draft.types)
            ChipSelector(title: "Holati", options: Catalog.motorbikeConditions, selection: $draft.conditions)
            ChipSelector(title: "Hudud", options: Catalog.locations, selection: $draft.locations)
            VStack(alignment: .leading, spacing: 10) {
                Text("Narx, $").font(.headline)
                HStack {
                    TextField("dan", text: $minPrice)
                    Text("—").foregroundStyle(.secondary)
                    TextField("gacha", text: $maxPrice)
                }
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            }
        } onReset: {
            draft = draft.cleared()
            minPrice = ""
            maxPrice = ""
        } onApply: {
            var filter = draft
            filter.minPrice = Int(minPrice)
            filter.maxPrice = Int(maxPrice)
            onApply(filter)
            dismiss()
        }
    }
}

// MARK: - Shared list chrome

struct SortMenu: View {
    let selection: SortOption
    let onSelect: (SortOption) -> Void

    var body: some View {
        Menu {
            Picker("Saralash", selection: Binding(get: { selection }, set: onSelect)) {
                ForEach(SortOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }
        } label: {
            Label("Saralash", systemImage: "arrow.up.arrow.down")
        }
    }
}

struct FilterButton: View {
    let activeCount: Int
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(
                activeCount > 0 ? "Filtrlar (\(activeCount))" : "Filtrlar",
                systemImage: activeCount > 0
                    ? "line.3.horizontal.decrease.circle.fill"
                    : "line.3.horizontal.decrease.circle"
            )
        }
    }
}

struct FilterSheetScaffold<Content: View>: View {
    @ViewBuilder let content: () -> Content
    let onReset: () -> Void
    let onApply: () -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    content()
                }
                .padding(20)
            }
            .navigationTitle("Filtrlar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Tozalash", action: onReset)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Qo‘llash", action: onApply).bold()
                }
            }
        }
    }
}
