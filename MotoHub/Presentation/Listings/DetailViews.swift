import SwiftUI

struct MotorbikeDetailView: View {
    @State private var model: DetailViewModel<Motorbike>

    init(id: String, repository: any ListingRepository) {
        _model = State(initialValue: DetailViewModel { try await repository.motorbike(id: id) })
    }

    var body: some View {
        DetailPhaseView(model: model) { bike in
            ListingDetailLayout(
                title: bike.title,
                price: Formatting.price(bike.price, currency: bike.currency),
                imagePaths: bike.imagePaths,
                tags: [
                    Formatting.label(bike.brand),
                    Formatting.label(bike.type),
                    Formatting.label(bike.condition),
                    bike.barter ? "Barter mumkin" : nil,
                    bike.rent ? "Ijaraga" : nil,
                ].compactMap { $0 },
                specs: [
                    Spec("calendar", "Yili", bike.year > 0 ? "\(bike.year)" : nil),
                    Spec("engine.combustion", "Dvigatel", bike.engineCc > 0 ? "\(Formatting.groupDigits(Double(bike.engineCc))) cc" : nil),
                    Spec("road.lanes", "Probeg", "\(Formatting.groupDigits(Double(bike.mileage))) km"),
                    Spec("mappin.and.ellipse", "Hudud", Formatting.label(bike.location)),
                    Spec("house", "Manzil", bike.address.isEmpty ? nil : bike.address),
                    Spec("eye", "Ko‘rishlar", "\(bike.views)"),
                    Spec("clock", "Joylangan", Formatting.timeAgo(bike.createdAt)),
                ],
                description: Formatting.plainText(bike.description),
                seller: bike.seller
            )
        }
        .navigationTitle("Mototsikl")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct PartDetailView: View {
    @State private var model: DetailViewModel<Part>

    init(id: String, repository: any ListingRepository) {
        _model = State(initialValue: DetailViewModel { try await repository.part(id: id) })
    }

    var body: some View {
        DetailPhaseView(model: model) { part in
            ListingDetailLayout(
                title: part.title,
                price: Formatting.price(part.price, currency: part.currency),
                imagePaths: part.imagePaths,
                tags: [
                    Formatting.label(part.category),
                    Formatting.label(part.type),
                    Formatting.label(part.condition),
                    part.barter ? "Barter mumkin" : nil,
                ].compactMap { $0 },
                specs: [
                    Spec("tag", "Brend", Formatting.label(part.brand)),
                    Spec("shippingbox", "Omborda", "\(part.stock) dona"),
                    Spec(
                        "checkmark.seal",
                        "Mos keladi",
                        part.compatibleBrands.isEmpty ? nil : part.compatibleBrands.map(Formatting.label).joined(separator: ", ")
                    ),
                    Spec("mappin.and.ellipse", "Hudud", Formatting.label(part.location)),
                    Spec("eye", "Ko‘rishlar", "\(part.views)"),
                    Spec("clock", "Joylangan", Formatting.timeAgo(part.createdAt)),
                ],
                description: Formatting.plainText(part.description),
                seller: part.seller
            )
        }
        .navigationTitle("Qism")
        .navigationBarTitleDisplayMode(.inline)
    }

}

/// Loading / error / content switch for a detail screen.
struct DetailPhaseView<Item: Sendable, Content: View>: View {
    let model: DetailViewModel<Item>
    @ViewBuilder let content: (Item) -> Content

    var body: some View {
        Group {
            switch model.phase {
            case .loading:
                LoadingStateView()
            case .failed(let message):
                MessageStateView(systemImage: "exclamationmark.triangle", message: message, actionTitle: "Qayta urinish") {
                    Task { await model.retry() }
                }
            case .loaded(let item):
                content(item)
            }
        }
        .task { await model.load() }
    }
}

struct Spec: Identifiable {
    let icon: String
    let title: String
    let value: String?
    var id: String { title }

    init(_ icon: String, _ title: String, _ value: String?) {
        self.icon = icon
        self.title = title
        self.value = value
    }
}

struct ListingDetailLayout: View {
    let title: String
    let price: String
    let imagePaths: [String]
    let tags: [String]
    let specs: [Spec]
    let description: String
    let seller: Seller?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Gallery(paths: imagePaths)

                VStack(alignment: .leading, spacing: 8) {
                    Text(title.isEmpty ? "Nomsiz e’lon" : title).font(.title2.bold())
                    Text(price).font(.title3.bold()).foregroundStyle(Color.accentColor)
                    FlowLayout(spacing: 6) {
                        ForEach(tags, id: \.self) { TagView(text: $0, highlighted: true) }
                    }
                }
                .padding(.horizontal, 16)

                VStack(spacing: 0) {
                    ForEach(specs.filter { !($0.value ?? "").isEmpty }) { spec in
                        HStack {
                            Label(spec.title, systemImage: spec.icon).foregroundStyle(.secondary)
                            Spacer()
                            Text(spec.value ?? "").multilineTextAlignment(.trailing)
                        }
                        .font(.subheadline)
                        .padding(.vertical, 10)
                        Divider()
                    }
                }
                .padding(.horizontal, 16)

                if !description.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tavsif").font(.headline)
                        Text(description).font(.body)
                    }
                    .padding(.horizontal, 16)
                }

                if let seller {
                    SellerCard(seller: seller).padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 24)
        }
        .safeAreaInset(edge: .bottom) {
            if let phone = seller?.phone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                Link(destination: url) {
                    Label("Sotuvchiga qo‘ng‘iroq qilish", systemImage: "phone.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                        .foregroundStyle(Color.white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.bar)
            }
        }
    }
}

private struct Gallery: View {
    let paths: [String]

    var body: some View {
        Group {
            if paths.isEmpty {
                RemoteImage(path: nil, iconSize: 44)
            } else {
                TabView {
                    ForEach(paths, id: \.self) { path in
                        Color.clear
                            .overlay { RemoteImage(path: path, iconSize: 44) }
                            .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: paths.count > 1 ? .automatic : .never))
            }
        }
        .frame(height: 280)
        .clipped()
    }
}

private struct SellerCard: View {
    let seller: Seller

    var body: some View {
        HStack(spacing: 12) {
            RemoteImage(path: seller.imagePath, iconSize: 20)
                .frame(width: 48, height: 48)
                .clipShape(Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(seller.nick).font(.headline)
                Text(seller.type == "AGENT" ? "Diler" : "Sotuvchi").font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if let phone = seller.phone, !phone.isEmpty {
                Text(phone).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 16))
    }
}
