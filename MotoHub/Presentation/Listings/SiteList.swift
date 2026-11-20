import SwiftUI

/// Website-style list: a white header card (title, "N mavjud", filters) on top,
/// then one big card per row, with infinite scroll and pull-to-refresh.
struct SiteList<Item: Identifiable & Sendable, Query: Equatable & Sendable, Top: View, Header: View, Row: View>: View {
    let model: PagedListViewModel<Item, Query>
    var title: String?
    var emptyMessage = "Hech narsa topilmadi"
    var spacing: CGFloat = 20
    @ViewBuilder var top: () -> Top
    @ViewBuilder var header: () -> Header
    @ViewBuilder var row: (Item) -> Row

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                top()
                if let title {
                    HeaderCard(title: title, total: model.total, content: header)
                } else {
                    header()
                }
                if model.items.isEmpty {
                    Group {
                        if model.isLoading {
                            LoadingView()
                        } else if let error = model.errorMessage {
                            MessageView(systemImage: "icloud.slash", message: error) {
                                Task { await model.reload() }
                            }
                        } else {
                            MessageView(systemImage: "magnifyingglass", message: emptyMessage)
                        }
                    }
                    .frame(minHeight: 280)
                } else {
                    ForEach(model.items) { item in
                        row(item)
                            .frame(maxWidth: 560)
                            .padding(.horizontal, 10)
                            .padding(.bottom, spacing)
                            .onAppear { Task { await model.loadMoreIfNeeded(after: item) } }
                    }
                    if model.isLoadingMore {
                        ProgressView().tint(Brand.green).padding(.bottom, 24)
                    }
                }
                // room for the floating AI button
                Color.clear.frame(height: 88)
            }
        }
        .background(Brand.page)
        .refreshable { await model.reload() }
        .task { await model.loadIfNeeded() }
    }
}

extension SiteList where Top == EmptyView {
    init(model: PagedListViewModel<Item, Query>, title: String? = nil, emptyMessage: String = "Hech narsa topilmadi",
         spacing: CGFloat = 20, @ViewBuilder header: @escaping () -> Header, @ViewBuilder row: @escaping (Item) -> Row) {
        self.init(model: model, title: title, emptyMessage: emptyMessage, spacing: spacing,
                  top: { EmptyView() }, header: header, row: row)
    }
}

/// White rounded card like the website's filter header: title, count, controls.
struct HeaderCard<Content: View>: View {
    let title: String
    let total: Int
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.tr)
                .font(.poppins(25, .bold))
                .foregroundStyle(Brand.ink)
            Text("\(total) mavjud".tr)
                .font(.poppins(13.5))
                .foregroundStyle(Color(argb: 0xFF717171))
                .padding(.top, 6)
            content()
        }
        .padding(EdgeInsets(top: 22, leading: 16, bottom: 12, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .roundedBorder(Brand.line, radius: 20)
        .padding(EdgeInsets(top: 20, leading: 10, bottom: 20, trailing: 10))
    }
}
