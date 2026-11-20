import SwiftUI

/// Bike page, laid out like the website's mobile bike detail. Opens with the
/// list's data (or a spinner when only the id is known) and refreshes it.
struct MotorbikeDetailScreen: View {
    let id: String
    @State private var bike: Motorbike? = nil
    @State private var similar: [SimilarItem]? = nil
    @State private var failed: String? = nil

    @Environment(AppContainer.self) private var app

    init(id: String, initial: Motorbike? = nil) {
        self.id = id
        _bike = State(initialValue: initial)
    }

    var body: some View {
        Group {
            if let bike {
                SiteDetailPage(
                    content: content(bike),
                    similar: similar,
                    onLike: { try await app.listings.likeMotorbike(id: bike.id) },
                    onInterest: { try await app.listings.notifyInterest(motorbikeID: bike.id) },
                    onRefresh: refresh
                )
            } else if let failed {
                MessageView(systemImage: "exclamationmark.triangle", message: failed) {
                    self.failed = nil
                    Task { await refresh() }
                }
                .frame(maxHeight: .infinity)
                .sitePage()
            } else {
                LoadingView().frame(maxHeight: .infinity).sitePage()
            }
        }
        .task {
            await refresh()
            await loadSimilar()
        }
    }

    private func refresh() async {
        do {
            bike = try await app.listings.motorbike(id: id)
        } catch {
            // Keep showing the list data.
            if bike == nil { failed = error.localizedDescription }
        }
    }

    private func loadSimilar() async {
        guard similar == nil, let location = bike?.location else { return }
        let list = (try? await app.listings.similarMotorbikes(location: location)) ?? []
        similar = list.filter { $0.id != id }.map { b in
            SimilarItem(
                id: b.id, image: b.imagePaths.first, price: Formatting.price(b.price, currency: b.currency),
                title: b.title, location: b.location,
                pills: [("gearshape.fill", "\(b.engineCc) CC"), ("speedometer", "\(b.mileage) km"), ("tag.fill", b.brand)],
                views: b.views, likes: b.likes, rent: b.rent, barter: b.barter, route: .motorbike(b)
            )
        }
    }

    private func content(_ b: Motorbike) -> DetailContent {
        // Same wording as the site; nothing when the bike is only for sale.
        let options = b.barter ? "Ayirboshlash" : (b.rent ? "Ijara mavjud" : "")
        // City and street on one line; skip the city if the address already starts with it.
        let city = Formatting.label(b.location).tr
        let street = b.address.trimmingCharacters(in: .whitespacesAndNewlines)
        let place = street.isEmpty ? city : street.lowercased().hasPrefix(city.lowercased()) ? street : "\(city), \(street)"
        var details = [DetailRow(label: "Manzil", value: place), DetailRow(label: "Holati", value: Formatting.label(b.condition))]
        if !options.isEmpty { details.append(DetailRow(label: "Qo'shimchalar", value: options)) }
        return DetailContent(
            id: b.id, crumb: "Mototsikl", title: b.title, typeBadge: Formatting.label(b.type),
            location: Formatting.label(b.location), images: b.imagePaths,
            price: Formatting.price(b.price, currency: b.currency),
            pricePeriod: b.rent ? "per month" : (b.barter ? "for exchange" : "total"),
            views: b.views, likes: b.likes, liked: b.liked, interested: b.interested, seller: b.seller,
            specs: [
                Spec(icon: "gearshape.fill", label: "Dvigatel", value: "\(b.engineCc) CC", colors: specRed),
                Spec(icon: "speedometer", label: "Yurgan masofa", value: "\(b.mileage) km", colors: specBlue),
                Spec(icon: "calendar", label: "Yil", value: "\(b.year)", colors: specAmber),
                Spec(icon: "tag.fill", label: "Brend", value: b.brand, colors: specGreen),
                Spec(icon: "scooter", label: "Mototsikl turi", value: Formatting.label(b.type), colors: specPurple),
            ],
            descTitle: "Mototsikl tavsifi", description: b.description,
            // Only what the cards above don't already show.
            detailsTitle: "Mototsikl tafsilotlari", details: details,
            commentGroup: "PROPERTY",
            similarTitle: "O'xshash mototsikllar", similarSubtitle: "Yaqin atrofdagi ajoyib mototsikllarni kashf eting"
        )
    }
}

/// Part / accessory page, same layout as the bike page (the site has no reviews here).
struct PartDetailScreen: View {
    let id: String
    @State private var part: Part? = nil
    @State private var similar: [SimilarItem]? = nil
    @State private var failed: String? = nil

    @Environment(AppContainer.self) private var app

    init(id: String, initial: Part? = nil) {
        self.id = id
        _part = State(initialValue: initial)
    }

    var body: some View {
        Group {
            if let part {
                SiteDetailPage(
                    content: content(part),
                    similar: similar,
                    onLike: { try await app.listings.likePart(id: part.id) },
                    onInterest: { try await app.listings.notifyInterest(partID: part.id) },
                    onRefresh: refresh
                )
            } else if let failed {
                MessageView(systemImage: "exclamationmark.triangle", message: failed) {
                    self.failed = nil
                    Task { await refresh() }
                }
                .frame(maxHeight: .infinity)
                .sitePage()
            } else {
                LoadingView().frame(maxHeight: .infinity).sitePage()
            }
        }
        .task {
            await refresh()
            await loadSimilar()
        }
    }

    private func refresh() async {
        do {
            part = try await app.listings.part(id: id)
        } catch {
            if part == nil { failed = error.localizedDescription }
        }
    }

    private func loadSimilar() async {
        guard similar == nil, let category = part?.category else { return }
        let list = (try? await app.listings.similarParts(category: category)) ?? []
        similar = list.filter { $0.id != id }.map { p in
            SimilarItem(
                id: p.id, image: p.imagePaths.first, price: Formatting.price(p.price, currency: p.currency),
                title: p.title, location: p.location,
                pills: [("square.grid.2x2.fill", Formatting.label(p.type)), ("wrench.fill", p.condition), ("tag.fill", p.brand)],
                views: p.views, likes: p.likes, barter: p.barter, route: .part(p)
            )
        }
    }

    private func content(_ p: Part) -> DetailContent {
        let category = p.isAccessory ? "Aksessuar" : "Ehtiyot qism"
        var details = [DetailRow(label: "Manzil", value: Formatting.label(p.location))]
        if p.barter { details.append(DetailRow(label: "Qo'shimchalar", value: "Ayirboshlash")) }
        return DetailContent(
            id: p.id, crumb: "Ehtiyot qismlar va aksessuarlar", title: p.title, typeBadge: category,
            location: Formatting.label(p.location), images: p.imagePaths,
            price: Formatting.price(p.price, currency: p.currency),
            pricePeriod: p.barter ? "for exchange" : "total",
            views: p.views, likes: p.likes, liked: p.liked, interested: p.interested, seller: p.seller,
            specs: [
                Spec(icon: "square.grid.2x2.fill", label: "Turkum", value: category, colors: specRed),
                Spec(icon: "wrench.fill", label: "Tur", value: Formatting.label(p.type), colors: specBlue),
                Spec(icon: "tag.fill", label: "Brend", value: p.brand, colors: specAmber),
                Spec(icon: "checkmark.seal.fill", label: "Holati", value: Formatting.label(p.condition), colors: specGreen),
                Spec(icon: "shippingbox.fill", label: "Omborda", value: "\(p.stock) dona", colors: specPurple),
            ],
            descTitle: "Tavsif", description: p.description,
            detailsTitle: "Tafsilotlar", details: details,
            commentGroup: nil,
            similarTitle: "O'xshash qismlar", similarSubtitle: "Ko'proq qism va aksessuarlarni kashf eting"
        )
    }
}
