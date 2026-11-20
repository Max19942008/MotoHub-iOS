import SwiftUI

/// The website's bike list: header card (title, count, sort, filter buttons) + cards.
struct MotorbikesScreen: View {
    @Environment(Router.self) private var router
    @State private var model: PagedListViewModel<Motorbike, MotorbikeFilter>

    init(repository: any ListingRepository) {
        _model = State(initialValue: PagedListViewModel(query: MotorbikeFilter()) { filter, page in
            try await repository.motorbikes(filter: filter, page: page)
        })
    }

    var body: some View {
        SiteList(model: model, title: "Mototsikllar",
                 emptyMessage: "Bunday mototsikl topilmadi.\nFiltrlarni o'zgartirib ko'ring.") {
            filters
        } row: { bike in
            ListingCard.listBike(bike) { router.push(.motorbike(bike)) }
        }
    }

    private var filters: some View {
        let f = model.query
        let thisYear = Calendar.current.component(.year, from: .now)
        return FilterPanel(sort: f.sort, onSort: { s in apply { $0.sort = s } }) {
            MultiFilterButton(label: "Brend", options: Catalog.motorbikeBrands, selected: f.brands) { v in
                apply { $0.brands = $0.brands.toggling(v) }
            }
            MultiFilterButton(label: "Tur", options: Catalog.motorbikeTypes, selected: f.types) { v in
                apply { $0.types = $0.types.toggling(v) }
            }
            MultiFilterButton(label: "Holati", options: Catalog.motorbikeConditions, selected: f.conditions) { v in
                apply { $0.conditions = $0.conditions.toggling(v) }
            }
            MultiFilterButton(label: "Manzil", options: Catalog.locations, selected: f.locations) { v in
                apply { $0.locations = $0.locations.toggling(v) }
            }
            RangeFilterButton(
                text: "\(f.minYear ?? 2000) - \(f.maxYear ?? thisYear)",
                fromTitle: "Yildan", toTitle: "Yilgacha",
                fromOptions: Catalog.yearOptions, toOptions: Catalog.yearOptions,
                format: { "\($0)" }, from: f.minYear, to: f.maxYear
            ) { a, b in apply { $0.minYear = a; $0.maxYear = b } }
            RangeFilterButton(
                text: "\(Formatting.usd(f.minPrice ?? 0)) - \(Formatting.usd(f.maxPrice ?? 2_000_000))",
                fromTitle: "Minimal narx ($)", toTitle: "Maksimal narx ($)",
                fromOptions: Catalog.minPriceOptions, toOptions: Catalog.maxPriceOptions,
                format: Formatting.usd, from: f.minPrice, to: f.maxPrice
            ) { a, b in apply { $0.minPrice = a; $0.maxPrice = b } }
            ResetFilterButton { Task { await model.update(MotorbikeFilter()) } }
        }
    }

    private func apply(_ change: (inout MotorbikeFilter) -> Void) {
        var filter = model.query
        change(&filter)
        Task { await model.update(filter) }
    }
}

/// The website's parts page: "Hammasi / Ehtiyot qismlar / Aksessuarlar" pills,
/// header card with sort + filter buttons, then cards.
struct PartsScreen: View {
    @Environment(Router.self) private var router
    @State private var model: PagedListViewModel<Part, PartFilter>

    init(repository: any ListingRepository, category: String) {
        _model = State(initialValue: PagedListViewModel(query: PartFilter(category: category)) { filter, page in
            try await repository.parts(filter: filter, page: page)
        })
    }

    private var title: String {
        switch model.query.category {
        case "SPARE_PART": "Ehtiyot qismlar"
        case "ACCESSORY": "Aksessuarlar"
        default: "Ehtiyot qismlar va aksessuarlar"
        }
    }

    var body: some View {
        SiteList(model: model, title: title, emptyMessage: "Hech narsa topilmadi.\nFiltrlarni o'zgartirib ko'ring.") {
            tabs
        } header: {
            filters
        } row: { part in
            ListingCard.listPart(part) { router.push(.part(part)) }
        }
        // The drawer picked another category.
        .onChange(of: router.partsCategoryChange) { _, _ in
            switchTo(router.partsCategory, notify: false)
        }
    }

    private func switchTo(_ category: String, notify: Bool = true) {
        guard category != model.query.category else { return }
        // Types differ per category, so start the filter fresh (the site does the same).
        Task { await model.update(PartFilter(category: category)) }
        if notify { router.partsCategory = category }
    }

    private var tabs: some View {
        FlowLayout(spacing: 12, lineSpacing: 12) {
            TabPill(label: "Hammasi", active: model.query.category == "ALL") { switchTo("ALL") }
            TabPill(label: "Ehtiyot qismlar", active: model.query.category == "SPARE_PART") { switchTo("SPARE_PART") }
            TabPill(label: "Aksessuarlar", active: model.query.category == "ACCESSORY") { switchTo("ACCESSORY") }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 22, leading: 10, bottom: 0, trailing: 10))
    }

    private var filters: some View {
        let f = model.query
        return FilterPanel(sort: f.sort, onSort: { s in apply { $0.sort = s } }) {
            MultiFilterButton(label: "Tur", options: Catalog.partTypes(f.category), selected: f.types) { v in
                apply { $0.types = $0.types.toggling(v) }
            }
            MultiFilterButton(label: "Brend", options: Catalog.partBrands, selected: f.brands) { v in
                apply { $0.brands = $0.brands.toggling(v) }
            }
            MultiFilterButton(label: "Holati", options: Catalog.partConditions, selected: f.conditions) { v in
                apply { $0.conditions = $0.conditions.toggling(v) }
            }
            MultiFilterButton(label: "Manzil", options: Catalog.locations, selected: f.locations) { v in
                apply { $0.locations = $0.locations.toggling(v) }
            }
            RangeFilterButton(
                text: f.minPrice == nil && f.maxPrice == nil
                    ? "Narx" : "\(Formatting.usd(f.minPrice ?? 0)) - \(Formatting.usd(f.maxPrice ?? 2_000_000))",
                fromTitle: "Minimal narx ($)", toTitle: "Maksimal narx ($)",
                fromOptions: Catalog.minPriceOptions, toOptions: Catalog.maxPriceOptions,
                format: Formatting.usd, from: f.minPrice, to: f.maxPrice
            ) { a, b in apply { $0.minPrice = a; $0.maxPrice = b } }
            ResetFilterButton { Task { await model.update(PartFilter(category: f.category)) } }
        }
    }

    private func apply(_ change: (inout PartFilter) -> Void) {
        var filter = model.query
        change(&filter)
        Task { await model.update(filter) }
    }
}

private struct TabPill: View {
    let label: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.tr)
                .font(.poppins(15, .semibold))
                .foregroundStyle(active ? .white : Brand.ink)
                .padding(.horizontal, 22)
                .padding(.vertical, 9)
                .background(active ? Brand.green : .white, in: Capsule())
                .overlay(Capsule().strokeBorder(active ? Brand.green : Brand.line))
                .shadow(color: active ? Brand.green.opacity(0.4) : .clear, radius: 5, y: 3)
        }
        .buttonStyle(.plain)
    }
}
