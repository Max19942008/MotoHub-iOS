import SwiftUI

private let violet = Color(argb: 0xFF667EEA)
private let purple = Color(argb: 0xFF764BA2)
private let pink = Color(argb: 0xFFF093FB)

/// The site's Help centre (/cs): "E'lon-xabar" and "Savol-javob" tabs.
struct HelpScreen: View {
    @State private var faq = false
    @State private var category = "bike"
    @State private var open: Int? = 0

    private static let categories = [
        ("bike", "Mototsikl"), ("payment", "To'lov"), ("buyers", "Xaridorlar uchun"), ("agents", "Agentlar uchun"),
        ("membership", "A'zolik"), ("community", "Hamjamiyat"), ("other", "Boshqa"),
    ]

    // Same two notices as the site.
    private static let notices = [
        (true, "Register to use and get discounts", "01.03.2024"),
        (false, "It's absolutely free to upload and trade bikes", "31.03.2024"),
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 10) {
                        Image(systemName: "sparkles").font(.system(size: 26)).foregroundStyle(violet)
                        Text("Yordam markazi".tr)
                            .font(.poppins(30, .heavy))
                            .multilineTextAlignment(.center)
                            .gradientText([violet, purple, pink])
                    }
                    .frame(maxWidth: .infinity)
                    Capsule().fill(Brand.gradient([violet, purple])).frame(width: 100, height: 4)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 12)
                        .padding(.bottom, 14)
                    Text("🌟 Biz yordam berishga tayyormiz! Istalgan savolni bering".tr)
                        .font(.poppins(14.5))
                        .multilineTextAlignment(.center)
                        .foregroundStyle(violet)
                        .frame(maxWidth: .infinity)
                    HStack(spacing: 10) {
                        tab("📢", "E'lon-xabar", active: !faq) { faq = false }
                        tab("❓", "Savol-javob", active: faq) { faq = true }
                    }
                    .padding(.top, 22)
                    Group {
                        if faq { faqContent } else { noticeContent }
                    }
                    .padding(.top, 28)
                }
                .padding(EdgeInsets(top: 28, leading: 16, bottom: 40, trailing: 16))
                SiteFooter()
            }
        }
        .background(LinearGradient(colors: [Color(argb: 0xFFF5F7FF), Color(argb: 0xFFEEF0FD), Color(argb: 0xFFF6F4FE)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private func tab(_ icon: String, _ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(verbatim: icon).font(.system(size: 20))
                Text(label.tr).font(.poppins(15, .heavy)).foregroundStyle(active ? .white : violet).lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)
            .background(active ? Brand.gradient([violet, purple]) : Brand.gradient([.white, .white]), in: RoundedRectangle(cornerRadius: 16))
            .roundedBorder(violet.opacity(0.3), radius: 16, width: 2)
            .shadow(color: active ? violet.opacity(0.3) : .clear, radius: 8, y: 6)
        }
        .buttonStyle(.plain)
    }

    private var noticeContent: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("📢 E'lon-xabar".tr).font(.poppins(24, .heavy)).foregroundStyle(violet)
            VStack(spacing: 0) {
                HStack {
                    Text(verbatim: "#").frame(width: 42, alignment: .leading)
                    Text("Sarlavha".tr)
                    Spacer()
                    Text("Sana".tr)
                }
                .font(.poppins(14, .bold))
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Brand.gradient([violet, purple]))
                ForEach(Self.notices.indices, id: \.self) { i in
                    let n = Self.notices[i]
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            if n.0 {
                                Text("🎉 Event".tr)
                                    .font(.poppins(12, .bold))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color(argb: 0xFFFF9800), in: Capsule())
                            } else {
                                Text(verbatim: "\(i + 1)")
                                    .font(.poppins(14, .bold))
                                    .foregroundStyle(.white)
                                    .frame(width: 30, height: 30)
                                    .background(Brand.gradient([violet, purple]), in: RoundedRectangle(cornerRadius: 10))
                            }
                            Spacer()
                            Text(verbatim: "📅 \(n.2)").font(.poppins(12.5)).foregroundStyle(Brand.muted)
                        }
                        Text(n.1.tr).font(.poppins(15, .semibold)).foregroundStyle(Brand.ink)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(n.0 ? Brand.gradient([Color(argb: 0xFFFFF5E6), Color(argb: 0xFFFFE6CC)]) : Brand.gradient([.white, .white]))
                    .overlay(alignment: .leading) { (n.0 ? Color(argb: 0xFFFF9800) : .clear).frame(width: 4) }
                    .overlay(alignment: .bottom) { violet.opacity(0.1).frame(height: 1) }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: violet.opacity(0.12), radius: 12, y: 8)
        }
    }

    private var faqContent: some View {
        let items = faqData[category] ?? []
        return VStack(alignment: .leading, spacing: 18) {
            FlowLayout(spacing: 8) {
                ForEach(Self.categories.indices, id: \.self) { i in
                    let c = Self.categories[i]
                    let selected = category == c.0
                    Button {
                        category = c.0
                        open = 0
                    } label: {
                        Text(c.1.tr)
                            .font(.poppins(14, .bold))
                            .foregroundStyle(selected ? .white : violet)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? violet : .white, in: RoundedRectangle(cornerRadius: 12))
                            .roundedBorder(violet.opacity(0.3), radius: 12)
                    }
                    .buttonStyle(.plain)
                }
            }
            VStack(spacing: 0) {
                ForEach(items.indices, id: \.self) { i in
                    FaqTile(question: items[i].0, answer: items[i].1, open: open == i) {
                        withAnimation(.easeOut(duration: 0.2)) { open = open == i ? nil : i }
                    }
                }
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .roundedBorder(violet.opacity(0.12), radius: 20)
        }
    }
}

private struct FaqTile: View {
    let question: String
    let answer: String
    let open: Bool
    let onTap: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onTap) {
                HStack(spacing: 12) {
                    badge("Q", [violet, purple])
                    Text(question.tr)
                        .font(.poppins(14.5, .semibold))
                        .foregroundStyle(Brand.ink)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Image(systemName: "chevron.down")
                        .foregroundStyle(violet)
                        .rotationEffect(.degrees(open ? 180 : 0))
                }
                .padding(EdgeInsets(top: 14, leading: 14, bottom: 14, trailing: 10))
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if open {
                HStack(alignment: .top, spacing: 12) {
                    badge("A", [Brand.green, Brand.greenDark])
                    Text(answer.tr)
                        .font(.poppins(14))
                        .lineSpacing(4)
                        .foregroundStyle(Color(argb: 0xFF4B5563))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(EdgeInsets(top: 12, leading: 14, bottom: 16, trailing: 14))
                .background(violet.opacity(0.04))
            }
        }
        .overlay(alignment: .bottom) { violet.opacity(0.1).frame(height: 1) }
    }

    private func badge(_ letter: String, _ colors: [Color]) -> some View {
        Text(verbatim: letter)
            .font(.poppins(14, .heavy))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(Brand.gradient(colors), in: RoundedRectangle(cornerRadius: 10))
    }
}
