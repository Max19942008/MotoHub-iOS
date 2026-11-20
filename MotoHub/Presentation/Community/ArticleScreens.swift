import SwiftUI

private let indigo = Brand.indigo

/// Website article page: boards, header card, content, comments.
struct ArticleDetailScreen: View {
    let articleID: String

    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var article: Article? = nil
    @State private var comments: PagedResult<Comment>? = nil
    @State private var page = 1
    @State private var text = ""
    @State private var sending = false
    @State private var liking = false
    @State private var failed: String? = nil

    var body: some View {
        Group {
            if let a = article {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        Button { router.pop() } label: {
                            Label("Back".tr, systemImage: "arrow.left")
                                .font(.poppins(15, .bold))
                                .foregroundStyle(indigo)
                                .padding(.horizontal, 18)
                                .padding(.vertical, 12)
                                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                                .roundedBorder(Brand.line, radius: 12, width: 2)
                        }
                        .buttonStyle(.plain)
                        Text("Doskalar".tr).font(.poppins(20, .heavy)).foregroundStyle(Brand.ink).padding(.top, 26)
                        BoardList(selected: a.category) { board in
                            router.communityBoard = board
                            router.pop()
                        }
                        .padding(.top, 20)
                        header(a).padding(.top, 24)
                        content(a).padding(.top, 24)
                        commentsCard.padding(.top, 24)
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 90, trailing: 20))
                }
                .refreshable {
                    await refresh()
                    await loadComments()
                }
            } else if let failed {
                MessageView(systemImage: "exclamationmark.triangle", message: failed) {
                    self.failed = nil
                    Task { await refresh() }
                }
                .frame(maxHeight: .infinity)
            } else {
                LoadingView().frame(maxHeight: .infinity)
            }
        }
        .background(communityBackground)
        .sitePage(back: true)
        .task {
            guard article == nil else { return }
            await refresh()
            await loadComments()
        }
    }

    private func refresh() async {
        do {
            article = try await app.community.article(id: articleID)
        } catch {
            if article == nil { failed = error.localizedDescription }
        }
    }

    private func loadComments() async {
        if let c = try? await app.listings.comments(refID: articleID, page: page) { comments = c }
    }

    private func like() async {
        guard session.isLoggedIn else { return router.toast("Avval tizimga kiring".tr) }
        guard !liking else { return }
        liking = true
        defer { liking = false }
        do {
            try await app.community.likeArticle(id: articleID)
            await refresh()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func send() async {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !sending else { return }
        guard session.isLoggedIn else { return router.toast("Avval tizimga kiring".tr) }
        sending = true
        defer { sending = false }
        do {
            try await app.listings.addComment(group: "ARTICLE", refID: articleID, content: content)
            text = ""
            page = 1
            await loadComments()
            await refresh()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func card<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .padding(22)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.gradient([.white, Color(argb: 0xFFF8F9FF)]), in: RoundedRectangle(cornerRadius: 24))
            .shadow(color: Color(argb: 0x0F000000), radius: 15, y: 10)
    }

    private func header(_ a: Article) -> some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text(a.category)
                        .font(.poppins(12, .heavy))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Brand.gradient([indigo, Color(argb: 0xFFA855F7)]), in: RoundedRectangle(cornerRadius: 12))
                    Spacer()
                    SiteGradientButton(label: "Write Article", colors: [indigo, Brand.indigoDark], height: 36, fontSize: 13.5,
                                       horizontalPadding: 18) {
                        router.openWriteArticle(loggedIn: session.isLoggedIn)
                    }
                }
                GradientTitle(text: a.title, size: 23).padding(.top, 18)
                Brand.line.frame(height: 2).padding(.vertical, 16)
                HStack(spacing: 12) {
                    Avatar(path: a.authorImage, size: 42)
                        .padding(2)
                        .overlay(Circle().strokeBorder(indigo, lineWidth: 2.5))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(a.author).font(.poppins(15.5, .bold)).foregroundStyle(Brand.ink)
                        Text(articleDate(a.createdAt)).font(.poppins(13)).foregroundStyle(Color(argb: 0xFF717171))
                    }
                }
                FlowLayout(spacing: 10) {
                    stat("eye.fill", a.views)
                    stat("bubble.left.fill", a.comments)
                    Button { Task { await like() } } label: {
                        HStack(spacing: 8) {
                            Image(systemName: a.liked ? "hand.thumbsup.fill" : "hand.thumbsup").font(.system(size: 16))
                            Text(verbatim: "\(a.likes)").font(.poppins(14, .bold))
                        }
                        .foregroundStyle(a.liked ? .white : Brand.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(a.liked ? Brand.gradient([indigo, Color(argb: 0xFFA855F7)]) : Brand.gradient([.white, .white]),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(a.liked ? .clear : Brand.line, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 14)
            }
        }
    }

    private func stat(_ icon: String, _ n: Int) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(Color(argb: 0xFF4B5563))
            Text(verbatim: "\(n)").font(.poppins(14, .bold)).foregroundStyle(Brand.ink)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .roundedBorder(Brand.line, radius: 12, width: 2)
    }

    /// <img src="…"> in the article HTML, shown under the text.
    private func images(in html: String) -> [String] {
        guard let regex = try? NSRegularExpression(pattern: "<img[^>]+src=[\"']([^\"']+)[\"']") else { return [] }
        let ns = html as NSString
        return regex.matches(in: html, range: NSRange(location: 0, length: ns.length)).map { ns.substring(with: $0.range(at: 1)) }
    }

    private func content(_ a: Article) -> some View {
        card {
            VStack(alignment: .leading, spacing: 0) {
                GradientTitle(text: "Maqola matni", size: 21)
                Brand.gradient([indigo, Color(argb: 0xFFA855F7), .clear]).frame(height: 3).padding(.top, 10).padding(.bottom, 20)
                VStack(alignment: .leading, spacing: 14) {
                    Text(Formatting.plainText(a.content))
                        .font(.poppins(15))
                        .lineSpacing(8)
                        .foregroundStyle(Brand.ink)
                        .textSelection(.enabled)
                    ForEach(images(in: a.content), id: \.self) { src in
                        RemoteImage(path: src, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(EdgeInsets(top: 26, leading: 24, bottom: 26, trailing: 24))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.white, in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var commentsCard: some View {
        let total = comments?.total ?? 0
        let pages = Int((Double(total) / 5).rounded(.up))
        let empty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        return card {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 0) {
                    GradientTitle(text: "Izohlar", size: 22)
                    Text(verbatim: " (\(total))").font(.poppins(22, .bold)).foregroundStyle(Color(argb: 0xFF717171))
                }
                TextField("", text: $text, prompt: Text("Fikringizni baham ko'ring...".tr).foregroundStyle(Color(argb: 0xFF9CA3AF)))
                    .font(.poppins(15))
                    .padding(.horizontal, 18)
                    .padding(.vertical, 16)
                    .background(.white, in: RoundedRectangle(cornerRadius: 14))
                    .roundedBorder(Brand.line, radius: 14, width: 2)
                    .onChange(of: text) { _, v in if v.count > 100 { text = String(v.prefix(100)) } }
                    .padding(.top, 18)
                HStack {
                    Text(verbatim: "\(text.count)/100").font(.poppins(13)).foregroundStyle(Color(argb: 0xFF4B5563))
                    Spacer()
                    SiteGradientButton(label: sending ? "..." : "Izoh qoldirish", colors: [indigo, Color(argb: 0xFF8B5CF6)],
                                       height: 36, fontSize: 14, horizontalPadding: 22, enabled: !empty && !sending) {
                        Task { await send() }
                    }
                }
                .padding(.top, 10)
                if let comments, !comments.items.isEmpty {
                    VStack(spacing: 12) {
                        ForEach(comments.items) { m in
                            HStack(alignment: .top, spacing: 12) {
                                Avatar(path: m.authorImage, size: 33)
                                    .padding(1.5)
                                    .overlay(Circle().strokeBorder(indigo, lineWidth: 2))
                                VStack(alignment: .leading, spacing: 0) {
                                    Text(m.author).font(.poppins(13.5, .bold)).foregroundStyle(Brand.ink)
                                    Text(commentDate(m.createdAt)).font(.poppins(11.5)).foregroundStyle(Brand.muted)
                                    Text(m.content).font(.poppins(14)).foregroundStyle(Brand.ink).padding(.top, 8)
                                }
                                Spacer(minLength: 0)
                            }
                            .padding(18)
                            .background(Brand.gradient([.white, Color(argb: 0xFFFAFAFF)]), in: RoundedRectangle(cornerRadius: 16))
                            .roundedBorder(Brand.line, radius: 16, width: 2)
                        }
                    }
                    .padding(.top, 20)
                }
                if pages > 1 {
                    HStack(spacing: 6) {
                        ForEach(1...pages, id: \.self) { p in
                            Button {
                                page = p
                                Task { await loadComments() }
                            } label: {
                                Text(verbatim: "\(p)")
                                    .font(.poppins(14, .semibold))
                                    .foregroundStyle(p == page ? .white : Brand.ink)
                                    .frame(width: 32, height: 32)
                                    .background(p == page ? indigo : .clear, in: Circle())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.top, 12)
                }
            }
        }
    }

    /// "Jan 15, 2026 • 13:27"
    private func commentDate(_ d: Date?) -> String {
        guard let d else { return "" }
        let full = articleDate(d)
        let c = Calendar.current.dateComponents([.hour, .minute], from: d)
        guard let space = full.firstIndex(of: " ") else { return full }
        return "\(full.prefix(3))\(full[space...]) • \(String(format: "%02d:%02d", c.hour ?? 0, c.minute ?? 0))"
    }
}

/// The site's "Write an Article" form: category, title, text, Register.
struct WriteArticleScreen: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var category: String
    @State private var title = ""
    @State private var bodyText = ""
    @State private var saving = false

    private static let categories = [("FREE", "Free"), ("HUMOR", "Humor"), ("NEWS", "News"), ("RECOMMEND", "Recommendation")]

    init(category: String = "FREE") {
        _category = State(initialValue: category)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Maqola yozish".tr).font(.poppins(24, .heavy)).foregroundStyle(Brand.ink)
                Text("G'oyalaringizni bemalol yozing!".tr).font(.poppins(14)).foregroundStyle(Brand.muted).padding(.top, 4)
                label("Turkum").padding(.top, 26)
                Menu {
                    ForEach(Self.categories.indices, id: \.self) { i in
                        Button(Self.categories[i].1.tr) { category = Self.categories[i].0 }
                    }
                } label: {
                    HStack {
                        Text((Self.categories.first { $0.0 == category }?.1 ?? "Free").tr).font(.poppins(15)).foregroundStyle(Brand.ink)
                        Spacer()
                        Image(systemName: "chevron.down").foregroundStyle(Brand.muted)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 52)
                    .background(.white, in: RoundedRectangle(cornerRadius: 12))
                    .roundedBorder(Brand.line, radius: 12)
                }
                .padding(.top, 8)
                label("Sarlavha").padding(.top, 18)
                field(TextField("", text: $title, prompt: Text("Type Title".tr)), max: 50, count: title.count)
                    .onChange(of: title) { _, v in if v.count > 50 { title = String(v.prefix(50)) } }
                    .padding(.top, 8)
                label("Matn").padding(.top, 8)
                field(TextField("", text: $bodyText, prompt: Text("Type here".tr), axis: .vertical).lineLimit(10...18),
                      max: 230, count: bodyText.count)
                    .onChange(of: bodyText) { _, v in if v.count > 230 { bodyText = String(v.prefix(230)) } }
                    .padding(.top, 8)
                Button { Task { await submit() } } label: {
                    Group {
                        if saving { ProgressView().tint(.white) } else { Text("Joylash".tr).font(.poppins(15, .bold)) }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 250, height: 45)
                    .background(Brand.green, in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(.plain)
                .disabled(saving)
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
            }
            .padding(EdgeInsets(top: 26, leading: 20, bottom: 40, trailing: 20))
        }
        .background(Color(argb: 0xFFF7F8FA))
        .scrollDismissesKeyboard(.interactively)
        .sitePage(back: true)
    }

    private func label(_ text: String) -> some View {
        Text(text.tr).font(.poppins(15, .semibold)).foregroundStyle(Color(argb: 0xFF7F838D))
    }

    private func field<F: View>(_ input: F, max: Int, count: Int) -> some View {
        VStack(alignment: .trailing, spacing: 4) {
            input
                .font(.poppins(15))
                .textInputAutocapitalization(.sentences)
                .padding(14)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .roundedBorder(Brand.line, radius: 12)
            Text(verbatim: "\(count)/\(max)").font(.poppins(12)).foregroundStyle(Brand.muted)
        }
    }

    /// Same HTML the site's editor produces, so the post renders on the web too.
    static func toHTML(_ text: String) -> String {
        let paragraphs = text.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\n\\s*\\n", with: "\u{0}", options: .regularExpression)
            .split(separator: "\u{0}")
        return paragraphs.map { p in
            let escaped = p.trimmingCharacters(in: .whitespacesAndNewlines)
                .replacingOccurrences(of: "&", with: "&amp;")
                .replacingOccurrences(of: "<", with: "&lt;")
                .replacingOccurrences(of: ">", with: "&gt;")
                .replacingOccurrences(of: "\n", with: "<br>")
            return "<p>\(escaped)</p>"
        }.joined()
    }

    private func submit() async {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let b = bodyText.trimmingCharacters(in: .whitespacesAndNewlines)
        var problem: String?
        if t.count < 3 || t.count > 50 {
            problem = "Sarlavha 3–50 belgidan iborat bo'lishi kerak"
        } else if b.count < 3 {
            problem = "Maqola matnini yozing"
        } else if Self.toHTML(b).count > 250 {
            problem = "Matn juda uzun (taxminan 230 belgigacha)"
        }
        if let problem { return router.toast(problem.tr) }
        saving = true
        defer { saving = false }
        do {
            _ = try await app.community.createArticle(category: category, title: t, content: Self.toHTML(b))
            router.toast("Maqola muvaffaqiyatli joylandi".tr)
            router.articlePublished()
            router.pop()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}
