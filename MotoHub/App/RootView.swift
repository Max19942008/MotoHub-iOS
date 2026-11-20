import SwiftUI

/// Website layout: dark navbar (logo · Kirish · ☰), drawer menu, floating
/// "AI Assistant" button bottom-left and the live chat bottom-right.
struct RootView: View {
    @Environment(AppContainer.self) private var app
    @Bindable var router: Router

    var body: some View {
        NavigationStack(path: $router.path) {
            ShellView()
                .navigationDestination(for: Route.self) { RouteView(route: $0) }
        }
        .overlay(alignment: .bottom) { ToastView(text: router.toastText) }
        .environment(router)
        .tint(Brand.green)
    }
}

/// The screen for a pushed route.
private struct RouteView: View {
    let route: Route

    var body: some View {
        switch route {
        case .motorbike(let bike): MotorbikeDetailScreen(id: bike.id, initial: bike)
        case .part(let part): PartDetailScreen(id: part.id, initial: part)
        case .motorbikeID(let id): MotorbikeDetailScreen(id: id)
        case .partID(let id): PartDetailScreen(id: id)
        case .agent(let id): AgentDetailScreen(agentID: id)
        case .article(let id): ArticleDetailScreen(articleID: id)
        case .writeArticle(let category): WriteArticleScreen(category: category)
        case .notifications: NotificationsScreen()
        case .addListing(let part, let bike, let sparePart): AddListingScreen(isPart: part, bike: bike, part: sparePart)
        }
    }
}

private struct ShellView: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack {
            // Every page keeps its state once opened, like the Android app's IndexedStack.
            ForEach(AppPage.allCases.filter { router.visited.contains($0) }, id: \.self) { page in
                pageView(page)
                    .opacity(page == router.page ? 1 : 0)
                    .allowsHitTesting(page == router.page)
                    .accessibilityHidden(page != router.page)
            }
            if router.page != .assistant {
                LiveChat()
                AIPill { router.go(.assistant) }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 16)
                    .padding(.bottom, 16)
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) { navBar }
        .overlay { MenuDrawer() }
        .toolbar(.hidden, for: .navigationBar)
    }

    @ViewBuilder
    private func pageView(_ page: AppPage) -> some View {
        switch page {
        case .home: HomeScreen()
        case .bikes: MotorbikesScreen(repository: app.listings)
        case .parts: PartsScreen(repository: app.listings, category: router.partsCategory)
        case .agents: AgentsScreen(repository: app.agents)
        case .community: CommunityScreen()
        case .help: HelpScreen()
        case .assistant: AssistantView(repository: app.assistant)
        case .profile: ProfileScreen()
        }
    }

    private var navBar: some View {
        HStack(spacing: 4) {
            Button { router.go(.home) } label: { BrandLogo() }
                .buttonStyle(.plain)
            Spacer()
            if let member = session.member {
                BellButton()
                Button { router.go(.profile) } label: {
                    Avatar(path: member.imagePath, size: 32)
                        .padding(2)
                        .overlay(Circle().strokeBorder(.white.opacity(0.3), lineWidth: 2))
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Profil".tr)
            } else {
                Button { router.go(.profile) } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "person.crop.circle").font(.system(size: 18))
                        Text("Kirish".tr).font(.poppins(14, .bold))
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .frame(height: 38)
                    .background(.white.opacity(0.08), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.3), lineWidth: 1.5))
                }
                .buttonStyle(.plain)
            }
            Button {
                withAnimation(.easeOut(duration: 0.25)) { router.drawerOpen = true }
            } label: {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Menyu".tr)
            .accessibilityIdentifier("menyu-ochiq")
        }
        .padding(.leading, 16)
        .padding(.trailing, 4)
        .frame(height: 60)
        .background(Brand.ink.ignoresSafeArea(edges: .top))
    }
}

/// Bell with the unread count, like the site's header; opens notifications.
private struct BellButton: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var unread = 0

    var body: some View {
        Button { router.push(.notifications) } label: {
            Image(systemName: "bell")
                .font(.system(size: 21))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .overlay(alignment: .topTrailing) {
                    if unread > 0 {
                        Text(verbatim: "\(unread)")
                            .font(.poppins(10, .semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 5)
                            .frame(minWidth: 16, minHeight: 16)
                            .background(Color(argb: 0xFFBA1A1A), in: Capsule())
                            .offset(x: -4, y: 6)
                    }
                }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Bildirishnomalar".tr)
        // Refreshed whenever the shell shows again (back from notifications).
        .onAppear { Task { await refresh() } }
    }

    private func refresh() async {
        if let result = try? await app.notifications.notifications() { unread = result.unread }
    }
}

/// The website's floating "AI Assistant" pill (48px high).
private struct AIPill: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles").font(.system(size: 19))
                Text("AI Assistant".tr).font(.poppins(14.5, .bold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 16)
            .frame(height: 48)
            .background(Brand.ai, in: Capsule())
            .shadow(color: Brand.ai.opacity(0.35), radius: 12, y: 8)
        }
        .buttonStyle(.plain)
    }
}

/// The right-hand menu, same items and order as the website's drawer.
private struct MenuDrawer: View {
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session

    var body: some View {
        ZStack(alignment: .trailing) {
            if router.drawerOpen {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture { close() }
                    .transition(.opacity)
                drawer
                    .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeOut(duration: 0.25), value: router.drawerOpen)
    }

    private func close() {
        withAnimation(.easeOut(duration: 0.2)) { router.drawerOpen = false }
    }

    private var drawer: some View {
        let page = router.page
        let parts = router.partsCategory
        return VStack(alignment: .leading, spacing: 0) {
            HStack {
                BrandLogo(height: 36)
                Spacer()
                Button(action: close) {
                    Image(systemName: "xmark").font(.system(size: 20)).foregroundStyle(.white).frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 16)
            .padding(.trailing, 4)
            .frame(height: 60)
            .overlay(alignment: .bottom) { Color.white.opacity(0.08).frame(height: 1) }
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    item("Bosh sahifa", page == .home) { router.go(.home) }
                    item("Mototsikllar", page == .bikes) { router.go(.bikes) }
                    item("Ehtiyot qismlar", page == .parts && parts == "SPARE_PART") { router.go(.parts, category: "SPARE_PART") }
                    item("Aksessuarlar", page == .parts && parts == "ACCESSORY") { router.go(.parts, category: "ACCESSORY") }
                    item("Agentlar", page == .agents) { router.go(.agents) }
                    item("Hamjamiyat", page == .community) { router.go(.community) }
                    item("Yordam", page == .help) { router.go(.help) }
                    item("AI yordamchi", page == .assistant) { router.go(.assistant) }
                    item(session.isLoggedIn ? "Mening sahifam" : "Kirish / Ro'yxatdan o'tish", page == .profile) { router.go(.profile) }
                    item("Maxfiylik siyosati", false) {
                        UIApplication.shared.open(AppConfig.privacyPolicyURL)
                    }
                }
                .padding(.top, 8)
            }
            LanguageRow()
            if session.isLoggedIn {
                Button {
                    close()
                    Task { await session.logout() }
                } label: {
                    Label("Chiqish".tr, systemImage: "rectangle.portrait.and.arrow.right")
                        .font(.poppins(15, .bold))
                        .foregroundStyle(Color(argb: 0xFFFF6B6B))
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.white.opacity(0.15)))
                }
                .buttonStyle(.plain)
                .padding(EdgeInsets(top: 8, leading: 16, bottom: 20, trailing: 16))
            }
        }
        .frame(width: 300)
        .frame(maxHeight: .infinity)
        .background(Brand.ink.ignoresSafeArea())
    }

    private func item(_ label: String, _ active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.tr)
                .font(.poppins(16, .semibold))
                .foregroundStyle(active ? .white : .white.opacity(0.85))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.vertical, 15)
                .background(active ? Brand.green.opacity(0.12) : .clear)
                .overlay(alignment: .leading) { (active ? Brand.green : .clear).frame(width: 3) }
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

/// UZ / RU / EN / KR flags at the bottom of the menu, like the site's drawer.
private struct LanguageRow: View {
    var body: some View {
        let current = I18n.shared.lang
        HStack(spacing: 8) {
            ForEach(AppLang.allCases) { l in
                Button { I18n.shared.set(l) } label: {
                    VStack(spacing: 4) {
                        Image(l.flagAsset).resizable().scaledToFit().frame(width: 26)
                        Text(verbatim: l.code)
                            .font(.poppins(11, .semibold))
                            .foregroundStyle(l == current ? .white : .white.opacity(0.8))
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(l == current ? Brand.green.opacity(0.12) : .clear, in: RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(l == current ? Brand.green : .white.opacity(0.15)))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 8, trailing: 16))
        .overlay(alignment: .top) { Color.white.opacity(0.08).frame(height: 1) }
    }
}

/// The site's snackbar: dark, floating at the bottom.
private struct ToastView: View {
    let text: String?

    var body: some View {
        if let text {
            Text(text)
                .font(.poppins(14))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.ink, in: RoundedRectangle(cornerRadius: 4))
                .shadow(color: .black.opacity(0.25), radius: 6, y: 3)
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .allowsHitTesting(false)
        }
    }
}
