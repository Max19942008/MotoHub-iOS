import SwiftUI

struct AssistantView: View {
    @State private var model: AssistantViewModel
    @FocusState private var inputFocused: Bool

    init(repository: any AssistantRepository) {
        _model = State(initialValue: AssistantViewModel(repository: repository))
    }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 14) {
                    if model.messages.isEmpty {
                        intro
                    }
                    ForEach(model.messages) { message in
                        MessageRow(message: message).id(message.id)
                    }
                    if model.isSending {
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Yordamchi javob yozmoqda…").font(.footnote).foregroundStyle(.secondary)
                        }
                        .id("typing")
                    }
                }
                .padding(16)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: model.messages.count) { _, _ in
                if let last = model.messages.last?.id {
                    withAnimation { proxy.scrollTo(last, anchor: .bottom) }
                }
            }
            .onChange(of: model.isSending) { _, sending in
                if sending { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
        .safeAreaInset(edge: .bottom) { inputBar }
        .navigationTitle("AI yordamchi")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if !model.messages.isEmpty {
                    Button("Yangi suhbat", systemImage: "square.and.pencil") { model.clear() }
                        .disabled(model.isSending)
                }
            }
        }
    }

    private var intro: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 36))
                .foregroundStyle(Color.accentColor)
            Text("Nima qidiryapsiz?").font(.title2.bold())
            Text("MotoHub e’lonlaridan mos mototsikl, qism yoki aksessuar topib beraman. O‘zbekcha, ruscha yoki inglizcha yozing.")
                .foregroundStyle(.secondary)
            ForEach(model.suggestions, id: \.self) { suggestion in
                Button {
                    inputFocused = false
                    Task { await model.send(suggestion) }
                } label: {
                    Text(suggestion)
                        .font(.subheadline)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 24)
    }

    private var inputBar: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Savolingizni yozing…", text: $model.draft, axis: .vertical)
                .lineLimit(1...4)
                .focused($inputFocused)
                .accessibilityIdentifier("ai-input")
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 20))
                .onSubmit { send() }
            Button(action: send) {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 34))
            }
            .disabled(!model.canSend)
            .accessibilityLabel("Yuborish")
            .accessibilityIdentifier("ai-send")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.bar)
    }

    private func send() {
        // Close the keyboard so the answer and the tab bar are visible.
        inputFocused = false
        Task { await model.send() }
    }
}

private struct MessageRow: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 18))
                    .foregroundStyle(Color.white)
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 10) {
                Text(message.text)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.secondarySystemBackground), in: RoundedRectangle(cornerRadius: 18))
                ForEach(Array(message.sources.enumerated()), id: \.offset) { index, source in
                    SourceCard(number: index + 1, source: source)
                }
            }
            .padding(.trailing, 24)
        case .error:
            Label(message.text, systemImage: "exclamationmark.circle")
                .font(.subheadline)
                .foregroundStyle(Color.red)
        }
    }
}

/// A cited listing; tapping opens it (articles open on the website).
private struct SourceCard: View {
    let number: Int
    let source: AISource

    var body: some View {
        switch source.kind {
        case .motorbike:
            NavigationLink(value: Route.motorbike(id: source.id)) { card }.buttonStyle(.plain)
        case .part:
            NavigationLink(value: Route.part(id: source.id)) { card }.buttonStyle(.plain)
        case .article, .none:
            if let url = AppConfig.articleURL(id: source.id, category: source.articleCategory) {
                Link(destination: url) { card }.buttonStyle(.plain)
            } else {
                card
            }
        }
    }

    private var card: some View {
        HStack(spacing: 12) {
            RemoteImage(path: source.imagePath, iconSize: 18)
                .frame(width: 56, height: 56)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 2) {
                Text("[\(number)] \(source.title)").font(.subheadline.weight(.semibold)).lineLimit(2)
                if let subtitle = source.subtitle, !subtitle.isEmpty {
                    Text(subtitle).font(.caption).foregroundStyle(.secondary).lineLimit(1)
                }
                if let price = source.price {
                    Text(Formatting.price(price, currency: source.currency))
                        .font(.caption.weight(.bold))
                        .foregroundStyle(Color.accentColor)
                }
            }
            Spacer(minLength: 0)
            Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(Color(.tertiarySystemBackground), in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color(.separator), lineWidth: 0.5))
    }
}
