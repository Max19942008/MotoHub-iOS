import SwiftUI

/// Home hero: video with "All Bikes. One Place."
struct HomeHero: View {
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            BackgroundVideo(urls: AppConfig.heroVideos, dim: 0.42, grayscale: true)
            VStack(alignment: .leading, spacing: 10) {
                Text("All Bikes. One Place.".tr)
                    .font(.poppins(32, .heavy))
                    .foregroundStyle(.white)
                Text("Looping hero videos keep the spotlight on fresh listings while you search.".tr)
                    .font(.poppins(15))
                    .lineSpacing(4)
                    .foregroundStyle(Color(argb: 0xD9FFFFFF))
            }
            .padding(EdgeInsets(top: 0, leading: 24, bottom: 36, trailing: 24))
        }
        .frame(height: min(max(UIScreen.main.bounds.height * 0.56, 320), 480))
    }
}

/// The desert ride video between the home carousels.
struct AdvertisementVideo: View {
    var body: some View {
        BackgroundVideo(urls: [AppConfig.adVideo], dim: 0).frame(height: 260)
    }
}

/// A home section: gradient title with an underline, an emoji subtitle, content.
struct SiteSection<Content: View>: View {
    let title: String
    let subtitle: String
    let emoji: String
    let gradient: [Color]
    var background = Color.white
    var underline: Color?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(titleCase(title.tr))
                .font(.poppins(28, .heavy))
                .kerning(-0.6)
                .gradientText(gradient)
            RoundedRectangle(cornerRadius: 2)
                .fill(underline ?? gradient[0])
                .frame(width: 50, height: 3)
                .padding(.top, 6)
                .padding(.bottom, 12)
            Text(verbatim: "\(emoji)  \(subtitle.tr)")
                .font(.poppins(14.5, .medium))
                .foregroundStyle(Brand.muted)
            content().padding(.top, 26)
        }
        .padding(EdgeInsets(top: 40, leading: 10, bottom: 40, trailing: 10))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background)
    }
}

/// One-card-at-a-time slider with the site's "← • • • →" bar underneath.
/// The slider is as tall as its tallest card, so short cards leave no gap.
struct SiteCarousel<Item: Identifiable, Card: View>: View {
    let items: [Item]
    let color: Color
    /// The agents slider uses ‹ › instead of arrows.
    var chevrons = false
    @ViewBuilder let card: (Item) -> Card

    @State private var current: Item.ID? = nil

    private var index: Int {
        items.firstIndex { $0.id == current } ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 0) {
                    ForEach(items) { item in
                        card(item)
                            .padding(.horizontal, 2)
                            .containerRelativeFrame(.horizontal)
                            .id(item.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.paging)
            .scrollPosition(id: $current)

            HStack(spacing: 14) {
                arrow(left: true)
                HStack(spacing: 9) {
                    ForEach(Array(items.indices), id: \.self) { i in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(i == index ? color : color.opacity(0.3))
                            .frame(width: i == index ? 24 : 8, height: 8)
                    }
                    Spacer(minLength: 0)
                }
                .animation(.easeOut(duration: 0.2), value: index)
                arrow(left: false)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(color.opacity(0.07), in: RoundedRectangle(cornerRadius: 30))
            .padding(.top, 28)
        }
    }

    private func arrow(left: Bool) -> some View {
        Button {
            let target = min(max(index + (left ? -1 : 1), 0), items.count - 1)
            withAnimation(.easeOut(duration: 0.35)) { current = items[target].id }
        } label: {
            Image(systemName: chevrons ? (left ? "chevron.left" : "chevron.right") : (left ? "arrow.left" : "arrow.right"))
                .font(.system(size: chevrons ? 20 : 17, weight: .bold))
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(.white, in: Circle())
                .shadow(color: color.opacity(0.18), radius: 5)
        }
        .buttonStyle(.plain)
    }
}

/// "Elite riders" card: round photo with a ★ rank badge, name, AGENT pill, phone.
struct AgentCard: View {
    let agent: Agent
    @Environment(Router.self) private var router

    var body: some View {
        Button { router.push(.agent(agent.id)) } label: {
            VStack(spacing: 0) {
                CoverImage(path: agent.imagePath)
                    .clipShape(Circle())
                    .padding(3)
                    .background(Color(argb: 0xFFE0E0FB), in: Circle())
                    .frame(width: 176, height: 176)
                    .overlay(alignment: .topTrailing) {
                        HStack(spacing: 3) {
                            Image(systemName: "star.fill").font(.system(size: 13))
                            Text(String(format: "%.1f", agent.rank)).font(.poppins(13, .heavy))
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Brand.gradient([Brand.indigo, Brand.indigoDark]), in: Capsule())
                        .shadow(color: Brand.indigo.opacity(0.35), radius: 5)
                        .offset(x: 4, y: -6)
                    }
                Text(agent.nick)
                    .font(.poppins(21, .heavy))
                    .foregroundStyle(Brand.ink)
                    .padding(.top, 22)
                Text("AGENT".tr)
                    .font(.poppins(12.5, .bold))
                    .kerning(0.8)
                    .foregroundStyle(Brand.muted)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 5)
                    .background(Color(argb: 0xFFF1F1FD), in: Capsule())
                    .overlay(Capsule().strokeBorder(Color(argb: 0xFFDADAF8)))
                    .padding(.top, 10)
                if let phone = agent.phone, !phone.isEmpty {
                    PhoneLink(phone: phone) {
                        HStack(spacing: 8) {
                            Image(systemName: "phone.fill").font(.system(size: 15)).foregroundStyle(Brand.indigo)
                            Text(phone).font(.poppins(14, .bold)).foregroundStyle(Brand.ink)
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 9)
                        .background(Color(argb: 0xFFF7F7FE), in: RoundedRectangle(cornerRadius: 16))
                        .roundedBorder(Color(argb: 0xFFDADAF8), radius: 16)
                    }
                    .padding(.top, 14)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 420)
            .padding(.horizontal, 20)
            .background(.white, in: RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.04), radius: 8, y: 6)
        }
        .buttonStyle(.plain)
    }
}

/// Opens the dialer for `phone`.
struct PhoneLink<Label: View>: View {
    let phone: String
    @ViewBuilder let label: () -> Label

    var body: some View {
        if let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
            Link(destination: url, label: label)
        } else {
            label()
        }
    }
}

/// The website footer (dark).
struct SiteFooter: View {
    @State private var email = ""
    @FocusState private var emailFocused: Bool

    private let muted = Color(argb: 0xFF9CA3AF)

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            BrandLogo(height: 48).padding(4).background(.black)
            Text("Mukammal mototsiklni topishda ishonchli hamkoringiz. Mototsikl xizmatlari va hamjamiyatida mukammallikni his eting.".tr)
                .font(.poppins(14))
                .lineSpacing(6)
                .foregroundStyle(muted)
                .padding(.top, 22)
            VStack(alignment: .leading, spacing: 26) {
                contact("phone.fill", "BUTUNLAY BEPUL MIJOZLARGA XIZMAT", "+82 10 4867 2909")
                contact("envelope.fill", "JONLI YORDAM KERAKMI?", "support@motohub.com")
            }
            .padding(.top, 34)
            Text("Bizni Ijtimoiy Tarmoqlarda Kuzating".tr)
                .font(.poppins(15.5, .semibold))
                .foregroundStyle(.white)
                .padding(.top, 34)
            HStack(spacing: 12) {
                ForEach(["f.cursive", "paperplane.fill", "camera", "play.rectangle.fill"], id: \.self) { icon in
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundStyle(muted)
                        .frame(width: 46, height: 46)
                        .background(.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 12))
                        .roundedBorder(.white.opacity(0.08), radius: 12)
                }
            }
            .padding(.top, 18)
            newsletter.padding(.top, 44)
            column("Ommabop Qidiruv", ["Sport mototsikllar", "Kruizer mototsikllar", "Yangi kelganlar", "Eng yaxshi takliflar"])
            column("Tezkor Havolalar", ["Foydalanish shartlari", "Maxfiylik siyosati", "Narx rejalari", "Bizning xizmatlar",
                                        "Qo'llab-quvvatlashga murojaat", "Ko'p so'raladigan savollar"])
            column("Turkumlar", ["Sport mototsikllar", "Kruizerlar", "Turing", "Sarguzasht"])
            Rule(color: .white.opacity(0.08)).padding(.top, 30)
            Text("© MOTOPRESTO - Barcha huquqlar himoyalangan.".tr)
                .font(.poppins(13))
                .foregroundStyle(Brand.muted)
                .frame(maxWidth: .infinity)
                .padding(.top, 22)
                .padding(.bottom, 80)
        }
        .padding(EdgeInsets(top: 60, leading: 20, bottom: 30, trailing: 20))
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Brand.ink, Color(argb: 0xFF0F1114)], startPoint: .top, endPoint: .bottom))
    }

    private func contact(_ icon: String, _ label: String, _ value: String) -> some View {
        HStack(alignment: .top, spacing: 22) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(Color(argb: 0xFFFF7A18))
                .padding(.leading, 12)
                .padding(.top, 8)
            VStack(alignment: .leading, spacing: 4) {
                Text(label.tr).font(.poppins(11, .medium)).kerning(1.2).foregroundStyle(muted)
                Text(value).font(.poppins(16, .bold)).foregroundStyle(.white)
            }
        }
    }

    private var newsletter: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Yangiliklardan xabardor bo'ling".tr)
                .font(.poppins(18, .bold))
                .foregroundStyle(.white)
            Text("Eng so'nggi mototsikl yangiliklari va takliflari uchun obuna bo'ling".tr)
                .font(.poppins(14))
                .lineSpacing(4)
                .foregroundStyle(muted)
                .padding(.top, 8)
            TextField("", text: $email, prompt: Text("Email manzilingizni kiriting".tr).foregroundStyle(Brand.muted))
                .font(.poppins(15))
                .foregroundStyle(.white)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .focused($emailFocused)
                .padding(.horizontal, 14)
                .frame(height: 50)
                .background(.white.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
                .roundedBorder(.white.opacity(0.15), radius: 12)
                .padding(.top, 14)
            Button { emailFocused = false } label: {
                Text("Obuna bo'lish".tr)
                    .font(.poppins(15, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 46)
                    .background(Brand.greenGradient, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            .padding(.top, 10)
        }
        .padding(20)
        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(.white.opacity(0.08), radius: 16)
    }

    private func column(_ title: String, _ links: [String]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title.tr).font(.poppins(16, .bold)).foregroundStyle(.white).padding(.bottom, 4)
            ForEach(links, id: \.self) { link in
                if link == "Maxfiylik siyosati" {
                    Link(destination: AppConfig.privacyPolicyURL) { linkText(link) }
                } else {
                    linkText(link)
                }
            }
        }
        .padding(.top, 36)
    }

    private func linkText(_ text: String) -> some View {
        Text(text.tr).font(.poppins(14)).foregroundStyle(muted)
    }
}
