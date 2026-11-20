import SwiftUI

/// Colored icon tile in the "options" box (Dvigatel, Yurgan masofa, …).
struct Spec: Hashable {
    let icon: String
    let label: String
    let value: String
    let colors: [Color]
}

/// The site's spec tile gradients, in page order.
let specRed = [Color(argb: 0xFFFF6B6B), Color(argb: 0xFFEE5A6F)]
let specBlue = [Color(argb: 0xFF3B82F6), Color(argb: 0xFF2563EB)]
let specAmber = [Color(argb: 0xFFEAB308), Color(argb: 0xFFCA8A04)]
let specGreen = [Color(argb: 0xFF4CAF50), Color(argb: 0xFF43A047)]
let specPurple = [Color(argb: 0xFFA855F7), Color(argb: 0xFF9333EA)]

/// One row of the "… tafsilotlari" box.
struct DetailRow: Hashable {
    let label: String
    let value: String
}

/// Everything the shared detail page shows, built by the bike / part screens.
struct DetailContent {
    let id: String
    /// "Mototsikl" / "Ehtiyot qism" in the breadcrumb.
    let crumb: String
    let title: String
    let typeBadge: String
    let location: String
    let images: [String]
    let price: String
    /// "total" / "per month" under the price.
    let pricePeriod: String
    let views: Int
    let likes: Int
    let liked: Bool
    let interested: Bool
    let seller: Seller?
    let specs: [Spec]
    let descTitle: String
    let description: String?
    let detailsTitle: String
    let details: [DetailRow]
    /// PROPERTY → reviews section shown (parts have none on the site).
    let commentGroup: String?
    let similarTitle: String
    let similarSubtitle: String
}

/// A card of the "O'xshash …" section.
struct SimilarItem: Identifiable {
    let id: String
    let image: String?
    let price: String
    let title: String
    let location: String
    let pills: [(String, String)]
    let views: Int
    let likes: Int
    var rent = false
    var barter = false
    let route: Route
}

/// The website's listing detail page (mobile), shared by bikes and parts.
struct SiteDetailPage: View {
    let content: DetailContent
    let similar: [SimilarItem]?
    let onLike: () async throws -> Void
    let onInterest: () async throws -> Void
    let onRefresh: () async -> Void

    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var image = 0
    @State private var sending = false
    @State private var interestSent = false

    private var c: DetailContent { content }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                breadcrumb
                BackButton().padding(.top, 12)
                photo.padding(.top, 28)
                thumbnails
                priceCard.padding(.top, 18)
                actions.padding(.top, 14)
                if let seller = c.seller {
                    dealerCard(seller).padding(.top, 14)
                }
                RainbowBox(top: [Color(argb: 0xFFFF6B6B), Color(argb: 0xFF3B82F6), Color(argb: 0xFFEAB308),
                                 Color(argb: 0xFF4CAF50), Color(argb: 0xFFA855F7)]) {
                    VStack(spacing: 22) {
                        ForEach(c.specs, id: \.self) { SpecTile(spec: $0) }
                    }
                }
                .padding(.top, 36)
                RainbowBox(top: [Color(argb: 0xFF4CAF50), Color(argb: 0xFF43A047)]) {
                    descriptionBox
                }
                .padding(.top, 28)
                if let group = c.commentGroup {
                    SiteReviews(group: group, refID: c.id).padding(.top, 28)
                }
                RainbowBox(top: [Color(argb: 0xFFEAB308), Color(argb: 0xFF4CAF50), Color(argb: 0xFFA855F7)]) {
                    similarBox
                }
                .padding(.top, 28)
            }
            .padding(EdgeInsets(top: 16, leading: 16, bottom: 90, trailing: 16))
        }
        .background(Color.white)
        .refreshable { await onRefresh() }
        .sitePage()
    }

    // MARK: - Top

    private var breadcrumb: some View {
        FlowLayout(spacing: 8, lineSpacing: 4) {
            Text("Bosh sahifa".tr).foregroundStyle(Brand.muted)
            Text(verbatim: "/").foregroundStyle(Color(argb: 0xFF9CA3AF))
            Text(c.crumb.tr).foregroundStyle(Brand.muted)
            Text(verbatim: "/").foregroundStyle(Color(argb: 0xFF9CA3AF))
            Text(c.title).font(.poppins(13, .medium)).foregroundStyle(Brand.ink)
        }
        .font(.poppins(13))
    }

    private var images: [String] { c.images.isEmpty ? [""] : c.images }

    private var photo: some View {
        Color.clear
            .frame(height: 260)
            .overlay { RemoteImage(path: images[min(image, images.count - 1)]) }
            .overlay(alignment: .top) {
                HStack(alignment: .top, spacing: 8) {
                    whitePill {
                        Text(c.typeBadge.tr.uppercased()).font(.poppins(13, .semibold)).foregroundStyle(Brand.ink)
                    }
                    whitePill {
                        VStack(spacing: 0) {
                            Image(systemName: "mappin").font(.system(size: 14))
                            Text(c.location.tr).font(.poppins(13))
                        }
                        .foregroundStyle(Brand.ink)
                    }
                    Spacer()
                    darkPill("eye", "\(c.views)")
                    Button { Task { await like() } } label: {
                        darkPill(c.liked ? "heart.fill" : "heart", "\(c.likes)",
                                 iconColor: c.liked ? Color(argb: 0xFFE91E63) : .white)
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
            }
            .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    @ViewBuilder
    private var thumbnails: some View {
        if images.count > 1 {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(Array(images.enumerated()), id: \.offset) { i, path in
                        Button { image = i } label: {
                            CoverImage(path: path)
                                .frame(width: 80, height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(2)
                                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(i == image ? Brand.ink : .clear, lineWidth: 2))
                                .shadow(color: i == image ? .black.opacity(0.15) : .clear, radius: 4, y: 2)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 4)
            }
            .padding(.top, 12)
        }
    }

    private func whitePill<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
    }

    private func darkPill(_ icon: String, _ text: String, iconColor: Color = .white) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon).font(.system(size: 14)).foregroundStyle(iconColor)
            Text(text).font(.poppins(13, .semibold)).foregroundStyle(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 20))
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("NARX".tr).font(.poppins(13, .medium)).kerning(0.5).foregroundStyle(Color(argb: 0xFF717171))
            Text(c.price).font(.poppins(34, .heavy)).foregroundStyle(Brand.ink)
            Text(c.pricePeriod.tr).font(.poppins(14)).foregroundStyle(Color(argb: 0xFF717171))
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [Color(argb: 0xFFF8F9FA), .white], startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(Color(argb: 0xFFE0E0E0), radius: 16)
    }

    private var interested: Bool { c.interested || interestSent }

    private var actions: some View {
        VStack(spacing: 12) {
            ActionButton(icon: "phone.fill", label: "Call Dealer", filled: true) { call() }
            ActionButton(
                icon: interested ? "checkmark.circle.fill" : "hand.raised.fill",
                label: interested ? "Sotuvchi xabardor qilindi" : (sending ? "Yuborilmoqda…" : "Qiziqaman"),
                done: interested
            ) { Task { await interest() } }
            ActionButton(icon: c.liked ? "heart.fill" : "heart", label: c.liked ? "Liked" : "Like",
                         iconColor: c.liked ? Color(argb: 0xFFE91E63) : nil) { Task { await like() } }
        }
    }

    private func dealerCard(_ s: Seller) -> some View {
        VStack(spacing: 0) {
            Avatar(path: s.imagePath, size: 80)
            Text(s.nick.isEmpty ? "Dealer".tr : s.nick)
                .font(.poppins(16, .semibold))
                .foregroundStyle(Brand.ink)
                .padding(.top, 14)
            Text(c.location.tr).font(.poppins(14)).foregroundStyle(Color(argb: 0xFF717171)).padding(.top, 4)
            Button { call() } label: {
                Label("Call".tr, systemImage: "phone.fill")
                    .font(.poppins(15, .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 42)
                    .background(Brand.siteGreen, in: RoundedRectangle(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .padding(.top, 16)
            Button { router.push(.agent(s.id)) } label: {
                Text("View Dealer".tr)
                    .font(.poppins(14, .semibold))
                    .foregroundStyle(Brand.siteGreen)
                    .frame(maxWidth: .infinity)
                    .frame(height: 40)
                    .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Brand.siteGreen, lineWidth: 2))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .padding(20)
        .background(.white, in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(Color(argb: 0xFFE0E0E0), radius: 16)
    }

    // MARK: - Description, related

    private var descriptionBox: some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionTitle(text: c.descTitle)
            let text = Formatting.plainText(c.description)
            Text(text.isEmpty ? "No Description!".tr : text)
                .font(.poppins(15))
                .lineSpacing(6)
                .foregroundStyle(Color(argb: 0xFF4B5563))
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(LinearGradient(colors: [Color(argb: 0xFFF8F9FA), .white], startPoint: .leading, endPoint: .trailing))
                .overlay(alignment: .leading) { Brand.siteGreen.frame(width: 4) }
                .clipShape(RoundedRectangle(cornerRadius: 12))
            LinearGradient(colors: [Brand.siteGreen, Color(argb: 0xFFE0E0E0), .clear], startPoint: .leading, endPoint: .trailing)
                .frame(height: 2)
                .padding(.vertical, 28)
            SectionTitle(text: c.detailsTitle)
            VStack(spacing: 20) {
                ForEach(c.details, id: \.self) { DetailRowView(row: $0) }
            }
        }
    }

    private var similarBox: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(c.similarTitle.tr)
                .font(.poppins(30, .heavy))
                .gradientText([Color(argb: 0xFF1B3A26), Color(argb: 0xFF4CAF50), Color(argb: 0xFF3B82F6)])
            Capsule()
                .fill(Brand.gradient([Color(argb: 0xFF4CAF50), Color(argb: 0xFF3B82F6)]))
                .frame(width: 80, height: 4)
                .padding(.top, 8)
                .padding(.bottom, 12)
            Text(c.similarSubtitle.tr)
                .font(.poppins(15))
                .lineSpacing(6)
                .foregroundStyle(Brand.muted)
            Group {
                if let similar {
                    VStack(spacing: 18) {
                        ForEach(similar) { item in
                            SimilarCard(item: item) { router.replace(item.route) }
                        }
                    }
                } else {
                    ProgressView().tint(Brand.green).frame(maxWidth: .infinity).padding(24)
                }
            }
            .padding(.top, 32)
        }
    }

    // MARK: - Actions

    private func requireLogin() -> Bool {
        if session.isLoggedIn { return true }
        router.toast("Avval tizimga kiring".tr)
        return false
    }

    private func like() async {
        guard requireLogin() else { return }
        do {
            try await onLike()
            await onRefresh()
            router.toast("success".tr)
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func interest() async {
        guard !interested, !sending, requireLogin() else { return }
        sending = true
        defer { sending = false }
        do {
            try await onInterest()
            interestSent = true
            router.toast("Sotuvchi qiziqishingizdan xabardor qilindi!".tr)
            await onRefresh()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    private func call() {
        guard let phone = c.seller?.phone, !phone.isEmpty else { return }
        if let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
            UIApplication.shared.open(url) { ok in
                if !ok { Task { @MainActor in router.toast("Telefon: \(phone)") } }
            }
        }
    }
}

private struct ActionButton: View {
    let icon: String
    let label: String
    var filled = false
    var done = false
    var iconColor: Color?
    let action: () -> Void

    var body: some View {
        let green = Brand.siteGreen
        let solid = filled || done
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: icon).font(.system(size: 19)).foregroundStyle(iconColor ?? (solid ? .white : green))
                Text(label.tr).font(.poppins(15.5, .bold)).foregroundStyle(solid ? .white : green).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .frame(height: filled ? 54 : 50)
            .background(solid ? green : .white, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(filled ? .clear : green, lineWidth: 2))
            .shadow(color: filled ? green.opacity(0.4) : .clear, radius: 4, y: 2)
        }
        .buttonStyle(.plain)
    }
}

/// White box with a thin gradient stripe on top.
struct RainbowBox<Content: View>: View {
    let top: [Color]
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            Brand.gradient(top).frame(height: 4)
            content().padding(EdgeInsets(top: 32, leading: 26, bottom: 32, trailing: 26))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(LinearGradient(colors: [.white, Color(argb: 0xFFF8F9FF)], startPoint: .topLeading, endPoint: .bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .roundedBorder(Color(argb: 0xFFF0F0F0), radius: 24)
        .shadow(color: .black.opacity(0.05), radius: 15, y: 8)
    }
}

struct SectionTitle: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(text.tr)
                .font(.poppins(24, .heavy))
                .gradientText([Color(argb: 0xFF1B3A26), Color(argb: 0xFF4CAF50)])
            LinearGradient(colors: [Brand.siteGreen, .clear], startPoint: .leading, endPoint: .trailing)
                .frame(width: 50, height: 3)
        }
        .padding(.bottom, 22)
    }
}

private struct SpecTile: View {
    let spec: Spec

    var body: some View {
        HStack(spacing: 20) {
            Image(systemName: spec.icon)
                .font(.system(size: 28))
                .foregroundStyle(.white)
                .frame(width: 70, height: 70)
                .background(Brand.gradient(spec.colors), in: RoundedRectangle(cornerRadius: 18))
                .shadow(color: spec.colors[0].opacity(0.35), radius: 7, y: 6)
            VStack(alignment: .leading, spacing: 8) {
                Text(spec.label.tr.uppercased())
                    .font(.poppins(12.5, .semibold))
                    .kerning(1)
                    .foregroundStyle(Brand.muted)
                Text(spec.value.tr)
                    .font(.poppins(21, .heavy))
                    .foregroundStyle(Color(argb: 0xFF1B3A26))
            }
            Spacer(minLength: 0)
        }
        .padding(24)
        .background(Color(argb: 0xFFFCFCFC), in: RoundedRectangle(cornerRadius: 18))
        .roundedBorder(Color(argb: 0xFFE8E8E8), radius: 18, width: 1.5)
    }
}

private struct DetailRowView: View {
    let row: DetailRow

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 6) {
                Text(row.label.tr.uppercased())
                    .font(.poppins(12.5, .bold))
                    .kerning(1.2)
                    .foregroundStyle(Color(argb: 0xFF2E7D32))
                LinearGradient(colors: [Brand.siteGreen, .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 50, height: 3)
            }
            .fixedSize()
            Text(row.value.tr)
                .font(.poppins(17, .heavy))
                .multilineTextAlignment(.trailing)
                .gradientText([Color(argb: 0xFF1B3A26), Color(argb: 0xFF2E7D32)])
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 26)
        .padding(.vertical, 22)
        .background(Color(argb: 0xFFFCFCFC), in: RoundedRectangle(cornerRadius: 14))
        .roundedBorder(Color(argb: 0xFFE8E8E8), radius: 14, width: 1.5)
    }
}

/// "O'xshash …" card (the site's big card): photo with a white price tag,
/// title, location, three blue pills, then Rent / Barter tags and counters.
struct SimilarCard: View {
    let item: SimilarItem
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                Color.clear
                    .frame(height: 264)
                    .overlay { RemoteImage(path: item.image) }
                    .overlay(alignment: .bottomLeading) {
                        Text(item.price)
                            .font(.poppins(20, .heavy))
                            .foregroundStyle(Brand.ink)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(LinearGradient(colors: [.white, Color(argb: 0xFFF2F2F2)], startPoint: .leading, endPoint: .trailing),
                                        in: RoundedRectangle(cornerRadius: 14))
                            .padding(20)
                    }
                    .clipped()
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title.tr.uppercased())
                        .font(.poppins(21, .heavy))
                        .foregroundStyle(Color(argb: 0xFF1B3A26))
                        .lineLimit(1)
                    HStack(spacing: 8) {
                        Image(systemName: "mappin").font(.system(size: 17)).foregroundStyle(Brand.siteGreen)
                        Text(item.location.tr.uppercased()).font(.poppins(14)).foregroundStyle(Color(argb: 0xFF717171))
                    }
                    .padding(.top, 14)
                    HStack(spacing: 10) {
                        ForEach(Array(item.pills.enumerated()), id: \.offset) { _, pill in
                            HStack(spacing: 6) {
                                Image(systemName: pill.0).font(.system(size: 13)).foregroundStyle(Color(argb: 0xFF3B82F6))
                                Text(pill.1.tr).font(.poppins(13, .bold)).foregroundStyle(Brand.ink).lineLimit(1)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 9)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(argb: 0xFFEFF6FF), in: RoundedRectangle(cornerRadius: 14))
                            .roundedBorder(Color(argb: 0xFFBFDBFE), radius: 14)
                        }
                    }
                    .padding(.top, 30)
                    Rule(color: Color(argb: 0xFFEEEEEE)).padding(.vertical, 22)
                    HStack(spacing: 8) {
                        tag("Rent", on: item.rent)
                        tag("Barter", on: item.barter)
                        Spacer()
                        Image(systemName: "eye").foregroundStyle(Color(argb: 0xFF717171))
                        Text(verbatim: "\(item.views)").foregroundStyle(Color(argb: 0xFF717171))
                        Image(systemName: "heart").foregroundStyle(Color(argb: 0xFF717171)).padding(.leading, 10)
                        Text(verbatim: "\(item.likes)").foregroundStyle(Color(argb: 0xFF717171))
                    }
                    .font(.poppins(14))
                }
                .padding(26)
            }
            .frame(maxWidth: 330)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func tag(_ text: String, on: Bool) -> some View {
        Text(text.tr)
            .font(.poppins(13, .semibold))
            .foregroundStyle(on ? Color(argb: 0xFF2E7D32) : Color(argb: 0xFFBDBDBD))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(on ? Color(argb: 0xFFE8F5E9) : Color(argb: 0xFFF5F5F5), in: RoundedRectangle(cornerRadius: 8))
    }
}
