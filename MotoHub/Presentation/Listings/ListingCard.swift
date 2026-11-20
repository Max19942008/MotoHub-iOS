import SwiftUI

/// One spec pill on a card (mileage, condition, engine…).
struct CardChip: Hashable {
    let icon: String
    let text: String
}

/// Accent of a card: the website draws "trend" cards green and "popular / top" cards indigo.
struct CardAccent {
    let main: Color
    let dark: Color
    let soft: Color
    let border: Color

    static let green = CardAccent(main: Brand.green, dark: Brand.greenDark, soft: Color(argb: 0xFFEFF8F1), border: Color(argb: 0xFFCDEBD5))
    static let indigo = CardAccent(main: Brand.indigo, dark: Brand.indigoDark, soft: Color(argb: 0xFFF1F1FD), border: Color(argb: 0xFFDADAF8))
}

/// The website's listing card: photo with view/like pills, title + "BRAND · YEAR"
/// with a ★ rating pill, location row, three spec pills, then a centered
/// "DAN / price" and the call-to-action button.
struct ListingCard: View {
    let image: String?
    let title: String
    /// Small uppercase line under the title, e.g. "YAMAHA · 2024".
    let kicker: String
    let price: String
    let location: String
    var address: String?
    /// Top-left label on the photo, e.g. "SPORT".
    var badge: String?
    /// Already formatted, e.g. "20.00" on home or "1.2" in lists (as on the site).
    var rating: String?
    var chips: [CardChip] = []
    var views: Int?
    var likes: Int?
    var action = "Sotib Olish"
    /// "DAN" on bikes, "NARX" on parts (as on the site).
    var priceLabel = "DAN"
    /// 1 in carousels, so every card there has the same height.
    var titleLines = 2
    var accent = CardAccent.green
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                photo
                VStack(spacing: 0) {
                    header
                    locationRow.padding(.top, 14)
                    if !chips.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(chips, id: \.self) { SpecPill(chip: $0, accent: accent) }
                        }
                        .padding(.top, 8)
                    }
                    Rule().padding(.top, 18).padding(.bottom, 22)
                    Text(priceLabel.tr)
                        .font(.poppins(10.5, .bold))
                        .kerning(0.8)
                        .foregroundStyle(Color(argb: 0xFF9CA3AF))
                    Text(price)
                        .font(.poppins(24, .heavy))
                        .foregroundStyle(accent.main)
                    Text(action.tr)
                        .font(.poppins(15, .heavy))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 26)
                        .padding(.vertical, 11)
                        .background(LinearGradient(colors: [accent.main, accent.dark], startPoint: .leading, endPoint: .trailing),
                                    in: RoundedRectangle(cornerRadius: 12))
                        .shadow(color: accent.main.opacity(0.32), radius: 8, y: 7)
                        .padding(.top, 10)
                }
                .padding(EdgeInsets(top: 18, leading: 18, bottom: 22, trailing: 18))
            }
            .background(Color(argb: 0xFFFDFDFD))
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .roundedBorder(Color(argb: 0xFFEDEDED), radius: 22)
            .contentShape(RoundedRectangle(cornerRadius: 22))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("listing-card")
    }

    private var photo: some View {
        Color.clear
            .aspectRatio(16 / 10, contentMode: .fit)
            .overlay { RemoteImage(path: image) }
            .overlay(alignment: .topLeading) {
                if let badge, !badge.isEmpty {
                    PhotoPill(text: badge.tr.uppercased(), light: true).padding(12)
                }
            }
            .overlay(alignment: .bottomLeading) {
                if let views { PhotoPill(icon: "eye.fill", text: "\(views)").padding(12) }
            }
            .overlay(alignment: .bottomTrailing) {
                if let likes { PhotoPill(icon: "heart.fill", text: "\(likes)", soft: true).padding(12) }
            }
            .clipped()
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title.tr)
                    .font(.poppins(17, .heavy))
                    .foregroundStyle(Brand.ink)
                    .lineLimit(titleLines)
                Text(kicker)
                    .font(.poppins(12.5, .semibold))
                    .kerning(0.4)
                    .foregroundStyle(Brand.muted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            if let rating {
                HStack(spacing: 5) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(argb: 0xFFFFC107))
                    Text(rating)
                        .font(.poppins(14, .heavy))
                        .foregroundStyle(accent.main)
                }
                .padding(.horizontal, 11)
                .padding(.vertical, 6)
                .background(accent.soft, in: RoundedRectangle(cornerRadius: 12))
                .roundedBorder(accent.border, radius: 12)
                .shadow(color: accent.main.opacity(0.12), radius: 5)
            }
        }
    }

    private var locationRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "mappin.and.ellipse")
                .font(.system(size: 15))
                .foregroundStyle(accent.main)
            Text(location.tr)
                .font(.poppins(12.5, .bold))
                .foregroundStyle(Color(argb: 0xFF374151))
            Text((address ?? "").tr)
                .font(.poppins(11.5))
                .foregroundStyle(Brand.muted)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
        .background(accent.soft, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct PhotoPill: View {
    var icon: String?
    let text: String
    var light = false
    /// The like counter on the site is a lighter, translucent pill.
    var soft = false

    var body: some View {
        let fg = light ? Brand.ink : Color.white
        let bg = light ? Color.white : soft ? Color.white.opacity(0.35) : Brand.ink.opacity(0.75)
        HStack(spacing: 6) {
            if let icon { Image(systemName: icon).font(.system(size: 13)) }
            Text(text).font(.poppins(12.5, .bold)).kerning(0.4)
        }
        .foregroundStyle(fg)
        .padding(.horizontal, light ? 12 : 11)
        .padding(.vertical, 6)
        .background(bg, in: RoundedRectangle(cornerRadius: light ? 8 : 14))
    }
}

private struct SpecPill: View {
    let chip: CardChip
    let accent: CardAccent

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: chip.icon)
                .font(.system(size: 12))
                .foregroundStyle(accent.main)
            Text(chip.text.tr)
                .font(.poppins(12, .bold))
                .foregroundStyle(Brand.ink)
                .lineLimit(1)
        }
        .padding(8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(accent.soft, in: RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Cards for each entity

extension ListingCard {
    /// A bike card as the list pages draw it (labels, list rating).
    static func listBike(_ bike: Motorbike, onTap: @escaping () -> Void) -> ListingCard {
        ListingCard(
            image: bike.imagePaths.first,
            title: bike.title,
            kicker: "\(bike.brand) · \(bike.year)",
            price: Formatting.price(bike.price, currency: bike.currency),
            location: Formatting.label(bike.location),
            address: bike.address,
            badge: bike.type,
            rating: Formatting.siteRating(bike.rank),
            chips: [
                CardChip(icon: "speedometer", text: "\(bike.mileage) milya"),
                CardChip(icon: "scooter", text: Formatting.label(bike.condition)),
                CardChip(icon: "gearshape.fill", text: "\(bike.engineCc) cc"),
            ],
            views: bike.views,
            likes: bike.likes,
            onTap: onTap
        )
    }

    /// A part card as the list pages draw it.
    static func listPart(_ part: Part, onTap: @escaping () -> Void) -> ListingCard {
        let category = part.isAccessory ? "Aksessuar" : "Ehtiyot qism"
        return ListingCard(
            image: part.imagePaths.first,
            title: part.title,
            kicker: "\(part.brand) · \(Formatting.label(part.type).tr)",
            price: Formatting.price(part.price, currency: part.currency),
            location: Formatting.label(part.location),
            address: category,
            badge: category,
            rating: Formatting.siteRating(part.rank),
            chips: [
                CardChip(icon: "square.grid.2x2.fill", text: Formatting.label(part.type)),
                CardChip(icon: "wrench.fill", text: part.condition),
                CardChip(icon: "shippingbox.fill", text: "\(part.stock) dona"),
            ],
            views: part.views,
            likes: part.likes,
            priceLabel: "NARX",
            onTap: onTap
        )
    }
}
