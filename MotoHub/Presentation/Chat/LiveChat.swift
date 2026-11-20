import SwiftUI

private let divider = Color(argb: 0xD4CDCDCD)

/// The website's live chat (ignition Chat.tsx + chat.scss): a round white
/// button bottom right, on the same line as the AI Assistant pill, and a light
/// blue "Online Chat" panel that slides in from the right above it.
/// Fills its parent; put it over the page.
struct LiveChat: View {
    @Environment(AppContainer.self) private var app
    @Environment(SessionStore.self) private var session
    @Environment(Router.self) private var router
    @Environment(\.scenePhase) private var scenePhase
    @State private var open = false
    @State private var text = ""
    @FocusState private var focused: Bool

    private var chat: ChatService { app.chat }

    var body: some View {
        GeometryReader { geo in
            // Site: bottom 76px, height min(500px, 100dvh - 150px), 8px from the edges.
            let height = max(0, min(500, geo.size.height - 76 - 14))
            ZStack(alignment: .bottomTrailing) {
                Color.clear
                frame
                    .frame(height: height)
                    .padding(.horizontal, 8)
                    .padding(.bottom, 76)
                    .offset(x: open ? 0 : geo.size.width * 1.1)
                    .animation(.easeInOut(duration: 0.7), value: open)
                    .allowsHitTesting(open)
                ChatButton(open: open, action: toggle)
                    .padding(.trailing, 16)
                    .padding(.bottom, 16)
            }
        }
        // Like the Android app, the panel and its button move up above the keyboard.
        .onAppear { chat.start(memberID: session.member?.id) }
        .onChange(of: session.member?.id) { _, id in chat.memberChanged(id) }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { chat.pause() } else if phase == .active { chat.resume() }
        }
    }

    private func toggle() {
        open.toggle()
        focused = open // the site focuses the input on open
    }

    private func send() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return router.toast("Message is empty!".tr) }
        guard chat.send(trimmed) else { return router.toast("Chat is reconnecting, please try again in a moment.".tr) }
        text = ""
    }

    private var frame: some View {
        let me = session.member?.id
        return VStack(spacing: 0) {
            // .chat-top: 103px, title + online counter
            HStack(alignment: .top, spacing: 0) {
                Text((chat.connected ? "Online Chat" : "Connecting…").tr)
                    // The site asks for Nunito, which it never loads, so phones draw it in serif.
                    .font(.system(size: 30, design: .serif))
                    .foregroundStyle(.black)
                OnlineBadge(count: chat.onlineUsers).offset(x: 8, y: -4)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 103)
            .overlay(alignment: .bottom) { divider.frame(height: 1) }
            // .chat-content: messages; follows new ones like react-scrollable-feed.
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        Text("Welcome to Live chat!".tr).font(.poppins(16)).foregroundStyle(.black)
                        ForEach(chat.messages) { m in
                            Group {
                                if let me, m.member?.id == me {
                                    MyMessage(text: m.text)
                                } else {
                                    TheirMessage(message: m)
                                }
                            }
                            .id(m.id)
                        }
                    }
                    .padding(17)
                }
                .defaultScrollAnchor(.bottom)
                .onChange(of: chat.messages.count) { _, _ in
                    if let last = chat.messages.last?.id { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            // .chat-bott: 103px, input + send
            HStack(spacing: 14) {
                TextField("", text: $text, prompt: Text("Type message".tr))
                    .font(.poppins(16))
                    .focused($focused)
                    .submitLabel(.send)
                    .onSubmit {
                        send()
                        focused = true // keep typing, like the site
                    }
                    .onChange(of: text) { _, v in if v.count > ChatService.maxTextLength { text = String(v.prefix(ChatService.maxTextLength)) } }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 13)
                    .background(Color(argb: 0xFFF7F7F7), in: Capsule())
                    .overlay(Capsule().strokeBorder(focused ? Color(argb: 0xFF257677) : .clear, lineWidth: 2))
                Button(action: send) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                        .frame(width: 50, height: 50)
                        .background(Color(argb: 0xFF33C1C1), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Send message")
            }
            .padding(.horizontal, 17)
            .frame(height: 103)
            .overlay(alignment: .top) { divider.frame(height: 1) }
        }
        .background(Color(argb: 0xFFE9F3FF))
        .clipShape(RoundedRectangle(cornerRadius: 34))
        .shadow(color: Color(argb: 0x4D323232), radius: 8)
    }
}

/// .chat-button: 48px white circle, soft shadow; chat icon / collapse icon.
private struct ChatButton: View {
    let open: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: open ? "arrow.down.right.and.arrow.up.left" : "message.badge.filled.fill")
                .font(.system(size: 21))
                .foregroundStyle(.black)
                .frame(width: 48, height: 48)
                .background(.white, in: Circle())
                .shadow(color: Color(argb: 0x33323232), radius: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(open ? "Close chat" : "Open chat")
    }
}

/// The site's RippleBadge: light blue pill with the online count and a teal
/// ring that keeps pulsing outwards. Hidden at 0, like MUI.
private struct OnlineBadge: View {
    let count: Int
    @State private var pulse = false

    var body: some View {
        ZStack {
            if count > 0 {
                Circle()
                    .strokeBorder(Color(argb: 0xFF32C2C1), lineWidth: 2)
                    .frame(width: 20, height: 20)
                    .scaleEffect(pulse ? 2.4 : 0.8)
                    .opacity(pulse ? 0 : 1)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false), value: pulse)
                    .onAppear { pulse = true }
                Text(verbatim: "\(count)")
                    .font(.poppins(12, .medium))
                    .foregroundStyle(Color(argb: 0xD62C40BD))
                    .padding(.horizontal, 6)
                    .frame(minWidth: 20, minHeight: 20)
                    .background(Color(argb: 0x8FB4DCFF), in: Capsule())
            }
        }
        .frame(width: 20, height: 20)
    }
}

/// .msg-right: my messages, mint bubble on the right.
private struct MyMessage: View {
    let text: String

    var body: some View {
        HStack {
            Spacer(minLength: 40)
            Text(text)
                .font(.poppins(16))
                .foregroundStyle(.black)
                .padding(9)
                .background(Color(argb: 0xFFD0ECE8),
                            in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 20, bottomTrailingRadius: 0, topTrailingRadius: 20))
        }
    }
}

/// Avatar, nick (Guest when logged out) and a grey .msg-left bubble.
private struct TheirMessage: View {
    let message: LiveChatMessage

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Avatar(path: message.member?.imagePath, size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text(message.member?.nick ?? "Guest".tr).font(.poppins(12)).foregroundStyle(Brand.muted)
                Text(message.text)
                    .font(.poppins(16))
                    .foregroundStyle(.white)
                    .padding(9)
                    .background(Color(argb: 0xFF9FA7AC),
                                in: UnevenRoundedRectangle(topLeadingRadius: 20, bottomLeadingRadius: 0, bottomTrailingRadius: 20, topTrailingRadius: 20))
            }
            Spacer(minLength: 20)
        }
    }
}
