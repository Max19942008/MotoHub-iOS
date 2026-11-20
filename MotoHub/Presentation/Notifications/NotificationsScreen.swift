import SwiftUI

/// The site's /notifications page: list, "Mark all read", delete one.
struct NotificationsScreen: View {
    @Environment(AppContainer.self) private var app
    @Environment(Router.self) private var router
    @State private var items: [AppNotification]? = nil
    @State private var unread = 0
    @State private var error: String? = nil

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Bildirishnomalar".tr).font(.poppins(22, .heavy)).foregroundStyle(Brand.ink)
                Button { Task { await run { try await app.notifications.markNotificationsRead(ids: nil) } } } label: {
                    Label("Hammasini o'qilgan deb belgilash".tr, systemImage: "checkmark.circle")
                        .font(.poppins(13, .semibold))
                        .foregroundStyle(unread == 0 ? Brand.muted : Brand.green)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(unread == 0 ? Brand.line : Brand.green, lineWidth: 1.5))
                }
                .buttonStyle(.plain)
                .disabled(unread == 0)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 8)
                Group {
                    if let error {
                        MessageView(systemImage: "icloud.slash", message: error) { Task { await load() } }
                    } else if let items {
                        if items.isEmpty {
                            VStack(spacing: 8) {
                                Image(systemName: "bell").font(.system(size: 50)).foregroundStyle(Color(argb: 0xFF999999))
                                Text("Bildirishnomalar yo'q".tr).font(.poppins(14)).foregroundStyle(Color(argb: 0xFF999999))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 64)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(items) { row($0) }
                            }
                        }
                    } else {
                        LoadingView().frame(height: 240)
                    }
                }
                .padding(.top, 16)
            }
            .padding(EdgeInsets(top: 20, leading: 16, bottom: 40, trailing: 16))
        }
        .background(Color.white)
        .refreshable { await load() }
        .sitePage(back: true)
        .task { await load() }
    }

    private func row(_ n: AppNotification) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 6) {
                    chip(n.type, Brand.green, outlined: true)
                    if n.unread { chip("Yangi", .red, outlined: false) }
                }
                Text(n.title).font(.poppins(14, .semibold)).foregroundStyle(Brand.ink).padding(.top, 6)
                if let d = n.description, !d.isEmpty {
                    Text(d).font(.poppins(13)).foregroundStyle(Color(argb: 0xFF666666)).padding(.top, 3)
                }
                Text(Formatting.timeAgo(n.createdAt).tr).font(.poppins(12)).foregroundStyle(Color(argb: 0xFFAAAAAA)).padding(.top, 5)
            }
            Spacer(minLength: 0)
            Button { Task { await run { try await app.notifications.deleteNotification(id: n.id) } } } label: {
                Image(systemName: "trash").font(.system(size: 17)).foregroundStyle(Brand.muted).frame(width: 40, height: 40)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("O'chirish".tr)
        }
        .padding(EdgeInsets(top: 14, leading: 16, bottom: 14, trailing: 6))
        .background(n.unread ? Brand.green.opacity(0.06) : .white, in: RoundedRectangle(cornerRadius: 8))
        .roundedBorder(Color(argb: 0xFFEEEEEE), radius: 8)
    }

    private func chip(_ text: String, _ color: Color, outlined: Bool) -> some View {
        Text(text.tr)
            .font(.poppins(11.5, .semibold))
            .foregroundStyle(outlined ? color : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 3)
            .background(outlined ? .clear : color, in: Capsule())
            .overlay(Capsule().strokeBorder(color))
    }

    private func load() async {
        do {
            let result = try await app.notifications.notifications()
            items = result.items
            unread = result.unread
            error = nil
        } catch {
            self.error = error.localizedDescription
        }
    }

    private func run(_ action: () async throws -> Void) async {
        do {
            try await action()
            await load()
        } catch {
            router.toast(error.localizedDescription.tr)
        }
    }
}
