import SwiftUI

/// Website-style controls of the list header card: a full-width sort button
/// and a wrap of filter buttons, each opening a small dropdown menu.

private let filterBorder = Color(argb: 0xFFE0E0E0)

private struct OutlinedLabel: View {
    let text: String
    var active = false
    var icon: String? = nil
    var height: CGFloat = 40
    var fullWidth = false

    var body: some View {
        HStack(spacing: fullWidth ? 10 : 18) {
            if let icon { Image(systemName: icon).font(.system(size: 15, weight: .semibold)) }
            Text(text).font(.poppins(fullWidth ? 14 : 13.5, .medium)).lineLimit(1)
            if icon == nil { Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold)) }
        }
        .foregroundStyle(Brand.ink)
        .padding(.horizontal, 12)
        .frame(maxWidth: fullWidth ? .infinity : nil)
        .frame(height: height)
        .background(.white, in: RoundedRectangle(cornerRadius: 10))
        .roundedBorder(active ? Brand.green : filterBorder, radius: 10)
        .contentShape(RoundedRectangle(cornerRadius: 10))
    }
}

/// One row of a dropdown; the chosen one shows a check.
private struct MenuRow: View {
    let text: String
    let selected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            if selected {
                Label(text, systemImage: "checkmark")
            } else {
                Text(text)
            }
        }
    }
}

/// Full-width "Yangi ⌄" sort button.
struct SortButton: View {
    let sort: SortOption?
    let onChange: (SortOption) -> Void

    var body: some View {
        Menu {
            ForEach(SortOption.allCases) { option in
                MenuRow(text: option.label.tr, selected: option == sort) { onChange(option) }
            }
        } label: {
            OutlinedLabel(text: (sort?.label ?? "Yangi").tr, height: 36, fullWidth: true)
        }
        .menuOrder(.fixed)
    }
}

/// "Brend ⌄" — toggles one value per tap, like the site's menus.
struct MultiFilterButton: View {
    let label: String
    let options: [String]
    let selected: Set<String>
    let onToggle: (String) -> Void

    var body: some View {
        Menu {
            ForEach(options, id: \.self) { option in
                MenuRow(text: Formatting.label(option).tr, selected: selected.contains(option)) { onToggle(option) }
            }
        } label: {
            OutlinedLabel(text: selected.isEmpty ? label.tr : "\(label.tr) (\(selected.count))", active: !selected.isEmpty)
        }
        .menuOrder(.fixed)
    }
}

/// "2000 - 2026 ⌄" / "$0 - $2,000,000 ⌄" — two lists (from / to) in one menu.
struct RangeFilterButton: View {
    let text: String
    let fromTitle: String
    let toTitle: String
    let fromOptions: [Int]
    let toOptions: [Int]
    let format: (Int) -> String
    let from: Int?
    let to: Int?
    let onChange: (Int?, Int?) -> Void

    var body: some View {
        Menu {
            Section(fromTitle.tr) {
                ForEach(fromOptions, id: \.self) { v in
                    MenuRow(text: format(v), selected: v == from) { pick(v, isFrom: true) }
                }
            }
            Section(toTitle.tr) {
                ForEach(toOptions, id: \.self) { v in
                    MenuRow(text: format(v), selected: v == to) { pick(v, isFrom: false) }
                }
            }
        } label: {
            OutlinedLabel(text: text.tr, active: from != nil || to != nil)
        }
        .menuOrder(.fixed)
    }

    private func pick(_ v: Int, isFrom: Bool) {
        var f = from
        var t = to
        if isFrom {
            f = v
            if let tt = t, tt < v { t = v }
        } else {
            t = v
            if let ff = f, ff > v { f = v }
        }
        onChange(f, t)
    }
}

/// "↻ Tozalash"
struct ResetFilterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            OutlinedLabel(text: "Tozalash".tr, icon: "arrow.clockwise")
        }
        .buttonStyle(.plain)
    }
}

/// Sort button, divider, then the filter buttons, as in the site's header card.
struct FilterPanel<Buttons: View>: View {
    let sort: SortOption?
    let onSort: (SortOption) -> Void
    @ViewBuilder let buttons: () -> Buttons

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            SortButton(sort: sort, onChange: onSort).padding(.top, 14)
            Rule().padding(.vertical, 16)
            FlowLayout(spacing: 8) { buttons() }
                .padding(.top, 8)
                .padding(.bottom, 8)
        }
    }
}

extension Set where Element == String {
    func toggling(_ value: String) -> Set<String> {
        var copy = self
        if copy.contains(value) { copy.remove(value) } else { copy.insert(value) }
        return copy
    }
}
