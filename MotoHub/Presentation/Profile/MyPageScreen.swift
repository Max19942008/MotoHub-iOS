import PhotosUI
import SwiftUI

private let violet = Color(argb: 0xFF667EEA)
private let purple = Color(argb: 0xFF764BA2)
private let muted = Color(argb: 0xFF717171)

enum MySection: String, CaseIterable, Identifiable {
    case addBike, myBikes, addPart, myParts, favorites, visited, followers, followings, articles, write, profile

    var id: String { rawValue }

    var label: String {
        switch self {
        case .addBike: "E'lon qo'shish"
        case .myBikes: "Mening mototsikllarim"
        case .addPart: "Qism qo'shish"
        case .myParts: "Mening qismlarim"
        case .favorites: "Sevimlilarim"
        case .visited: "Yaqinda ko'rilganlar"
        case .followers: "Obunachilarim"
        case .followings: "Obunalarim"
        case .articles: "Maqolalar"
        case .write: "Maqola yozish"
        case .profile: "Mening profilim"
        }
    }

    var icon: String {
        switch self {
        case .addBike: "plus.square"
        case .myBikes: "scooter"
        case .addPart: "plus.circle"
        case .myParts: "wrench"
        case .favorites: "heart"
        case .visited: "doc.text.magnifyingglass"
        case .followers: "person.2"
        case .followings: "person.badge.plus"
        case .articles: "safari"
        case .write: "square.and.pencil"
        case .profile: "person.crop.circle"
        }
    }
}

/// The website's "My page" on a phone: menu card on top, the chosen section below.
struct MyPageScreen: View {
    let member: Member

    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var section = MySection.profile
    @State private var confirmLogout = false

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 0) {
                    VStack(spacing: 20) {
                        MenuCard(member: member, section: section, onPick: { pick($0, proxy) }) { confirmLogout = true }
                        content.id("content")
                    }
                    .padding(EdgeInsets(top: 14, leading: 12, bottom: 20, trailing: 12))
                    .background(.white, in: RoundedRectangle(cornerRadius: 16))
                    .roundedBorder(Color(argb: 0xFFC4C4C4), radius: 16)
                    .shadow(color: Color(argb: 0x12181A20), radius: 2, y: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                    SiteFooter()
                }
            }
        }
        .background(Color(argb: 0xFFF6F6F6))
        .alert("Chiqish".tr, isPresented: $confirmLogout) {
            Button("Bekor qilish".tr, role: .cancel) {}
            Button("Chiqish".tr, role: .destructive) { Task { await session.logout() } }
        } message: {
            Text("Hisobingizdan chiqmoqchimisiz?".tr)
        }
        .onChange(of: router.myPageSection) { _, s in
            guard let s, let target = MySection(rawValue: s) else { return }
            router.myPageSection = nil
            section = target
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .profile: ProfileSection(member: member)
        case .favorites: BikesSection(visited: false).id("fav")
        case .visited: BikesSection(visited: true).id("visited")
        case .followers: FollowSection(memberID: member.id, followers: true).id("followers")
        case .followings: FollowSection(memberID: member.id, followers: false).id("followings")
        case .articles: ArticlesSection(memberID: member.id)
        case .myBikes: ListingsSection(part: false).id("myBikes")
        case .myParts: ListingsSection(part: true).id("myParts")
        case .write, .addBike, .addPart: EmptyView()
        }
    }

    private func pick(_ s: MySection, _ proxy: ScrollViewProxy) {
        switch s {
        case .write:
            router.openWriteArticle(loggedIn: true)
        case .addBike:
            router.push(.addListing(part: false, motorbike: nil, sparePart: nil))
        case .addPart:
            router.push(.addListing(part: true, motorbike: nil, sparePart: nil))
        default:
            section = s
            // Bring the section into view, like the site's page jump.
            DispatchQueue.main.async { withAnimation(.easeOut(duration: 0.35)) { proxy.scrollTo("content", anchor: .top) } }
        }
    }
}

// MARK: - Menu

private struct MenuCard: View {
    let member: Member
    let section: MySection
    let onPick: (MySection) -> Void
    let onLogout: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 16) {
                Avatar(path: member.imagePath, size: 60)
                VStack(alignment: .leading, spacing: 0) {
                    Text(member.nick).font(.poppins(16, .semibold)).foregroundStyle(Brand.ink)
                    if let phone = member.phone, !phone.isEmpty {
                        HStack(spacing: 6) {
                            Image(systemName: "phone").font(.system(size: 12)).foregroundStyle(Brand.ink)
                            Text(phone).font(.poppins(13, .medium)).foregroundStyle(muted)
                        }
                        .padding(.top, 6)
                    }
                    Text(member.type ?? "USER").font(.poppins(12, .bold)).foregroundStyle(.red).padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 4, trailing: 16))
            title("MANAGE LISTINGS")
            // Dealers manage their own bikes and parts here, as on the site.
            if member.isAgent {
                item(.addBike)
                item(.myBikes)
                item(.addPart)
                item(.myParts)
            }
            item(.favorites)
            item(.visited)
            item(.followers)
            item(.followings)
            title("COMMUNITY")
            item(.articles)
            item(.write)
            title("MANAGE ACCOUNT")
            item(.profile)
            MenuItem(label: "Logout", icon: "rectangle.portrait.and.arrow.right", active: false, action: onLogout)
        }
        .padding(.bottom, 12)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .roundedBorder(Color(argb: 0xC9C4C4C4), radius: 12)
        .shadow(color: Color(argb: 0x12181A20), radius: 2, y: 1)
    }

    private func title(_ text: String) -> some View {
        Text(text.tr).font(.poppins(13, .semibold)).kerning(0.5).foregroundStyle(muted)
            .padding(EdgeInsets(top: 18, leading: 16, bottom: 8, trailing: 16))
    }

    private func item(_ s: MySection) -> some View {
        MenuItem(label: s.label, icon: s.icon, active: s == section) { onPick(s) }
    }
}

private struct MenuItem: View {
    let label: String
    let icon: String
    let active: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon).font(.system(size: 17)).frame(width: 22)
                Text(label.tr).font(.poppins(14, .semibold))
                Spacer(minLength: 0)
            }
            .foregroundStyle(active ? .white : Brand.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(active ? Color.black : .clear, in: RoundedRectangle(cornerRadius: 10))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    }
}

// MARK: - Shared pieces

/// "✨ My Profile" style heading with the violet underline and a subtitle.
private struct MySectionTitle<Trailing: View>: View {
    let title: String
    let subtitle: String
    var label: String?
    @ViewBuilder var trailing: () -> Trailing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if let label {
                Text(label.tr).font(.poppins(11, .bold)).kerning(1).foregroundStyle(Color(argb: 0xFF9CA3AF))
            }
            Text(title.tr).font(.poppins(24, .heavy)).gradientText([violet, purple])
            Capsule().fill(Brand.gradient([violet, purple])).frame(width: 60, height: 3).padding(.top, 6).padding(.bottom, 10)
            Text(subtitle.tr).font(.poppins(14)).lineSpacing(4).foregroundStyle(Brand.muted)
            trailing().padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 0, leading: 4, bottom: 18, trailing: 4))
    }
}

extension MySectionTitle where Trailing == EmptyView {
    init(title: String, subtitle: String, label: String? = nil) {
        self.init(title: title, subtitle: subtitle, label: label, trailing: { EmptyView() })
    }
}

/// Dashed "nothing here" box with the site's ⓘ icon.
private struct EmptyBox: View {
    let text: String

    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: "exclamationmark")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Color(argb: 0xFFD1D5DB))
                .frame(width: 64, height: 64)
                .overlay(Circle().strokeBorder(Color(argb: 0xFFD1D5DB), lineWidth: 2))
            Text(text.tr).font(.poppins(15, .bold)).foregroundStyle(violet).multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 46)
        .padding(.horizontal, 16)
        .background(Brand.gradient([Color(argb: 0xFFF8F9FF), Color(argb: 0xFFEEF0FF)]), in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(Color(argb: 0xFFC7CBF5), radius: 16, width: 1.5)
    }
}

private struct Pager: View {
    let page: Int
    let total: Int
    let perPage: Int
    let onPage: (Int) -> Void

    var body: some View {
        let pages = Int((Double(total) / Double(perPage)).rounded(.up))
        if pages >= 2 {
            FlowLayout(spacing: 6, lineSpacing: 6) {
                ForEach(1...pages, id: \.self) { p in
                    Button { onPage(p) } label: {
                        Text(verbatim: "\(p)")
                            .font(.poppins(14, .semibold))
                            .foregroundStyle(p == page ? .white : Brand.ink)
                            .frame(width: 34, height: 34)
                            .background(p == page ? violet : .white, in: Circle())
                            .overlay(Circle().strokeBorder(p == page ? violet : Brand.line))
                    }
                    .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 12)
        }
    }
}

/// One page of a list, re-loaded on page change; loading / error / content.
@MainActor
@Observable
private final class PageLoader<T: Sendable> {
    var page = 1
    private(set) var result: PagedResult<T>?
    private(set) var error: String?
    private let fetch: (Int) async throws -> PagedResult<T>

    init(_ fetch: @escaping (Int) async throws -> PagedResult<T>) {
        self.fetch = fetch
    }

    func load() async {
        do {
            result = try await fetch(page)
            error = nil
        } catch is CancellationError {
        } catch {
            self.error = error.localizedDescription
        }
    }

    func go(_ p: Int) {
        page = p
        Task { await load() }
    }

    func reset() {
        page = 1
        result = nil
    }
}

private struct PageBody<T: Sendable, Content: View>: View {
    let loader: PageLoader<T>
    @ViewBuilder let content: (PagedResult<T>) -> Content

    var body: some View {
        if let error = loader.error {
            MessageView(systemImage: "icloud.slash", message: error) { Task { await loader.load() } }
        } else if let result = loader.result {
            content(result)
        } else {
            LoadingView().frame(height: 200)
        }
    }
}

// MARK: - Bikes

private struct BikesSection: View {
    let visited: Bool
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var loader: PageLoader<Motorbike>? = nil

    var body: some View {
        let total = loader?.result?.total ?? 0
        let page = loader?.page ?? 1
        let from = total == 0 ? 0 : (page - 1) * 6 + 1
        let to = min(page * 6, total)
        VStack(spacing: 0) {
            MySectionTitle(
                title: visited ? "Yaqinda Ko'rilganlar" : "Sevimlilarim",
                subtitle: visited ? "Ko'rish tarixingizni ko'ring • O'rgangan mototsikllaringizga qayting"
                                  : "Sevimli mototsikllaringizni boshqaring • Saqlang va istalgan vaqtda qayting",
                label: visited ? "TARIX" : "FAVORITES"
            ) {
                HStack {
                    Text("\(total) bikes".tr).font(.poppins(17, .bold)).foregroundStyle(Brand.ink)
                    Spacer()
                    Text("Showing \(from)-\(to) of \(total)".tr).font(.poppins(12.5)).foregroundStyle(muted)
                }
            }
            if let loader {
                PageBody(loader: loader) { r in
                    if r.items.isEmpty {
                        EmptyBox(text: visited ? "Yaqinda ko'rilganlar topilmadi!" : "Sevimlilar topilmadi!")
                    } else {
                        VStack(spacing: 18) {
                            ForEach(r.items) { bike in
                                ListingCard.listBike(bike) { router.push(.motorbike(bike)) }
                            }
                            Pager(page: loader.page, total: r.total, perPage: 6, onPage: loader.go)
                        }
                    }
                }
            }
        }
        .task {
            guard loader == nil else { return }
            let repo = app.myPage
            let visited = visited
            let l = PageLoader { try await repo.myBikes(page: $0, visited: visited) }
            loader = l
            await l.load()
        }
        // An unlike on the bike page removes it from favourites.
        .onAppear { if loader?.result != nil { Task { await loader?.load() } } }
    }
}

// MARK: - Follows

private struct FollowSection: View {
    let memberID: String
    let followers: Bool
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var loader: PageLoader<FollowMember>? = nil

    var body: some View {
        VStack(spacing: 0) {
            MySectionTitle(title: followers ? "Followers" : "Followings",
                           subtitle: followers ? "Sizni kuzatayotgan foydalanuvchilar" : "Siz kuzatayotgan foydalanuvchilar")
            if let loader {
                PageBody(loader: loader) { r in
                    if r.items.isEmpty {
                        EmptyBox(text: followers ? "HALI OBUNACHILAR YO'Q!" : "HALI OBUNALAR YO'Q!")
                    } else {
                        VStack(spacing: 14) {
                            ForEach(r.items) { row($0) }
                            Pager(page: loader.page, total: r.total, perPage: 5, onPage: loader.go)
                        }
                    }
                }
            }
        }
        .task {
            guard loader == nil else { return }
            let repo = app.myPage
            let id = memberID
            let followers = followers
            let l = PageLoader { try await repo.follows(memberID: id, page: $0, followers: followers) }
            loader = l
            await l.load()
        }
    }

    private func row(_ f: FollowMember) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Button { router.push(.agent(f.id)) } label: {
                HStack(spacing: 14) {
                    Avatar(path: f.imagePath, size: 56)
                    Text(f.nick).font(.poppins(16, .bold)).foregroundStyle(Brand.ink)
                    Spacer(minLength: 0)
                }
            }
            .buttonStyle(.plain)
            HStack {
                count("Followers", f.followers)
                count("Followings", f.followings)
                Button { Task { await run { try await app.agents.likeMember(id: f.id) } } } label: {
                    HStack(spacing: 4) {
                        Image(systemName: f.liked ? "heart.fill" : "heart").font(.system(size: 16)).foregroundStyle(f.liked ? .red : muted)
                        Text(verbatim: "(\(f.likes))").font(.poppins(13)).foregroundStyle(muted)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
            }
            if f.id != memberID {
                Button {
                    Task {
                        await run {
                            if f.followed {
                                try await app.agents.unfollow(id: f.id)
                            } else {
                                try await app.agents.follow(id: f.id)
                            }
                        }
                    }
                } label: {
                    Text((f.followed ? "Unfollow" : "Follow").tr)
                        .font(.poppins(15, .bold))
                        .foregroundStyle(f.followed ? Brand.green : .white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(f.followed ? .white : violet, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(f.followed ? Brand.green : .clear, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(16)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(Brand.line, radius: 16)
    }

    private func count(_ label: String, _ value: Int) -> some View {
        (Text(label.tr + " ").font(.poppins(13)).foregroundColor(muted)
            + Text(verbatim: "(\(value))").font(.poppins(13, .bold)).foregroundColor(Brand.ink))
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func run(_ action: () async throws -> Void) async {
        do {
            try await action()
            await loader?.load()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}

// MARK: - Articles

private struct ArticlesSection: View {
    let memberID: String
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var loader: PageLoader<Article>? = nil

    var body: some View {
        VStack(spacing: 0) {
            MySectionTitle(title: "Maqola", subtitle: "Sizni yana ko'rganimizdan xursandmiz!")
            if let loader {
                PageBody(loader: loader) { r in
                    if r.items.isEmpty {
                        EmptyBox(text: "Maqolalar topilmadi!")
                    } else {
                        VStack(spacing: 18) {
                            ForEach(r.items) { a in
                                ArticleCard(article: a, onTap: { router.push(.article(a.id)) }, onLike: {
                                    Task {
                                        do {
                                            try await app.community.likeArticle(id: a.id)
                                            await loader.load()
                                        } catch {
                                            router.toast(error.localizedDescription.tr)
                                        }
                                    }
                                })
                            }
                            Pager(page: loader.page, total: r.total, perPage: 6, onPage: loader.go)
                        }
                    }
                }
            }
        }
        .task {
            if loader == nil {
                let repo = app.community
                let id = memberID
                loader = PageLoader { try await repo.memberArticles(memberID: id, page: $0) }
            }
            await loader?.load()
        }
        .onChange(of: router.articlesChanged) { _, _ in Task { await loader?.load() } }
    }
}

// MARK: - Profile

private struct ProfileSection: View {
    let member: Member
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var nick: String
    @State private var phone: String
    @State private var address: String
    @State private var image: String? = nil
    @State private var photo: PhotosPickerItem? = nil
    @State private var uploading = false
    @State private var saving = false
    @State private var confirmDelete = false

    init(member: Member) {
        self.member = member
        _nick = State(initialValue: member.nick)
        _phone = State(initialValue: member.phone ?? "")
        _address = State(initialValue: member.address ?? "")
        _image = State(initialValue: member.imagePath)
    }

    private var changed: Bool {
        nick.trimmingCharacters(in: .whitespaces) != member.nick
            || phone.trimmingCharacters(in: .whitespaces) != (member.phone ?? "")
            || address.trimmingCharacters(in: .whitespaces) != (member.address ?? "")
            || image != member.imagePath
    }

    var body: some View {
        let canSave = changed && !saving && !uploading
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(violet)
                    Text("My Profile".tr).font(.poppins(26, .heavy)).gradientText([violet, purple])
                }
                Capsule().fill(Brand.gradient([violet, purple])).frame(width: 60, height: 3).padding(.top, 6).padding(.bottom, 10)
                Text("🌟 We are glad to see you again!".tr).font(.poppins(15)).foregroundStyle(violet)
            }
            .padding(EdgeInsets(top: 0, leading: 4, bottom: 24, trailing: 4))
            VStack(alignment: .leading, spacing: 0) {
                Text("Rasm".tr).font(.poppins(18, .bold)).gradientText([violet, purple])
                Group {
                    if uploading {
                        LoadingView()
                    } else if image == nil {
                        DefaultAvatar()
                    } else {
                        CoverImage(path: image)
                    }
                }
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: violet.opacity(0.25), radius: 10, y: 8)
                .padding(.top, 18)
                PhotosPicker(selection: $photo, matching: .images) {
                    Text("Profil rasmini yuklash".tr)
                        .font(.poppins(14, .bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .frame(height: 44)
                        .background(Brand.gradient([violet, purple]), in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: violet.opacity(0.3), radius: 7, y: 5)
                }
                .disabled(uploading)
                .padding(.top, 16)
                Text("A photo must be in JPG, JPEG or PNG format!".tr).font(.poppins(12.5)).foregroundStyle(violet).padding(.top, 12)
                VStack(spacing: 18) {
                    field("USERNAME", icon: "person.fill", color: Color(argb: 0xFF5B3E96), text: $nick, hint: "Taxallusingiz")
                    field("PHONE", icon: "phone.fill", color: Color(argb: 0xFFE11D48), text: $phone, hint: "Telefon raqamingiz",
                          keyboard: .phonePad)
                    field("ADDRESS", icon: "mappin.and.ellipse", color: Color(argb: 0xFFEC4899), text: $address, hint: "Manzilingiz")
                }
                .padding(.top, 22)
                SiteGradientButton(label: saving ? "..." : "Profilni yangilash  ↗",
                                   colors: canSave ? [violet, purple] : [Color(argb: 0xFFC4C4C4), Color(argb: 0xFFBDBDBD)],
                                   height: 44, fontSize: 14.5, horizontalPadding: 20, enabled: canSave) {
                    Task { await save() }
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 18)
            }
            .padding(EdgeInsets(top: 22, leading: 16, bottom: 22, trailing: 16))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.gradient([.white, Color(argb: 0xFFF8F9FF)]), in: RoundedRectangle(cornerRadius: 20))
            .roundedBorder(violet.opacity(0.15), radius: 20)
            .shadow(color: violet.opacity(0.12), radius: 12, y: 8)
            Button(role: .destructive) { confirmDelete = true } label: {
                Label("Hisobni o'chirish".tr, systemImage: "trash").font(.poppins(15, .semibold)).foregroundStyle(.red)
            }
            .padding(.top, 22)
            .padding(.horizontal, 8)
            Link(destination: AppConfig.privacyPolicyURL) {
                Text("Maxfiylik siyosati".tr).font(.poppins(15, .medium)).foregroundStyle(muted)
            }
            .padding(.top, 14)
            .padding(.horizontal, 8)
        }
        .onChange(of: photo) { _, item in
            guard let item else { return }
            Task { await upload(item) }
        }
        .alert("Hisobni o'chirish".tr, isPresented: $confirmDelete) {
            Button("Bekor qilish".tr, role: .cancel) {}
            Button("O'chirish".tr, role: .destructive) { Task { await deleteAccount() } }
        } message: {
            Text("Hisobingiz butunlay o'chiriladi: barcha qurilmalardagi sessiyalar yopiladi, e'lonlaringiz va maqolalaringiz saytdan olib tashlanadi. Buni qaytarib bo'lmaydi.".tr)
        }
    }

    private func field(_ label: String, icon: String, color: Color, text: Binding<String>, hint: String,
                       keyboard: UIKeyboardType = .default) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon).font(.system(size: 14)).foregroundStyle(color)
                Text(label.tr).font(.poppins(13, .bold)).kerning(0.5).foregroundStyle(violet)
            }
            TextField("", text: text, prompt: Text(hint.tr).foregroundStyle(Color(argb: 0xFFA0A0A0)))
                .font(.poppins(15))
                .keyboardType(keyboard)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding(.horizontal, 18)
                .frame(height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 10))
                .roundedBorder(violet.opacity(0.2), radius: 10, width: 2)
        }
    }

    private func upload(_ item: PhotosPickerItem) async {
        uploading = true
        defer {
            uploading = false
            photo = nil
        }
        do {
            guard let raw = try await item.loadTransferable(type: Data.self), let jpeg = ImageEncoding.jpeg(raw) else {
                return router.toast("A photo must be in JPG, JPEG or PNG format!".tr)
            }
            image = try await app.myPage.uploadImage(jpeg, fileName: "photo.jpg", target: "member")
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func save() async {
        let n = nick.trimmingCharacters(in: .whitespaces)
        let p = phone.trimmingCharacters(in: .whitespaces)
        let a = address.trimmingCharacters(in: .whitespaces)
        guard (3...20).contains(n.count) else { return router.toast("Taxallus 3–20 belgidan iborat bo'lishi kerak".tr) }
        saving = true
        defer { saving = false }
        do {
            try await session.updateProfile(
                nick: n == member.nick ? nil : n,
                phone: p == (member.phone ?? "") ? nil : p,
                address: a == (member.address ?? "") ? nil : a,
                imagePath: image == member.imagePath ? nil : image
            )
            router.toast("Profil yangilandi".tr)
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func deleteAccount() async {
        do {
            try await session.deleteAccount()
            router.toast("Hisobingiz o'chirildi".tr)
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}

// MARK: - My listings

/// "My Bikes" / "My Parts": Active / Blocked / Archived tabs, edit, archive,
/// re-list and delete, like the site's garage page.
private struct ListingsSection: View {
    let part: Bool
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var status = "ACTIVE"
    @State private var page = 1
    @State private var bikes: PagedResult<Motorbike>? = nil
    @State private var parts: PagedResult<Part>? = nil
    @State private var error: String? = nil
    @State private var deleting: String? = nil

    private static let tabs = [("ACTIVE", "Faol"), ("HOLD", "Bloklangan"), ("SOLD", "Arxivlangan")]

    private var total: Int { part ? (parts?.total ?? 0) : (bikes?.total ?? 0) }
    private var loaded: Bool { part ? parts != nil : bikes != nil }
    private var isEmpty: Bool { part ? (parts?.items.isEmpty ?? true) : (bikes?.items.isEmpty ?? true) }

    var body: some View {
        VStack(spacing: 0) {
            MySectionTitle(
                title: part ? "Mening qismlarim" : "Mening mototsikllarim",
                subtitle: part ? "Qism va aksessuarlaringizni boshqaring, ma'lumotlarni yangilang."
                               : "E'lonlaringizni boshqaring, ma'lumotlarni yangilang va eskilarini arxivlang.",
                label: "GARAJ"
            ) {
                HStack {
                    Text("\(total) \(part ? "parts" : "bikes")".tr).font(.poppins(17, .bold)).foregroundStyle(Brand.ink)
                    Spacer()
                    SiteGradientButton(label: part ? "+ Qism qo'shish" : "+ E'lon qo'shish", colors: [violet, purple],
                                       height: 38, fontSize: 13.5, horizontalPadding: 16) {
                        router.push(.addListing(part: part, motorbike: nil, sparePart: nil))
                    }
                }
            }
            HStack(spacing: 0) {
                ForEach(Self.tabs.indices, id: \.self) { i in
                    let t = Self.tabs[i]
                    Button {
                        status = t.0
                        page = 1
                        bikes = nil
                        parts = nil
                        Task { await load() }
                    } label: {
                        Text(t.1.tr)
                            .font(.poppins(14, .semibold))
                            .foregroundStyle(status == t.0 ? Brand.ink : muted)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .overlay(alignment: .bottom) { (status == t.0 ? Brand.ink : .clear).frame(height: 2) }
                    }
                    .buttonStyle(.plain)
                }
            }
            .background(.white)
            .overlay(alignment: .bottom) { Color(argb: 0xFFDDDDDD).frame(height: 1) }
            Group {
                if let error {
                    MessageView(systemImage: "icloud.slash", message: error) { Task { await load() } }
                } else if !loaded {
                    LoadingView().frame(height: 200)
                } else if isEmpty {
                    EmptyBox(text: part ? "Qismlar topilmadi!" : "Mototsikllar topilmadi!")
                } else {
                    VStack(spacing: 22) {
                        if part {
                            ForEach(parts?.items ?? []) { p in
                                card(id: p.id, ListingCard(
                                    image: p.imagePaths.first, title: p.title,
                                    kicker: "\(Formatting.label(p.brand)) · \(Formatting.label(p.type).tr)",
                                    price: Formatting.price(p.price, currency: p.currency), location: Formatting.label(p.location),
                                    badge: p.category, rating: Formatting.siteRating(p.rank),
                                    chips: [CardChip(icon: "square.grid.2x2.fill", text: Formatting.label(p.type)),
                                            CardChip(icon: "wrench.fill", text: Formatting.label(p.condition)),
                                            CardChip(icon: "shippingbox.fill", text: "\(p.stock) dona")],
                                    views: p.views, likes: p.likes, action: "Ko'rish"
                                ) { router.push(.part(p)) }) {
                                    router.push(.addListing(part: true, motorbike: nil, sparePart: p))
                                }
                            }
                        } else {
                            ForEach(bikes?.items ?? []) { b in
                                card(id: b.id, ListingCard(
                                    image: b.imagePaths.first, title: b.title, kicker: "\(b.brand) · \(b.year)",
                                    price: Formatting.price(b.price, currency: b.currency), location: Formatting.label(b.location),
                                    address: b.address, badge: b.type, rating: Formatting.siteRating(b.rank),
                                    chips: [CardChip(icon: "speedometer", text: "\(b.mileage) milya"),
                                            CardChip(icon: "scooter", text: Formatting.label(b.condition)),
                                            CardChip(icon: "gearshape.fill", text: "\(b.engineCc) cc")],
                                    views: b.views, likes: b.likes, action: "Ko'rish"
                                ) { router.push(.motorbike(b)) }) {
                                    router.push(.addListing(part: false, motorbike: b, sparePart: nil))
                                }
                            }
                        }
                        Pager(page: page, total: total, perPage: 5) { p in
                            page = p
                            Task { await load() }
                        }
                    }
                }
            }
            .padding(.top, 16)
        }
        .task { await load() }
        // Back from the add / edit form.
        .onAppear { if loaded { Task { await load() } } }
        .alert("E'lonni o'chirish".tr, isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } })) {
            Button("Bekor qilish".tr, role: .cancel) {}
            Button("O'chirish".tr, role: .destructive) {
                if let id = deleting { Task { await setStatus(id, "DELETE") } }
            }
        } message: {
            Text("Bu e'lon butunlay o'chiriladi.".tr)
        }
    }

    private func load() async {
        do {
            if part {
                parts = try await app.myPage.myParts(status: status, page: page)
            } else {
                bikes = try await app.myPage.myListings(status: status, page: page)
            }
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func setStatus(_ id: String, _ newStatus: String) async {
        do {
            try await app.myPage.setListingStatus(id: id, status: newStatus, part: part)
            await load()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func card(id: String, _ card: ListingCard, onEdit: @escaping () -> Void) -> some View {
        VStack(spacing: 10) {
            card
            HStack(spacing: 8) {
                if status != "HOLD" { action("Tahrirlash", "pencil", violet, onEdit) }
                if status == "ACTIVE" { action("Arxivlash", "archivebox", Brand.ink) { Task { await setStatus(id, "SOLD") } } }
                if status == "SOLD" { action("Qayta joylash", "arrow.up.bin", Brand.green) { Task { await setStatus(id, "ACTIVE") } } }
                action("O'chirish", "trash", .red) { deleting = id }
            }
        }
    }

    private func action(_ text: String, _ icon: String, _ color: Color, _ tap: @escaping () -> Void) -> some View {
        Button(action: tap) {
            Label(text.tr, systemImage: icon)
                .font(.poppins(13, .semibold))
                .lineLimit(1)
                .foregroundStyle(color)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(color.opacity(0.5)))
        }
        .buttonStyle(.plain)
    }
}
