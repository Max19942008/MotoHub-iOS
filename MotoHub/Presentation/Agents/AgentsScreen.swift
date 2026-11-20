import SwiftUI

/// The site's six agent card themes (top bar / ring / AGENT pill).
let agentThemes: [[Color]] = [
    [Color(argb: 0xFF667EEA), Color(argb: 0xFF764BA2)],
    [Color(argb: 0xFFF093FB), Color(argb: 0xFFF5576C)],
    [Color(argb: 0xFF4FACFE), Color(argb: 0xFF00F2FE)],
    [Color(argb: 0xFFFA709A), Color(argb: 0xFFFEE140)],
    [Color(argb: 0xFF30CFD0), Color(argb: 0xFF330867)],
    [Color(argb: 0xFFA8EDEA), Color(argb: 0xFFFED6E3)],
]

enum AgentSort: String, CaseIterable, Identifiable, Sendable {
    case recent, oldest, liked, viewed

    var id: String { rawValue }

    var label: String {
        switch self {
        case .recent: "So'nggi"
        case .oldest: "Eng eski"
        case .liked: "Eng ko'p yoqtirilgan"
        case .viewed: "Eng ko'p ko'rilgan"
        }
    }

    var field: String {
        switch self {
        case .recent, .oldest: "createdAt"
        case .liked: "memberLikes"
        case .viewed: "memberViews"
        }
    }

    var direction: String { self == .oldest ? "ASC" : "DESC" }
}

struct AgentQuery: Equatable, Sendable {
    var sort = AgentSort.recent
    var text = ""
}

/// The website's agents page.
struct AgentsScreen: View {
    @State private var model: PagedListViewModel<Agent, AgentQuery>
    @State private var search = ""

    init(repository: any AgentRepository) {
        _model = State(initialValue: PagedListViewModel(query: AgentQuery()) { q, page in
            try await repository.agents(page: page, sort: q.sort.field, direction: q.sort.direction, text: q.text)
        })
    }

    var body: some View {
        SiteList(model: model, emptyMessage: "Agentlar topilmadi") {
            header.padding(.horizontal, 10)
        } row: { agent in
            AgentListCard(agent: agent)
        }
        .background(Color(argb: 0xFFF8F9FA))
        .task(id: search) {
            // Search as you type, half a second after the last key.
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled, search != model.query.text else { return }
            var q = model.query
            q.text = search
            await model.update(q)
        }
    }

    private var header: some View {
        VStack(spacing: 0) {
            Text("O'zingizga mos agentni toping".tr)
                .font(.poppins(26, .heavy))
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.ink)
                .padding(.top, 28)
            Text("Ishonchli agentlar bilan bog'laning va keyingi mototsiklingiz bo'yicha ekspert maslahatini oling".tr)
                .font(.poppins(14))
                .lineSpacing(6)
                .multilineTextAlignment(.center)
                .foregroundStyle(Brand.muted)
                .padding(.horizontal, 12)
                .padding(.top, 12)
            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "magnifyingglass").foregroundStyle(Brand.green)
                    TextField("", text: $search,
                              prompt: Text("Agentlarni ism, manzil bo'yicha qidiring...".tr).foregroundStyle(Color(argb: 0xFF9CA3AF)))
                        .font(.poppins(13.5))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
                .padding(.horizontal, 14)
                .frame(height: 48)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .roundedBorder(Brand.line, radius: 12)
                Menu {
                    ForEach(AgentSort.allCases) { s in
                        Button {
                            guard s != model.query.sort else { return }
                            var q = model.query
                            q.sort = s
                            Task { await model.update(q) }
                        } label: {
                            if s == model.query.sort { Label(s.label.tr, systemImage: "checkmark") } else { Text(s.label.tr) }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "line.3.horizontal.decrease").foregroundStyle(Brand.green)
                        Text("Saralash".tr).font(.poppins(13.5)).foregroundStyle(Color(argb: 0xFF374151))
                            .frame(maxWidth: .infinity)
                        Text(model.query.sort.label.tr).font(.poppins(13.5, .bold)).foregroundStyle(Brand.ink)
                        Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(Brand.muted)
                    }
                    .padding(.horizontal, 14)
                    .frame(height: 46)
                    .roundedBorder(Brand.line, radius: 12)
                    .contentShape(Rectangle())
                }
                .menuOrder(.fixed)
            }
            .padding(14)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .roundedBorder(Color(argb: 0xFFEAEAEA), radius: 16)
            .shadow(color: .black.opacity(0.04), radius: 8)
            .padding(.top, 32)
            .padding(.bottom, 28)
        }
    }
}

/// One agent card of the agents page.
struct AgentListCard: View {
    let agent: Agent
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var liked: Bool
    @State private var likes: Int

    init(agent: Agent) {
        self.agent = agent
        _liked = State(initialValue: agent.liked)
        _likes = State(initialValue: agent.likes)
    }

    var body: some View {
        let theme = agentThemes[agent.variant]
        let rating = agent.rank > 0 ? String(format: "%.1f", agent.rank) : "4.5"
        Button { router.push(.agent(agent.id)) } label: {
            VStack(spacing: 0) {
                Brand.gradient(theme).frame(height: 5)
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        avatar
                            .padding(3)
                            .background(.white, in: Circle())
                            .padding(4)
                            .background(Brand.gradient(theme), in: Circle())
                            .shadow(color: theme[1].opacity(0.35), radius: 8)
                            .frame(width: 100, height: 100)
                            .frame(maxWidth: .infinity)
                        Button { Task { await like() } } label: {
                            Image(systemName: liked ? "heart.fill" : "heart")
                                .font(.system(size: 18))
                                .foregroundStyle(liked ? Color(argb: 0xFFF5576C) : Color(argb: 0xFF667EEA))
                                .frame(width: 40, height: 40)
                                .background(.white, in: Circle())
                                .shadow(color: .black.opacity(0.1), radius: 5)
                        }
                        .buttonStyle(.plain)
                    }
                    Text(agent.nick)
                        .font(.poppins(18, .heavy))
                        .gradientText([Color(argb: 0xFF667EEA), Color(argb: 0xFF764BA2)])
                        .padding(.top, 14)
                    Text("AGENT".tr)
                        .font(.poppins(11, .heavy))
                        .kerning(1)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 5)
                        .background(Brand.gradient(theme), in: Capsule())
                        .shadow(color: theme[1].opacity(0.35), radius: 4, y: 3)
                        .padding(.top, 8)
                    VStack(spacing: 14) {
                        contact("mappin.and.ellipse", Color(argb: 0xFF667EEA), Color(argb: 0xFFE8EBFB),
                                (agent.address ?? "").isEmpty ? "N/A" : agent.address!)
                        if let phone = agent.phone {
                            PhoneLink(phone: phone) { contact("phone.fill", Color(argb: 0xFFF5576C), Color(argb: 0xFFFDE8EB), phone) }
                        } else {
                            contact("phone.fill", Color(argb: 0xFFF5576C), Color(argb: 0xFFFDE8EB), "N/A")
                        }
                    }
                    .padding(18)
                    .background(LinearGradient(colors: [Color(argb: 0xFFF8F9FF), Color(argb: 0xFFF3F4F6)], startPoint: .leading, endPoint: .trailing),
                                in: RoundedRectangle(cornerRadius: 16))
                    .roundedBorder(Brand.line, radius: 16)
                    .padding(.top, 18)
                    VStack(spacing: 10) {
                        HStack(spacing: 10) {
                            stat("scooter", Brand.siteGreen, "\(agent.properties)", "MOTOTSIKLLAR")
                            stat("eye.fill", Color(argb: 0xFF3B82F6), "\(agent.views)", "KO'RISHLAR")
                        }
                        HStack(spacing: 10) {
                            stat("heart.fill", Color(argb: 0xFFF5576C), "\(likes)", "YOQTIRISHLAR")
                            stat("star.fill", Color(argb: 0xFFF59E0B), rating, "REYTING")
                        }
                    }
                    .padding(.top, 18)
                }
                .padding(EdgeInsets(top: 18, leading: 20, bottom: 22, trailing: 20))
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.12), radius: 3, y: 2)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var avatar: some View {
        if let image = agent.imagePath {
            CoverImage(path: image).clipShape(Circle())
        } else {
            ZStack {
                Color(argb: 0xFFE5E7EB)
                Image(systemName: "person.fill").font(.system(size: 46)).foregroundStyle(.white)
            }
            .clipShape(Circle())
        }
    }

    private func contact(_ icon: String, _ color: Color, _ bg: Color, _ text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundStyle(color)
                .frame(width: 34, height: 34)
                .background(bg, in: RoundedRectangle(cornerRadius: 8))
            Text(text.tr).font(.poppins(14, .semibold)).foregroundStyle(color).lineLimit(1)
            Spacer(minLength: 0)
        }
    }

    private func stat(_ icon: String, _ color: Color, _ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: icon).font(.system(size: 16)).foregroundStyle(color)
            Text(value).font(.poppins(17, .heavy)).foregroundStyle(color).padding(.top, 2)
            Text(label.tr).font(.poppins(10, .bold)).kerning(0.4).foregroundStyle(Brand.muted).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white, in: RoundedRectangle(cornerRadius: 12))
        .roundedBorder(Brand.line, radius: 12, width: 1.5)
    }

    private func like() async {
        guard session.isLoggedIn else {
            router.toast("Avval tizimga kiring".tr)
            return
        }
        liked.toggle()
        likes += liked ? 1 : -1
        do {
            try await app.agents.likeMember(id: agent.id)
        } catch {
            liked.toggle()
            likes += liked ? 1 : -1
            router.toast(error.localizedDescription.tr)
        }
    }
}
