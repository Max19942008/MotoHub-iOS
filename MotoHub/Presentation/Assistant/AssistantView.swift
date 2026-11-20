import SwiftUI

/// The AI assistant page, laid out like the Android app's.
struct AssistantView: View {
    @State private var model: AssistantViewModel
    @FocusState private var inputFocused: Bool
    @State private var reporting: ChatMessage? = nil

    @Environment(Router.self) private var router

    init(repository: any AssistantRepository) {
        _model = State(initialValue: AssistantViewModel(repository: repository))
    }

    var body: some View {
        VStack(spacing: 0) {
            if model.messages.isEmpty {
                ScrollView { intro.padding(24) }
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(model.messages) { message in
                                MessageRow(
                                    message: message,
                                    reported: model.reported.contains(message.id),
                                    onReport: { reporting = message },
                                    onSource: open
                                )
                                .id(message.id)
                            }
                            if model.isSending {
                                TypingBubble().id("typing")
                            }
                        }
                        .padding(12)
                    }
                    .scrollDismissesKeyboard(.interactively)
                    .onChange(of: model.messages.count) { _, _ in
                        if let last = model.messages.last?.id {
                            withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo(last, anchor: .bottom) }
                        }
                    }
                    .onChange(of: model.isSending) { _, sending in
                        if sending { withAnimation(.easeOut(duration: 0.25)) { proxy.scrollTo("typing", anchor: .bottom) } }
                    }
                }
            }
            inputBar
        }
        .background(Brand.page)
        .sheet(item: $reporting) { answer in
            ReportSheet { reason, comment in
                try await model.report(answer, reason: reason, comment: comment)
                router.toast("Rahmat! Shikoyatingiz qabul qilindi, uni ko'rib chiqamiz.".tr)
            }
        }
    }

    private var intro: some View {
        VStack(spacing: 0) {
            Image(systemName: "sparkles").font(.system(size: 50)).foregroundStyle(Brand.green).padding(.top, 24)
            Text("MOTOPRESTO AI yordamchi".tr)
                .font(.poppins(22, .medium)).foregroundStyle(Brand.ink).multilineTextAlignment(.center).padding(.top, 12)
            Text("O'zbek, rus yoki ingliz tilida yozing — men MOTOPRESTO e'lonlaridan mos mototsikl va qismlarni topib beraman. Javoblar sun'iy intellekt tomonidan yaratiladi va xato bo'lishi mumkin.".tr)
                .font(.poppins(14)).foregroundStyle(Brand.muted).multilineTextAlignment(.center).padding(.top, 8)
            VStack(spacing: 8) {
                ForEach(model.suggestions, id: \.self) { s in
                    Button {
                        inputFocused = false
                        Task { await model.send(s.tr) }
                    } label: {
                        Text(s.tr)
                            .font(.poppins(15, .bold))
                            .foregroundStyle(Brand.green)
                            .multilineTextAlignment(.leading)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 14)
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Brand.green, lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 24)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 4) {
            TextField("", text: $model.draft, prompt: Text("Mototsikl yoki qism haqida so'rang…".tr), axis: .vertical)
                .font(.poppins(15))
                .lineLimit(1...4)
                .focused($inputFocused)
                .submitLabel(.send)
                .onSubmit(send)
                .onChange(of: model.draft) { _, v in if v.count > 1000 { model.draft = String(v.prefix(1000)) } }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(argb: 0xFFE7E8EA), in: RoundedRectangle(cornerRadius: 24))
                .accessibilityIdentifier("ai-input")
            Button(action: send) {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(.white)
                    .frame(width: 44, height: 44)
                    .background(model.isSending ? Brand.green.opacity(0.4) : Brand.green, in: Circle())
            }
            .buttonStyle(.plain)
            .disabled(model.isSending)
            .accessibilityLabel("Yuborish".tr)
            .accessibilityIdentifier("ai-send")
        }
        .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 8))
        .background(.white)
        .overlay(alignment: .top) { Brand.line.frame(height: 1) }
    }

    private func send() {
        // Close the keyboard so the answer is visible.
        inputFocused = false
        Task { await model.send() }
    }

    private func open(_ source: AISource) {
        switch source.kind {
        case .motorbike: router.push(.motorbikeID(source.id))
        case .part: router.push(.partID(source.id))
        case .article, .none: router.toast("Maqolalarni saytda o'qishingiz mumkin.".tr)
        }
    }
}

private struct MessageRow: View {
    let message: ChatMessage
    let reported: Bool
    let onReport: () -> Void
    let onSource: (AISource) -> Void

    var body: some View {
        let isUser = message.role == .user
        let isError = message.role == .error
        HStack {
            if isUser { Spacer(minLength: 40) }
            VStack(alignment: isUser ? .trailing : .leading, spacing: 6) {
                Text(message.text.tr)
                    .font(.poppins(15))
                    .lineSpacing(4)
                    .textSelection(.enabled)
                    .foregroundStyle(isUser ? .white : isError ? Color(argb: 0xFF410002) : Brand.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(
                        isUser ? Brand.green : isError ? Color(argb: 0xFFFFDAD6) : Color(argb: 0xFFE7E8EA),
                        in: UnevenRoundedRectangle(topLeadingRadius: 16, bottomLeadingRadius: isUser ? 16 : 4,
                                                   bottomTrailingRadius: isUser ? 4 : 16, topTrailingRadius: 16)
                    )
                ForEach(Array(message.sources.enumerated()), id: \.offset) { i, source in
                    SourceCard(index: i + 1, source: source) { onSource(source) }
                }
                if !isUser, !isError {
                    HStack(spacing: 4) {
                        Text("AI javobi, xato bo'lishi mumkin".tr)
                        if reported {
                            Text("· Shikoyat yuborildi".tr).padding(8)
                        } else {
                            Button(action: onReport) {
                                Label("Shikoyat qilish".tr, systemImage: "flag").foregroundStyle(Color(argb: 0xFFBA1A1A))
                            }
                            .buttonStyle(.plain)
                            .padding(8)
                            .accessibilityIdentifier("ai-report")
                        }
                    }
                    .font(.poppins(12))
                    .foregroundStyle(Brand.muted)
                }
            }
            .frame(maxWidth: UIScreen.main.bounds.width * 0.85, alignment: isUser ? .trailing : .leading)
            if !isUser { Spacer(minLength: 0) }
        }
        .padding(.bottom, 12)
    }
}

private struct SourceCard: View {
    let index: Int
    let source: AISource
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 10) {
                CoverImage(path: source.imagePath).frame(width: 72, height: 64)
                VStack(alignment: .leading, spacing: 0) {
                    Text(verbatim: "[\(index)] \(source.title)").font(.poppins(14, .semibold)).foregroundStyle(Brand.ink).lineLimit(1)
                    if let subtitle = source.subtitle {
                        Text(subtitle.components(separatedBy: " · ").map { Formatting.label($0).tr }.joined(separator: " · "))
                            .font(.poppins(12)).foregroundStyle(Brand.muted).lineLimit(1)
                    }
                    if let price = source.price {
                        Text(Formatting.price(price, currency: source.currency)).font(.poppins(14, .bold)).foregroundStyle(Brand.green)
                    }
                }
                .padding(.vertical, 8)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(Brand.muted).padding(.trailing, 8)
            }
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .roundedBorder(Brand.line, radius: 20)
        }
        .buttonStyle(.plain)
    }
}

private struct TypingBubble: View {
    var body: some View {
        HStack {
            HStack(spacing: 10) {
                ProgressView().controlSize(.small).tint(Brand.green)
                Text("Qidiryapman…".tr).font(.poppins(14)).foregroundStyle(Brand.ink)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(argb: 0xFFE7E8EA), in: RoundedRectangle(cornerRadius: 16))
            Spacer()
        }
        .padding(.bottom, 12)
    }
}

/// Asks why the answer is bad and sends the report; stays open on errors.
private struct ReportSheet: View {
    let submit: (AIReportReason, String) async throws -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var reason: AIReportReason? = nil
    @State private var comment = ""
    @State private var sending = false
    @State private var errorText: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("AI javobi ustidan shikoyat".tr).font(.poppins(22)).foregroundStyle(Brand.ink)
            Text("Bu javobda nima noto'g'ri?".tr).font(.poppins(14)).foregroundStyle(Brand.ink).padding(.top, 4)
            VStack(alignment: .leading, spacing: 0) {
                ForEach(AIReportReason.allCases) { r in
                    Button { reason = r } label: {
                        HStack(spacing: 14) {
                            Image(systemName: reason == r ? "largecircle.fill.circle" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(reason == r ? Brand.green : Brand.muted)
                            Text(r.label.tr).font(.poppins(15)).foregroundStyle(Brand.ink)
                            Spacer()
                        }
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
            TextField("", text: $comment, prompt: Text("Izoh (ixtiyoriy)".tr), axis: .vertical)
                .font(.poppins(15))
                .lineLimit(1...3)
                .onChange(of: comment) { _, v in if v.count > 500 { comment = String(v.prefix(500)) } }
                .padding(14)
                .roundedBorder(Color(argb: 0xFF79747E), radius: 4)
                .padding(.top, 8)
            if let errorText {
                Text(errorText.tr).font(.poppins(13)).foregroundStyle(Color(argb: 0xFFBA1A1A)).padding(.top, 8)
            }
            Button(action: send) {
                Group {
                    if sending { ProgressView().tint(.white) } else { Text("Yuborish".tr).font(.poppins(15, .bold)) }
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(reason == nil ? Brand.green.opacity(0.4) : Brand.green, in: Capsule())
            }
            .buttonStyle(.plain)
            .disabled(reason == nil || sending)
            .padding(.top, 16)
        }
        .padding(20)
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func send() {
        guard let reason, !sending else { return }
        sending = true
        errorText = nil
        Task {
            do {
                try await submit(reason, comment)
                dismiss()
            } catch {
                errorText = error.localizedDescription
            }
            sending = false
        }
    }
}
