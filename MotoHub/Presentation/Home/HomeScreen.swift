import SwiftUI

/// The website's mobile home page, section for section.
struct HomeScreen: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router

    @State private var trend: [Motorbike]? = nil
    @State private var popular: [Motorbike]? = nil
    @State private var top: [Motorbike]? = nil
    @State private var topParts: [Part]? = nil
    @State private var topAccessories: [Part]? = nil
    @State private var agents: [Agent]? = nil
    @State private var loaded = false

    private static let greenTitle = [Brand.green, Brand.greenDark, Color(argb: 0xFFFF6B6B)]
    private static let indigoTitle = [Brand.indigo, Color(argb: 0xFF8B5CF6)]
    private static let grey = Color(argb: 0xFFF5F5F5)

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HomeHero()
                SiteSection(title: "Eng ko'p qidirilgan mototsikllar", subtitle: "Trend yoqtirishlarga asoslangan",
                            emoji: "🔥", gradient: Self.greenTitle, underline: Brand.green) {
                    carousel(trend, color: Brand.green) { bikeCard($0, accent: .green, action: "Sotib Olish") }
                }
                SiteSection(title: "Ommabop mototsikllar", subtitle: "Shu haftada eng ko'p ko'rilgan mototsikllar",
                            emoji: "🔥  🔥", gradient: Self.indigoTitle, background: Self.grey) {
                    carousel(popular, color: Brand.indigo) { bikeCard($0, accent: .indigo, action: "Band Qilish") }
                }
                AdvertisementVideo()
                SiteSection(title: "Eng zo'r mototsikllar", subtitle: "Shu oyning eng yuqori baholangan mototsikllari",
                            emoji: "🏆  🏆", gradient: Self.indigoTitle) {
                    carousel(top, color: Brand.indigo) { bikeCard($0, accent: .indigo, action: "Band Qilish") }
                }
                SiteSection(title: "Eng zo'r ehtiyot qismlar", subtitle: "Shu oyning eng ommabop ehtiyot qismlari",
                            emoji: "🏆  🏆", gradient: Self.indigoTitle, background: Self.grey) {
                    carousel(topParts, color: Brand.indigo, content: partCard)
                }
                SiteSection(title: "Eng zo'r aksessuarlar", subtitle: "Shu oyning eng ommabop aksessuarlari",
                            emoji: "🏆  🏆", gradient: Self.indigoTitle) {
                    carousel(topAccessories, color: Brand.indigo, content: partCard)
                }
                SiteSection(title: "Elita haydovchilar", subtitle: "Hamjamiyatimiz chempionlari bilan tanishing",
                            emoji: "⭐  ⭐", gradient: Self.indigoTitle, background: Self.grey) {
                    carousel(agents, color: Brand.indigo, chevrons: true) { AgentCard(agent: $0) }
                }
                SiteFooter()
            }
        }
        .background(Color.white)
        .refreshable { await load() }
        .task {
            guard !loaded else { return }
            loaded = true
            await load()
        }
    }

    private func load() async {
        // Each section loads on its own; one failure leaves the others alone.
        let listings = app.listings
        let agentRepo = app.agents
        async let a = try? listings.topMotorbikes(sort: "propertyLikes", limit: 8)
        async let b = try? listings.topMotorbikes(sort: "propertyViews", limit: 7)
        async let c = try? listings.topMotorbikes(sort: "propertyRank", limit: 8)
        async let d = try? listings.topParts(category: "SPARE_PART", limit: 8)
        async let e = try? listings.topParts(category: "ACCESSORY", limit: 8)
        async let f = try? agentRepo.topAgents(limit: 10)
        trend = await a ?? []
        popular = await b ?? []
        top = await c ?? []
        topParts = await d ?? []
        topAccessories = await e ?? []
        agents = await f ?? []
    }

    @ViewBuilder
    private func carousel<Item: Identifiable, Card: View>(
        _ items: [Item]?, color: Color, chevrons: Bool = false, @ViewBuilder content: @escaping (Item) -> Card
    ) -> some View {
        if let items {
            if items.isEmpty {
                Text("Hozircha bo'sh".tr)
                    .font(.poppins(14))
                    .foregroundStyle(Brand.muted)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
            } else {
                SiteCarousel(items: items, color: color, chevrons: chevrons, card: content)
            }
        } else {
            ProgressView()
                .controlSize(.large)
                .tint(color)
                .frame(maxWidth: .infinity)
                .frame(height: 420)
        }
    }

    private func bikeCard(_ b: Motorbike, accent: CardAccent, action: String) -> ListingCard {
        ListingCard(
            image: b.imagePaths.first,
            title: b.title,
            kicker: "\(b.brand) · \(b.year)",
            price: Formatting.price(b.price, currency: b.currency),
            location: b.location,
            address: b.address,
            rating: Formatting.siteRating(b.rank, home: true),
            chips: [
                CardChip(icon: "speedometer", text: "\(b.mileage) milya"),
                CardChip(icon: "scooter", text: b.condition),
                CardChip(icon: "gearshape.fill", text: "\(b.engineCc) cc"),
            ],
            views: b.views,
            likes: b.likes,
            action: action,
            titleLines: 1,
            accent: accent
        ) { router.push(.motorbike(b)) }
    }

    private func partCard(_ p: Part) -> ListingCard {
        ListingCard(
            image: p.imagePaths.first,
            title: p.title,
            kicker: "\(p.brand) · \(p.type)",
            price: Formatting.price(p.price, currency: p.currency),
            location: p.location,
            rating: Formatting.siteRating(p.rank, home: true),
            chips: [
                CardChip(icon: "square.grid.2x2", text: p.type),
                CardChip(icon: "scooter", text: p.condition),
                CardChip(icon: "shippingbox", text: "\(p.stock) dona"),
            ],
            views: p.views,
            likes: p.likes,
            titleLines: 1,
            accent: .indigo
        ) { router.push(.part(p)) }
    }
}
