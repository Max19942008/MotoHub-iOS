import SwiftUI

/// The website's agent page: profile card, then "Bikes (n)" / "Reviews (n)" tabs.
struct AgentDetailScreen: View {
    let agentID: String

    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var agent: Agent? = nil
    @State private var bikes: PagedResult<Motorbike>? = nil
    @State private var reviews = 0
    @State private var tab = 0
    @State private var page = 1
    @State private var following = false

    var body: some View {
        Group {
            if let agent {
                ScrollView {
                    VStack(spacing: 0) {
                        profile(agent)
                        tabs.padding(.top, 28)
                        Group {
                            if tab == 0 {
                                bikesTab
                            } else {
                                SiteReviews(group: "MEMBER", refID: agentID)
                            }
                        }
                        .padding(.top, 24)
                    }
                    .padding(EdgeInsets(top: 20, leading: 20, bottom: 90, trailing: 20))
                }
                .refreshable { await load() }
            } else {
                LoadingView().frame(maxHeight: .infinity)
            }
        }
        .background(Color(argb: 0xFFF8F9FA))
        .sitePage(back: true)
        .task { if agent == nil { await load() } }
    }

    private func load() async {
        let agents = app.agents
        let listings = app.listings
        let id = agentID
        let current = page
        do {
            async let a = agents.agent(id: id)
            async let b = agents.agentMotorbikes(memberID: id, page: current)
            async let c = listings.comments(refID: id, page: 1)
            let (loaded, list, comments) = try await (a, b, c)
            agent = loaded
            following = loaded.followed
            bikes = list
            reviews = comments.total
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func toPage(_ p: Int) async {
        page = p
        if let list = try? await app.agents.agentMotorbikes(memberID: agentID, page: p) { bikes = list }
    }

    private func toggleFollow() async {
        do {
            if following {
                try await app.agents.unfollow(id: agentID)
            } else {
                try await app.agents.follow(id: agentID)
            }
            following.toggle()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func profile(_ a: Agent) -> some View {
        let canFollow = session.member.map { $0.id != a.id } ?? false
        let ring = Brand.gradient([Brand.siteGreen, Color(argb: 0xFF3B82F6)])
        return VStack(spacing: 0) {
            Brand.gradient([Color(argb: 0xFF667EEA), Color(argb: 0xFF3B82F6), Color(argb: 0xFFEAB308), Brand.siteGreen, Brand.siteGreen])
                .frame(height: 4)
            VStack(spacing: 0) {
                Avatar(path: a.imagePath, size: 92)
                    .padding(4)
                    .background(ring, in: Circle())
                    .overlay(alignment: .bottom) {
                        Text("AGENT".tr)
                            .font(.poppins(11, .heavy))
                            .kerning(1)
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 4)
                            .background(ring, in: RoundedRectangle(cornerRadius: 14))
                            .offset(y: 8)
                    }
                Text((a.fullName ?? "").isEmpty ? a.nick : a.fullName!)
                    .font(.poppins(22, .heavy))
                    .multilineTextAlignment(.center)
                    .gradientText([Color(argb: 0xFF1B3A26), Brand.siteGreen, Color(argb: 0xFF3B82F6)])
                    .padding(.top, 22)
                Text((a.address ?? "").uppercased())
                    .font(.poppins(13.5))
                    .kerning(0.5)
                    .foregroundStyle(Brand.muted)
                    .padding(.top, 6)
                FlowLayout(spacing: 10) {
                    PhoneLink(phone: a.phone ?? "") {
                        Label("Call".tr, systemImage: "phone.fill")
                            .font(.poppins(15, .bold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 22)
                            .padding(.vertical, 11)
                            .background(Brand.gradient([Color(argb: 0xFF3B82F6), Color(argb: 0xFF8B5CF6)]), in: RoundedRectangle(cornerRadius: 12))
                            .shadow(color: Brand.indigo.opacity(0.4), radius: 7, y: 6)
                    }
                    if canFollow {
                        Button { Task { await toggleFollow() } } label: {
                            Text((following ? "Following" : "Follow").tr)
                                .font(.poppins(15, .bold))
                                .foregroundStyle(Brand.indigo)
                                .padding(.horizontal, 22)
                                .frame(height: 44)
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.indigo, lineWidth: 1.5))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 18)
                HStack(spacing: 8) {
                    stat("\(a.properties)", "MOTOTSIKLLAR")
                    stat("\(a.likes)", "YOQTIRISHLAR")
                    stat("\(a.views)", "KO'RISHLAR")
                }
                .padding(.top, 20)
            }
            .padding(EdgeInsets(top: 22, leading: 20, bottom: 26, trailing: 20))
        }
        .background(.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack(spacing: 4) {
            Text(value).font(.poppins(20, .heavy)).foregroundStyle(Brand.ink)
            Text(label.tr).font(.poppins(10.5, .semibold)).foregroundStyle(Brand.muted).lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(.white, in: RoundedRectangle(cornerRadius: 14))
        .roundedBorder(Brand.line, radius: 14, width: 2)
    }

    private var tabs: some View {
        HStack(spacing: 0) {
            tabButton(0, "scooter", "Bikes (\(bikes?.total ?? 0))")
            tabButton(1, "star.fill", "Reviews (\(reviews))")
            Spacer()
        }
        .overlay(alignment: .bottom) { Brand.line.frame(height: 1) }
    }

    private func tabButton(_ i: Int, _ icon: String, _ label: String) -> some View {
        let active = tab == i
        return Button { tab = i } label: {
            VStack(spacing: 4) {
                Image(systemName: icon).font(.system(size: 16))
                Text(label.tr).font(.poppins(14.5, .medium))
            }
            .foregroundStyle(active ? Brand.green : Brand.muted)
            .padding(.horizontal, 16)
            .padding(.bottom, 10)
            .overlay(alignment: .bottom) { (active ? Color(argb: 0xFFE53935) : .clear).frame(height: 2.5) }
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var bikesTab: some View {
        let total = bikes?.total ?? 0
        let pages = Int((Double(total) / 9).rounded(.up))
        VStack(spacing: 0) {
            HStack {
                Text("Mototsikllar".tr)
                    .font(.poppins(22, .heavy))
                    .gradientText([Color(argb: 0xFF1B3A26), Brand.siteGreen, Color(argb: 0xFF3B82F6)])
                Spacer()
                Text("\(total) available".tr).font(.poppins(13.5)).foregroundStyle(Brand.muted)
            }
            .padding(.bottom, 20)
            if let bikes, !bikes.items.isEmpty {
                VStack(spacing: 20) {
                    ForEach(bikes.items) { b in
                        SimilarCard(item: SimilarItem(
                            id: b.id, image: b.imagePaths.first, price: Formatting.price(b.price, currency: b.currency),
                            title: b.title, location: b.location,
                            pills: [("gearshape.fill", "\(b.engineCc) CC"), ("speedometer", "\(b.mileage) km"), ("tag.fill", b.brand)],
                            views: b.views, likes: b.likes, rent: b.rent, barter: b.barter, route: .motorbike(b)
                        )) { router.push(.motorbike(b)) }
                    }
                }
                .padding(EdgeInsets(top: 20, leading: 16, bottom: 4, trailing: 16))
                .background(.white, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.05), radius: 12)
            } else {
                Text("Mototsikllar topilmadi!".tr).font(.poppins(14)).foregroundStyle(Brand.muted).padding(30)
            }
            if pages > 1 {
                HStack(spacing: 8) {
                    ForEach(1...pages, id: \.self) { p in
                        Button { Task { await toPage(p) } } label: {
                            Text(verbatim: "\(p)")
                                .font(.poppins(14, .semibold))
                                .foregroundStyle(p == page ? .white : Brand.ink)
                                .frame(width: 36, height: 36)
                                .background(p == page ? Brand.green : .white, in: Circle())
                                .overlay(Circle().strokeBorder(p == page ? Brand.green : Brand.line))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}
