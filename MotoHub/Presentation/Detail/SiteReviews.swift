import SwiftUI

/// "Izohlar" list + "Fikringizni qoldiring" box.
struct SiteReviews: View {
    let group: String
    let refID: String

    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @Environment(SessionStore.self) private var session
    @State private var comments: PagedResult<Comment>? = nil
    @State private var text = ""
    @State private var sending = false

    private var canSend: Bool { !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    var body: some View {
        VStack(spacing: 0) {
            if let comments, !comments.items.isEmpty {
                list(comments).padding(.bottom, 28)
            }
            form
        }
        .task { await load() }
    }

    private func load() async {
        comments = try? await app.listings.comments(refID: refID, page: 1)
    }

    private func list(_ page: PagedResult<Comment>) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "star.fill").foregroundStyle(Color(argb: 0xFFFFC107))
                Text("\(page.total) Izohlar".tr).font(.poppins(17, .bold)).foregroundStyle(Brand.ink)
            }
            .padding(.bottom, 16)
            ForEach(page.items) { c in
                VStack(alignment: .leading, spacing: 10) {
                    HStack(spacing: 12) {
                        Avatar(path: c.authorImage, size: 40)
                        VStack(alignment: .leading, spacing: 0) {
                            Text(c.author).font(.poppins(14, .semibold)).foregroundStyle(Brand.ink)
                            if let date = c.createdAt {
                                Text(Formatting.longDate(date)).font(.poppins(12)).foregroundStyle(Color(argb: 0xFF9CA3AF))
                            }
                        }
                    }
                    Text(c.content).font(.poppins(14)).lineSpacing(4).foregroundStyle(Color(argb: 0xFF4B5563))
                }
                .padding(.vertical, 16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .top) { Color(argb: 0xFFF0F0F0).frame(height: 1) }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.white, in: RoundedRectangle(cornerRadius: 24))
        .roundedBorder(Color(argb: 0xFFF0F0F0), radius: 24)
    }

    private var form: some View {
        VStack(spacing: 0) {
            Brand.gradient([Color(argb: 0xFF3B82F6), Color(argb: 0xFF8B5CF6), Color(argb: 0xFF3B82F6)]).frame(height: 4)
            VStack(alignment: .leading, spacing: 0) {
                Text("Fikringizni qoldiring".tr)
                    .font(.poppins(28, .heavy))
                    .gradientText([Color(argb: 0xFF3B82F6), Color(argb: 0xFF8B5CF6)])
                LinearGradient(colors: [Color(argb: 0xFF3B82F6), .clear], startPoint: .leading, endPoint: .trailing)
                    .frame(width: 60, height: 4)
                    .padding(.top, 8)
                    .padding(.bottom, 30)
                Text("👉  Tajriba".tr).font(.poppins(17, .bold)).foregroundStyle(Brand.ink)
                TextField("", text: $text, axis: .vertical)
                    .font(.poppins(15))
                    .lineLimit(5...8)
                    .padding(16)
                    .background(Color(argb: 0xFFFAFAFA), in: RoundedRectangle(cornerRadius: 16))
                    .roundedBorder(Color(argb: 0xFFE0E0E0), radius: 16, width: 2)
                    .padding(.top, 18)
                Button { Task { await submit() } } label: {
                    HStack(spacing: 18) {
                        Text((sending ? "YUBORILMOQDA…" : "SHARH YUBORISH").tr)
                            .font(.poppins(16, .heavy))
                            .kerning(1)
                            .foregroundStyle(canSend ? .white : Color(argb: 0xFFBDBDBD))
                        Image(systemName: "arrow.up.right").font(.system(size: 22, weight: .semibold)).foregroundStyle(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 62)
                    .background(canSend ? Color(argb: 0xFF3B82F6) : Color(argb: 0xFFE5E7EB), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
                .disabled(!canSend)
                .padding(.top, 30)
            }
            .padding(EdgeInsets(top: 40, leading: 30, bottom: 40, trailing: 30))
        }
        .background(LinearGradient(colors: [.white, Color(argb: 0xFFF0F9FF)], startPoint: .leading, endPoint: .trailing))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .roundedBorder(Color(argb: 0xFFE0F2FE), radius: 24, width: 2)
    }

    private func submit() async {
        let content = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty, !sending else { return }
        guard session.isLoggedIn else {
            router.toast("Avval tizimga kiring".tr)
            return
        }
        sending = true
        defer { sending = false }
        do {
            try await app.listings.addComment(group: group, refID: refID, content: content)
            text = ""
            await load()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}
