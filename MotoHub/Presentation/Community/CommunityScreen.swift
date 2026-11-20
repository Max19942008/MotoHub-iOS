import SwiftUI

/// The four boards of the site's community page: id, name, description, English badge.
struct Board: Identifiable {
    let id: String
    let name: String
    let desc: String
    let label: String
}

let communityBoards = [
    Board(id: "FREE", name: "Erkin doska", desc: "Istalgan mavzuda ochiq suhbat", label: "Free Board"),
    Board(id: "RECOMMEND", name: "Tavsiya", desc: "Eng yaxshi joylar va xizmatlar", label: "Recommend"),
    Board(id: "NEWS", name: "Yangiliklar", desc: "Avto soha yangiliklari", label: "News"),
    Board(id: "HUMOR", name: "Hazil", desc: "Memlar va o'yin-kulgu", label: "Humor"),
]

/// English board name the site shows in badges ("Free Board", "Recommend"...).
func boardLabel(_ category: String) -> String {
    (communityBoards.first { $0.id == category } ?? communityBoards[0]).label
}

private let englishMonths = [
    "January", "February", "March", "April", "May", "June", "July",
    "August", "September", "October", "November", "December",
]

/// "December 24, 2025", the site's Moment format.
func articleDate(_ date: Date?) -> String {
    guard let date else { return "" }
    let c = Calendar.current.dateComponents([.day, .month, .year], from: date)
    return "\(englishMonths[(c.month ?? 1) - 1]) \(String(format: "%02d", c.day ?? 1)), \(c.year ?? 2026)"
}

/// Gradient page background used by the site's community pages.
let communityBackground = LinearGradient(
    colors: [Color(argb: 0xFFF8F9FF), Color(argb: 0xFFFFF5F5), Color(argb: 0xFFF0F9FF)],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

/// Website community page: dark banner, board list, latest posts, pagination.
struct CommunityScreen: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var category = "FREE"
    @State private var page = 1
    @State private var result: PagedResult<Article>? = nil
    @State private var loading = true
    @State private var error: String? = nil

    var body: some View {
        let total = result?.total ?? 0
        let items = result?.items ?? []
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    banner(total)
                    Text("Doskalar".tr).font(.poppins(20, .heavy)).foregroundStyle(Brand.ink).padding(.top, 44)
                    BoardList(selected: category, onPick: pickBoard).padding(.top, 20)
                    if total > 0 {
                        Text("Showing \(items.count) / \(total)".tr)
                            .font(.poppins(13, .medium))
                            .foregroundStyle(Color(argb: 0xFF717171))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(LinearGradient(colors: [Color(argb: 0xFFF8F9FA), .white], startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 12))
                            .roundedBorder(Brand.line, radius: 12, width: 1.5)
                            .padding(.top, 12)
                    }
                    GradientTitle(text: "So'nggi postlar", size: 24).padding(.top, 32)
                    Text("Sorted by newest • \(boardLabel(category)) board".tr)
                        .font(.poppins(13.5))
                        .foregroundStyle(Color(argb: 0xFF717171))
                        .padding(.top, 6)
                    Group {
                        if loading && result == nil {
                            LoadingView().frame(height: 260)
                        } else if let error, result == nil {
                            MessageView(systemImage: "icloud.slash", message: error) { Task { await load() } }.frame(height: 260)
                        } else if items.isEmpty {
                            NoArticles()
                        } else {
                            VStack(spacing: 20) {
                                ForEach(items) { a in
                                    ArticleCard(article: a, onTap: { router.push(.article(a.id)) }, onLike: { Task { await like(a) } })
                                }
                            }
                        }
                    }
                    .padding(.top, 18)
                    if total > 0 { pagination(total) }
                }
                .padding(EdgeInsets(top: 20, leading: 20, bottom: 36, trailing: 20))
                SiteFooter()
            }
        }
        .background(communityBackground)
        .refreshable { await load() }
        .task { if result == nil { await load() } }
        // Back from an article: views / likes / comments may have changed.
        .onAppear { if result != nil { Task { await load() } } }
        .onChange(of: router.communityBoard) { _, board in
            guard let board else { return }
            router.communityBoard = nil
            pickBoard(board)
        }
        .onChange(of: router.articlesChanged) { _, _ in
            page = 1
            Task { await load() }
        }
    }

    private func load() async {
        loading = true
        error = nil
        defer { loading = false }
        do {
            result = try await app.community.articles(category: category, page: page)
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func pickBoard(_ c: String) {
        guard c != category else { return }
        category = c
        page = 1
        Task { await load() }
    }

    private func like(_ a: Article) async {
        guard session.isLoggedIn else {
            router.toast("Avval tizimga kiring".tr)
            return
        }
        do {
            try await app.community.likeArticle(id: a.id)
            await load()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func banner(_ total: Int) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("HAMJAMIYAT".tr).font(.poppins(11.5, .bold)).kerning(3).foregroundStyle(.white.opacity(0.7))
            Text("Suhbatni boshlang.".tr)
                .font(.poppins(26, .heavy))
                .gradientText([.white, Color(argb: 0xFFFF6B6B), Brand.indigo])
                .padding(.top, 10)
            Text("Learn, share, and laugh with enthusiasts. Pick a lane and dive into the latest posts.".tr)
                .font(.poppins(14))
                .lineSpacing(6)
                .foregroundStyle(.white.opacity(0.85))
                .padding(.top, 12)
            SiteGradientButton(label: "Write an article", colors: [Color(argb: 0xFFFF6B6B), Color(argb: 0xFFEE5A6F)],
                               radius: 14, height: 46, fullWidth: true) {
                router.openWriteArticle(loggedIn: session.isLoggedIn)
            }
            .padding(.top, 22)
            Button { Task { await load() } } label: {
                Label("Refresh".tr, systemImage: "arrow.clockwise")
                    .font(.poppins(15, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
                    .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
            }
            .buttonStyle(.plain)
            .padding(.top, 12)
            HStack(spacing: 12) {
                bannerStat("MAQOLALAR") {
                    VStack(spacing: 0) {
                        Image(systemName: "doc.text.fill").font(.system(size: 20)).foregroundStyle(Color(argb: 0xFFFF6B6B))
                        Text(verbatim: "\(total)").font(.poppins(20, .heavy)).foregroundStyle(.white)
                    }
                }
                bannerStat("TURKUM") {
                    Text(boardLabel(category).tr).font(.poppins(14, .heavy)).multilineTextAlignment(.center).foregroundStyle(.white)
                }
            }
            .padding(.top, 20)
        }
        .padding(EdgeInsets(top: 30, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(argb: 0xFF1A1A2E), Color(argb: 0xFF16213E), Color(argb: 0xFF0F3460)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.18), radius: 15, y: 12)
    }

    private func bannerStat<Top: View>(_ label: String, @ViewBuilder top: () -> Top) -> some View {
        VStack(spacing: 4) {
            top()
            Text(label.tr).font(.poppins(11, .semibold)).kerning(1).foregroundStyle(.white.opacity(0.7))
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .frame(height: 104)
        .background(.white.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(.white.opacity(0.2), radius: 16)
    }

    private func pagination(_ total: Int) -> some View {
        let pages = Int((Double(total) / 6).rounded(.up))
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                pageArrow("chevron.left", page - 1, enabled: page > 1)
                ForEach(1...max(pages, 1), id: \.self) { p in
                    Button { go(p) } label: {
                        Text(verbatim: "\(p)")
                            .font(.poppins(14, .semibold))
                            .foregroundStyle(p == page ? .white : Brand.ink)
                            .frame(width: 32, height: 32)
                            .background(p == page ? Color(argb: 0xFFE53935) : .clear, in: Circle())
                    }
                    .buttonStyle(.plain)
                }
                pageArrow("chevron.right", page + 1, enabled: page < pages)
            }
            Text((total > 1 ? "Total \(total) articles available" : "Total \(total) article available").tr)
                .font(.poppins(13))
                .foregroundStyle(Color(argb: 0xFF717171))
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 18, trailing: 16))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.white, Color(argb: 0xFFF8F9FF)], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 10, y: 4)
        .padding(.top, 12)
    }

    private func pageArrow(_ icon: String, _ target: Int, enabled: Bool) -> some View {
        Button { go(target) } label: {
            Image(systemName: icon).font(.system(size: 17, weight: .semibold)).foregroundStyle(Brand.muted).frame(width: 36, height: 36)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.4)
    }

    private func go(_ p: Int) {
        page = p
        Task { await load() }
    }
}

/// Vertical board tabs ("Erkin doska", "Tavsiya", ...), active one in a gradient.
struct BoardList: View {
    let selected: String
    let onPick: (String) -> Void

    var body: some View {
        VStack(spacing: 4) {
            ForEach(communityBoards) { b in
                let active = b.id == selected
                Button { onPick(b.id) } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(b.name.tr).font(.poppins(16, .heavy)).foregroundStyle(active ? .white : Brand.ink)
                        Text(b.desc.tr).font(.poppins(13.5)).foregroundStyle(active ? .white.opacity(0.9) : Color(argb: 0xFF717171))
                    }
                    .padding(EdgeInsets(top: 16, leading: 20, bottom: 16, trailing: 20))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        active
                            ? Brand.gradient([Color(argb: 0xFFA855F7), Color(argb: 0xFFEC4899), Color(argb: 0xFFF43F5E)])
                            : Brand.gradient([.white, Color(argb: 0xFFF8F9FA)]),
                        in: RoundedRectangle(cornerRadius: 16)
                    )
                    .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(active ? .clear : Brand.line, lineWidth: 1.5))
                    .shadow(color: active ? Color(argb: 0xFFEC4899).opacity(0.25) : .clear, radius: 8, y: 6)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

/// Site community card: photo with a date box, author, title, views / likes.
struct ArticleCard: View {
    let article: Article
    let onTap: () -> Void
    let onLike: () -> Void

    var body: some View {
        let a = article
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                ArticleImage(path: a.imagePath)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .overlay(alignment: .bottomTrailing) {
                        if let d = a.createdAt {
                            let c = Calendar.current.dateComponents([.day, .month], from: d)
                            VStack(spacing: 0) {
                                Text(englishMonths[(c.month ?? 1) - 1].tr.uppercased())
                                    .font(.poppins(10, .medium)).kerning(0.8).foregroundStyle(Color(argb: 0xFF4B5563))
                                Text(String(format: "%02d", c.day ?? 1)).font(.poppins(19, .heavy)).foregroundStyle(Brand.ink)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                            .padding(.trailing, 14)
                            .padding(.bottom, 12)
                        }
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(a.author).font(.poppins(13, .bold)).foregroundStyle(Brand.indigo)
                    Text(a.title).font(.poppins(16, .bold)).foregroundStyle(Brand.ink).lineLimit(2).padding(.top, 8)
                    Rule(color: Brand.line).padding(.vertical, 13)
                    HStack(spacing: 12) {
                        chip("eye.fill", a.views)
                        Button(action: onLike) {
                            chip(a.liked ? "heart.fill" : "heart", a.likes, color: a.liked ? Color(argb: 0xFFEF4444) : nil)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 22, bottom: 22, trailing: 22))
            }
            .background(Brand.gradient([.white, Color(argb: 0xFFF8F9FF)]))
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .roundedBorder(Color(argb: 0xFFF0F0F0), radius: 20, width: 2)
        }
        .buttonStyle(.plain)
    }

    private func chip(_ icon: String, _ n: Int, color: Color? = nil) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color ?? Color(argb: 0xFF4B5563))
            Text(verbatim: "\(n)").font(.poppins(14, .bold)).foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Color(argb: 0xFFF8F9FA), in: RoundedRectangle(cornerRadius: 12))
        .roundedBorder(Brand.line, radius: 12)
    }
}

/// Article photo, or the site's default community picture.
struct ArticleImage: View {
    let path: String?

    var body: some View {
        if let path {
            CoverImage(path: path)
        } else {
            Color.clear.overlay { Image("community_default").resizable().scaledToFill() }.clipped()
        }
    }
}

/// Two-tone gradient heading, like the site's "So'nggi postlar".
struct GradientTitle: View {
    let text: String
    var size: CGFloat = 24
    var colors = [Brand.ink, Brand.indigo]

    var body: some View {
        Text(text.tr).font(.poppins(size, .heavy)).gradientText(colors)
    }
}

/// Rounded button filled with a gradient (the site's primary buttons here).
struct SiteGradientButton: View {
    let label: String
    let colors: [Color]
    var radius: CGFloat = 12
    var height: CGFloat = 44
    var fontSize: CGFloat = 15
    var horizontalPadding: CGFloat = 0
    var fullWidth = false
    var enabled = true
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label.tr)
                .font(.poppins(fontSize, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, horizontalPadding)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .frame(height: height)
                .background(Brand.gradient(colors), in: RoundedRectangle(cornerRadius: radius))
                .shadow(color: colors[0].opacity(0.3), radius: 7, y: 5)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}

private struct NoArticles: View {
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle").font(.system(size: 40)).foregroundStyle(Color(argb: 0xFFBDBDBD))
            Text("Maqola topilmadi!".tr).font(.poppins(15)).foregroundStyle(Color(argb: 0xFF717171))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 44)
        .background(.white, in: RoundedRectangle(cornerRadius: 20))
        .roundedBorder(Color(argb: 0xFFF0F0F0), radius: 20, width: 2)
    }
}
