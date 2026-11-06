import SwiftUI

/// Listing photo with a placeholder for missing or broken images
/// (uploads on the free backend disappear on restart, so this is common).
struct RemoteImage: View {
    let path: String?
    var iconSize: CGFloat = 28

    var body: some View {
        if let url = AppConfig.imageURL(path) {
            AsyncImage(url: url, transaction: Transaction(animation: .easeOut(duration: 0.2))) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .empty:
                    placeholder.overlay { ProgressView() }
                default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        Rectangle()
            .fill(Color(.secondarySystemFill))
            .overlay {
                Image(systemName: "photo")
                    .font(.system(size: iconSize))
                    .foregroundStyle(.secondary)
            }
    }
}

struct LoadingStateView: View {
    var isSlow = false

    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
            if isSlow {
                Text("Server uyg‘onmoqda, bu bir daqiqagacha cho‘zilishi mumkin…")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct MessageStateView: View {
    let systemImage: String
    let message: String
    var actionTitle: String?
    var action: (() -> Void)?

    var body: some View {
        ContentUnavailableView {
            Label(message, systemImage: systemImage)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action).buttonStyle(.borderedProminent)
            }
        }
    }
}

struct TagView: View {
    let text: String
    var highlighted = false

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(highlighted ? Color.accentColor.opacity(0.15) : Color(.tertiarySystemFill), in: Capsule())
            .foregroundStyle(highlighted ? Color.accentColor : Color.primary)
    }
}

/// Wraps children onto new lines like text.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var width: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0, x + size.width > maxWidth {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            width = max(width, x - spacing)
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX, x + size.width > bounds.maxX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

/// Multi-select chips for one filter dimension.
struct ChipSelector: View {
    let title: String
    let options: [String]
    @Binding var selection: Set<String>

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(options, id: \.self) { option in
                    let isOn = selection.contains(option)
                    Button {
                        if isOn { selection.remove(option) } else { selection.insert(option) }
                    } label: {
                        Text(Formatting.label(option))
                            .font(.subheadline)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 7)
                            .background(isOn ? Color.accentColor : Color(.tertiarySystemFill), in: Capsule())
                            .foregroundStyle(isOn ? Color.white : Color.primary)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(isOn ? .isSelected : [])
                }
            }
        }
    }
}

struct ListingCard: View {
    let title: String
    let price: String
    let caption: String
    let imagePath: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Color.clear
                .frame(height: 120)
                .overlay { RemoteImage(path: imagePath) }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            Text(title.isEmpty ? "Nomsiz e’lon" : title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(2, reservesSpace: true)
            Text(price)
                .font(.headline)
                .foregroundStyle(Color.accentColor)
            Text(caption)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(8)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }
}

/// Grid with first-load, error, empty, pull-to-refresh and infinite-scroll states.
struct PagedGrid<Item: Identifiable & Sendable, Query: Equatable & Sendable, Card: View>: View {
    let model: PagedListViewModel<Item, Query>
    var emptyMessage = "Hech narsa topilmadi"
    @ViewBuilder let card: (Item) -> Card

    var body: some View {
        Group {
            if model.items.isEmpty {
                if model.isLoading {
                    LoadingStateView(isSlow: model.isSlow)
                } else if let error = model.errorMessage {
                    MessageStateView(systemImage: "wifi.exclamationmark", message: error, actionTitle: "Qayta urinish") {
                        Task { await model.reload() }
                    }
                } else {
                    MessageStateView(systemImage: "magnifyingglass", message: emptyMessage)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160), spacing: 12)], spacing: 12) {
                        ForEach(model.items) { item in
                            card(item)
                                .onAppear { Task { await model.loadMoreIfNeeded(after: item) } }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    if model.isLoadingMore {
                        ProgressView().padding()
                    }
                }
            }
        }
        .refreshable { await model.reload() }
        .task { await model.loadIfNeeded() }
    }
}
