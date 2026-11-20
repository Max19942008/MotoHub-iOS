import PhotosUI
import SwiftUI

private let violet = Color(argb: 0xFF667EEA)
private let purple = Color(argb: 0xFF764BA2)

/// The site's "Yangi mototsikl qo'shish" / "Qism qo'shish" form.
/// Pass `bike` or `part` to edit an existing listing.
struct AddListingScreen: View {
    let isPart: Bool
    let bike: Motorbike?
    let part: Part?

    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var title: String
    @State private var price: String
    @State private var address: String
    @State private var year: String
    @State private var engine: String
    @State private var mileage: String
    @State private var stock: String
    @State private var desc: String
    @State private var currency: String
    @State private var location: String? = nil
    @State private var brand: String? = nil
    @State private var condition: String? = nil
    @State private var type: String? = nil
    @State private var category: String
    @State private var barter: Bool
    @State private var rent: Bool
    @State private var images: [String]
    @State private var picked: [PhotosPickerItem] = []
    @State private var uploading = false
    @State private var saving = false

    init(isPart: Bool, bike: Motorbike? = nil, part: Part? = nil) {
        self.isPart = isPart
        self.bike = bike
        self.part = part
        func num(_ n: Double?) -> String { n.map { $0 == 0 ? "" : Formatting.groupDigits($0, separator: "") } ?? "" }
        func nonEmpty(_ s: String?) -> String? { (s ?? "").isEmpty ? nil : s }
        _title = State(initialValue: bike?.title ?? part?.title ?? "")
        _price = State(initialValue: num(bike?.price ?? part?.price))
        _address = State(initialValue: bike?.address ?? "")
        _year = State(initialValue: num(bike.map { Double($0.year) }))
        _engine = State(initialValue: num(bike.map { Double($0.engineCc) }))
        _mileage = State(initialValue: num(bike.map { Double($0.mileage) }))
        _stock = State(initialValue: part.map { "\($0.stock)" } ?? "1")
        _desc = State(initialValue: Formatting.plainText(bike?.description ?? part?.description))
        _currency = State(initialValue: bike?.currency ?? part?.currency ?? "USD")
        _location = State(initialValue: nonEmpty(bike?.location ?? part?.location))
        _brand = State(initialValue: nonEmpty(bike?.brand ?? part?.brand))
        _condition = State(initialValue: nonEmpty(bike?.condition ?? part?.condition))
        _type = State(initialValue: nonEmpty(bike?.type ?? part?.type))
        _category = State(initialValue: part?.category ?? "SPARE_PART")
        _barter = State(initialValue: bike?.barter ?? part?.barter ?? false)
        _rent = State(initialValue: bike?.rent ?? false)
        _images = State(initialValue: (bike?.imagePaths ?? []) + (part?.imagePaths ?? []))
    }

    private var editing: Bool { bike != nil || part != nil }

    var body: some View {
        let types = isPart ? (category == "ACCESSORY" ? Catalog.accessoryTypes : Catalog.sparePartTypes) : Catalog.motorbikeTypes
        ScrollView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 6) {
                    Text((editing ? "E'lonni tahrirlash" : (isPart ? "Qism qo'shish" : "Yangi mototsikl qo'shish")).tr)
                        .font(.poppins(24, .heavy)).foregroundStyle(.white)
                    Text("We are glad to see you again!".tr).font(.poppins(14)).foregroundStyle(.white.opacity(0.85))
                }
                .padding(EdgeInsets(top: 24, leading: 22, bottom: 24, trailing: 22))
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Brand.gradient([violet, purple]), in: RoundedRectangle(cornerRadius: 16))

                VStack(alignment: .leading, spacing: 18) {
                    text("Sarlavha", $title, hint: "Sarlavha")
                    pair(text("Narx", $price, hint: "Narx", number: true),
                         select("Valyuta", currency, ["USD", "UZS", "KRW"], label: { $0 }) { currency = $0 ?? "USD" })
                    if isPart {
                        select("Turkum", category, ["SPARE_PART", "ACCESSORY"], label: { $0 == "ACCESSORY" ? "Aksessuar" : "Ehtiyot qism" }) {
                            category = $0 ?? "SPARE_PART"
                            type = nil
                        }
                    }
                    pair(select("Turni tanlang", type, types) { type = $0 },
                         select("Manzilni tanlang", location, Catalog.locations) { location = $0 })
                    if !isPart { text("Manzil", $address, hint: "Manzil") }
                    pair(select("Ayirboshlash", "\(barter)", ["true", "false"], label: yesNo) { barter = $0 == "true" },
                         isPart ? AnyView(text("Omborda (dona)", $stock, hint: "1", number: true))
                                : AnyView(select("Ijara", "\(rent)", ["true", "false"], label: yesNo) { rent = $0 == "true" }))
                    pair(select("Brend", brand, isPart ? Catalog.partBrands : Catalog.motorbikeBrands) { brand = $0 },
                         select("Holati", condition, isPart ? Catalog.partConditions : Catalog.motorbikeConditions) { condition = $0 })
                    if !isPart {
                        pair(text("Yil", $year, hint: "Masalan, 2020", number: true),
                             text("Dvigatel (CC)", $engine, hint: "Masalan, 250", number: true))
                        text("Yurgan masofa", $mileage, hint: "Km", number: true)
                    }
                    Text("E'lon tavsifi".tr).font(.poppins(20, .heavy)).gradientText([violet, purple]).padding(.top, 6)
                    text("Tavsif", $desc, hint: "E'lon haqida yozing", lines: 5)
                    photos
                    Button { Task { await save() } } label: {
                        Group {
                            if saving { ProgressView().tint(.white) } else { Text("Saqlash".tr).font(.poppins(15, .bold)) }
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(Brand.ink.opacity(saving || uploading ? 0.5 : 1), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    .disabled(saving || uploading)
                    .padding(.top, 8)
                }
                .padding(EdgeInsets(top: 22, leading: 16, bottom: 22, trailing: 16))
                .background(Brand.gradient([.white, Color(argb: 0xFFF8F9FF)]), in: RoundedRectangle(cornerRadius: 20))
                .roundedBorder(violet.opacity(0.2), radius: 20)
            }
            .padding(EdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16))
        }
        .background(Color(argb: 0xFFF6F6F6))
        .scrollDismissesKeyboard(.interactively)
        .sitePage(back: true)
        .onChange(of: picked) { _, items in
            guard !items.isEmpty else { return }
            Task { await upload(items) }
        }
    }

    private func yesNo(_ v: String) -> String { v == "true" ? "Ha" : "Yo'q" }

    private var photos: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("E'loningiz rasmlarini yuklang".tr).font(.poppins(14, .semibold)).foregroundStyle(Brand.ink)
            VStack(spacing: 8) {
                Image(systemName: "icloud.and.arrow.up").font(.system(size: 36)).foregroundStyle(violet)
                Text("Rasmlarni tanlang".tr).font(.poppins(14, .bold)).foregroundStyle(Brand.ink)
                Text("Rasmlar JPEG yoki PNG formatida bo'lishi kerak (10 tagacha)".tr)
                    .font(.poppins(12.5)).foregroundStyle(Brand.muted).multilineTextAlignment(.center)
                PhotosPicker(selection: $picked, maxSelectionCount: max(1, 10 - images.count), matching: .images) {
                    HStack(spacing: 8) {
                        if uploading { ProgressView() } else { Image(systemName: "photo.on.rectangle") }
                        Text("Fayllarni tanlash".tr).font(.poppins(14, .semibold))
                    }
                    .foregroundStyle(Brand.ink)
                    .padding(.horizontal, 18)
                    .frame(height: 42)
                    .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.ink))
                }
                .disabled(uploading || images.count >= 10)
                .padding(.top, 6)
            }
            .padding(20)
            .frame(maxWidth: .infinity)
            .background(.white, in: RoundedRectangle(cornerRadius: 16))
            .roundedBorder(violet.opacity(0.35), radius: 16, width: 1.5)
            if !images.isEmpty {
                FlowLayout(spacing: 10) {
                    ForEach(images, id: \.self) { img in
                        CoverImage(path: img)
                            .frame(width: 96, height: 76)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .overlay(alignment: .topTrailing) {
                                Button { images.removeAll { $0 == img } } label: {
                                    Image(systemName: "xmark").font(.system(size: 11, weight: .bold)).foregroundStyle(.red)
                                        .frame(width: 22, height: 22).background(.white, in: Circle())
                                }
                                .buttonStyle(.plain)
                                .padding(4)
                            }
                    }
                }
                .padding(.top, 4)
            }
        }
    }

    // MARK: - Fields

    private func labeled<V: View>(_ label: String, @ViewBuilder _ field: () -> V) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label.tr).font(.poppins(14, .semibold)).foregroundStyle(Brand.ink)
            field()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func text(_ label: String, _ value: Binding<String>, hint: String, number: Bool = false, lines: Int = 1) -> some View {
        labeled(label) {
            Group {
                if lines > 1 {
                    TextField("", text: value, prompt: Text(hint.tr).foregroundStyle(Color(argb: 0xFF999999)), axis: .vertical)
                        .lineLimit(lines...(lines + 4))
                } else {
                    TextField("", text: value, prompt: Text(hint.tr).foregroundStyle(Color(argb: 0xFF999999)))
                }
            }
            .font(.poppins(15))
            .keyboardType(number ? .numberPad : .default)
            .padding(.horizontal, 16)
            .padding(.vertical, 15)
            .background(.white, in: RoundedRectangle(cornerRadius: 12))
            .roundedBorder(violet.opacity(0.2), radius: 12, width: 2)
        }
    }

    private func select(_ caption: String, _ value: String?, _ options: [String], label: @escaping (String) -> String = Formatting.label,
                        onChange: @escaping (String?) -> Void) -> some View {
        labeled(caption) {
            Menu {
                ForEach(options, id: \.self) { o in
                    Button { onChange(o) } label: {
                        if o == value { Label(label(o).tr, systemImage: "checkmark") } else { Text(label(o).tr) }
                    }
                }
            } label: {
                HStack {
                    Text((value.flatMap { options.contains($0) ? label($0) : nil } ?? "Tanlang").tr)
                        .font(.poppins(15))
                        .foregroundStyle(value != nil && options.contains(value!) ? Brand.ink : Color(argb: 0xFF999999))
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Image(systemName: "chevron.down").font(.system(size: 13, weight: .semibold)).foregroundStyle(Brand.muted)
                }
                .padding(.horizontal, 16)
                .frame(height: 54)
                .background(.white, in: RoundedRectangle(cornerRadius: 12))
                .roundedBorder(violet.opacity(0.2), radius: 12, width: 2)
                .contentShape(Rectangle())
            }
            .menuOrder(.fixed)
        }
    }

    private func pair<A: View, B: View>(_ a: A, _ b: B) -> some View {
        HStack(alignment: .top, spacing: 12) {
            a
            b
        }
    }

    // MARK: - Actions

    private func upload(_ items: [PhotosPickerItem]) async {
        uploading = true
        defer {
            uploading = false
            picked = []
        }
        do {
            for item in items.prefix(max(0, 10 - images.count)) {
                guard let raw = try await item.loadTransferable(type: Data.self),
                      let jpeg = ImageEncoding.jpeg(raw, maxSide: 2048) else { continue }
                let path = try await app.myPage.uploadImage(jpeg, fileName: "photo.jpg", target: isPart ? "part" : "property")
                images.append(path)
            }
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }

    /// Same rules as the backend DTOs, checked here so the user sees Uzbek text.
    private func problem() -> String? {
        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.count < 3 || t.count > 100 { return "Sarlavha 3–100 belgidan iborat bo'lishi kerak" }
        if (Double(price.trimmingCharacters(in: .whitespaces)) ?? 0) <= 0 { return "Narxni kiriting" }
        if type == nil { return "Turni tanlang" }
        if location == nil { return "Manzilni tanlang" }
        if brand == nil { return "Brendni tanlang" }
        if condition == nil { return "Holatini tanlang" }
        if images.isEmpty { return "Kamida bitta rasm qo'shing" }
        let d = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        if !d.isEmpty, d.count < 5 || d.count > 500 { return "Tavsif 5–500 belgidan iborat bo'lishi kerak" }
        if isPart {
            if (Int(stock.trimmingCharacters(in: .whitespaces)) ?? 0) < 1 { return "Omborda kamida 1 dona bo'lishi kerak" }
        } else {
            let a = address.trimmingCharacters(in: .whitespacesAndNewlines)
            if a.count < 3 || a.count > 100 { return "Manzil 3–100 belgidan iborat bo'lishi kerak" }
            let y = Int(year.trimmingCharacters(in: .whitespaces)) ?? 0
            if y < 1950 || y > Calendar.current.component(.year, from: .now) + 1 { return "Yilni kiriting" }
            if (Int(engine.trimmingCharacters(in: .whitespaces)) ?? 0) < 125 { return "Dvigatel hajmi kamida 125 CC" }
            if (Int(mileage.trimmingCharacters(in: .whitespaces)) ?? 0) < 10 { return "Yurgan masofa kamida 10 km" }
        }
        return nil
    }

    private func save() async {
        if let problem = problem() { return router.toast(problem.tr) }
        let d = desc.trimmingCharacters(in: .whitespacesAndNewlines)
        let p = Double(price.trimmingCharacters(in: .whitespaces)) ?? 0
        saving = true
        defer { saving = false }
        do {
            if isPart {
                var fields: JSONObject = [
                    "partCategory": category, "partType": type ?? "", "partLocation": location ?? "",
                    "partBrand": brand ?? "", "partCondition": condition ?? "",
                    "partTitle": title.trimmingCharacters(in: .whitespacesAndNewlines), "partPrice": p,
                    "partCurrency": currency, "partStockCount": Int(stock.trimmingCharacters(in: .whitespaces)) ?? 1,
                    "partImages": images, "partBarter": barter,
                ]
                if !d.isEmpty { fields["partDesc"] = d }
                try await app.myPage.savePart(fields, id: part?.id)
            } else {
                var fields: JSONObject = [
                    "propertyType": type ?? "", "propertyLocation": location ?? "", "propertyBrand": brand ?? "",
                    "propertyCondition": condition ?? "",
                    "propertyAddress": address.trimmingCharacters(in: .whitespacesAndNewlines),
                    "propertyTitle": title.trimmingCharacters(in: .whitespacesAndNewlines), "propertyPrice": p,
                    "propertyCurrency": currency,
                    "propertyYear": Int(year.trimmingCharacters(in: .whitespaces)) ?? 0,
                    "propertyEngineCc": Int(engine.trimmingCharacters(in: .whitespaces)) ?? 0,
                    "propertyMileAge": Int(mileage.trimmingCharacters(in: .whitespaces)) ?? 0,
                    "propertyImages": images, "propertyBarter": barter, "propertyRent": rent,
                ]
                if !d.isEmpty { fields["propertyDesc"] = d }
                try await app.myPage.saveMotorbike(fields, id: bike?.id)
            }
            router.toast((editing ? "E'lon yangilandi" : "E'lon joylandi").tr)
            router.myPageSection = isPart ? MySection.myParts.rawValue : MySection.myBikes.rawValue
            router.pop()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}
