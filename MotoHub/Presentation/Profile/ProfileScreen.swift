import SwiftUI

/// Login / signup for guests, "Mening sahifam" for members.
struct ProfileScreen: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        if let member = session.member {
            MyPageScreen(member: member)
        } else {
            AuthForm()
        }
    }
}

private let violet = Color(argb: 0xFF667EEA)
private let purple = Color(argb: 0xFF764BA2)
private let pink = Color(argb: 0xFFF093FB)
private let slate = Color(argb: 0xFF64748B)
private let dark = Color(argb: 0xFF1E293B)

private struct AuthForm: View {
    private enum Field { case nick, password, phone }

    @Environment(SessionStore.self) private var session
    @State private var signup = false
    @State private var nick = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var isAgent = false
    @State private var busy = false
    @State private var showPassword = false
    @State private var error: String? = nil
    /// Field errors appear after the first submit, like the site's form validation.
    @State private var validated = false
    @FocusState private var focus: Field?

    private var nickError: String? {
        let n = nick.trimmingCharacters(in: .whitespaces).count
        return (3...20).contains(n) ? nil : "3–20 ta belgi bo'lishi kerak"
    }

    private var passwordError: String? {
        (5...30).contains(password.count) ? nil : "5–30 ta belgi bo'lishi kerak"
    }

    private var phoneError: String? {
        guard signup else { return nil }
        let n = phone.trimmingCharacters(in: .whitespaces).count
        return (7...20).contains(n) ? nil : "Telefon raqamni to'g'ri kiriting"
    }

    // The site keeps LOGIN / SIGN UP disabled until the fields are filled.
    private var canSubmit: Bool { !busy && !nick.isEmpty && !password.isEmpty && (!signup || !phone.isEmpty) }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                card.padding(EdgeInsets(top: 24, leading: 16, bottom: 40, trailing: 16))
                SiteFooter()
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(LinearGradient(colors: [Color(argb: 0xFFF7F8FE), Color(argb: 0xFFFBF7FD), Color(argb: 0xFFF4FBFE)],
                                   startPoint: .topLeading, endPoint: .bottomTrailing))
    }

    private var card: some View {
        VStack(spacing: 0) {
            Image("logo").resizable().scaledToFit().frame(height: 64)
                .shadow(color: violet.opacity(0.3), radius: 6, y: 4)
            Text("SIZNING MOTOTSIKL BOZORINGIZ".tr)
                .font(.poppins(12.5, .semibold)).kerning(1).foregroundStyle(slate)
                .multilineTextAlignment(.center)
                .padding(.top, 12)
            Text((signup ? "Hisob yaratish" : "Xush kelibsiz!").tr)
                .font(.poppins(28, .heavy)).kerning(-1).foregroundStyle(dark)
                .padding(.top, 28)
            Text((signup ? "MOTOPRESTO'ga qo'shiling va mototsikl sotib olishni yoki sotishni boshlang"
                         : "Davom etish uchun MOTOPRESTO'ga kiring").tr)
                .font(.poppins(14, .medium)).lineSpacing(4).foregroundStyle(slate)
                .multilineTextAlignment(.center)
                .padding(.top, 10)
            VStack(spacing: 20) {
                input("Taxallus", icon: "person.fill", error: nickError) {
                    TextField("", text: $nick, prompt: prompt("Taxallusingizni kiriting"))
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .nick)
                        .submitLabel(.next)
                        .onSubmit { focus = .password }
                }
                input("Parol", icon: "lock.fill", error: passwordError) {
                    HStack {
                        Group {
                            if showPassword {
                                TextField("", text: $password, prompt: prompt("Parolingizni kiriting"))
                            } else {
                                SecureField("", text: $password, prompt: prompt("Parolingizni kiriting"))
                            }
                        }
                        .textContentType(signup ? UITextContentType.newPassword : UITextContentType.password)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focus, equals: .password)
                        .submitLabel(signup ? .next : .go)
                        .onSubmit { if signup { focus = .phone } else { submit() } }
                        Button { showPassword.toggle() } label: {
                            Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill").foregroundStyle(Color(argb: 0xFF94A3B8))
                        }
                        .buttonStyle(.plain)
                    }
                }
                if signup {
                    input("Phone Number", icon: "phone.fill", error: phoneError) {
                        TextField("", text: $phone, prompt: prompt("Telefon raqamingizni kiriting"))
                            .textContentType(.telephoneNumber)
                            .keyboardType(.phonePad)
                            .focused($focus, equals: .phone)
                    }
                    accountType
                }
            }
            .disabled(busy)
            .padding(.top, 28)
            if let error {
                Text(error.tr).font(.poppins(14)).foregroundStyle(.red).multilineTextAlignment(.center).padding(.top, 14)
            }
            Button(action: submit) {
                Group {
                    if busy {
                        ProgressView().tint(.white)
                    } else {
                        Text((signup ? "SIGN UP" : "LOGIN").tr).font(.poppins(16, .bold)).kerning(1).foregroundStyle(.white)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Brand.gradient([violet, purple, pink]), in: RoundedRectangle(cornerRadius: 14))
                .shadow(color: violet.opacity(0.3), radius: 12, y: 8)
            }
            .buttonStyle(.plain)
            .disabled(!canSubmit)
            .opacity(canSubmit ? 1 : 0.5)
            .padding(.top, 26)
            HStack(spacing: 4) {
                Text((signup ? "Hisobingiz bormi? " : "Hisobingiz yo'qmi? ").tr).font(.poppins(14)).foregroundStyle(slate)
                Button {
                    signup.toggle()
                    error = nil
                    validated = false
                } label: {
                    Text((signup ? "KIRISH" : "RO'YXATDAN O'TISH").tr).font(.poppins(14, .bold)).foregroundStyle(violet)
                }
                .buttonStyle(.plain)
                .disabled(busy)
            }
            .padding(.top, 18)
            Link(destination: AppConfig.privacyPolicyURL) {
                Text("Maxfiylik siyosati".tr).font(.poppins(14, .medium)).foregroundStyle(slate)
            }
            .padding(.top, 14)
        }
        .padding(EdgeInsets(top: 36, leading: 22, bottom: 26, trailing: 22))
        .frame(maxWidth: .infinity)
        .background(Brand.gradient([.white, Color(argb: 0xFFF8F9FF)]), in: RoundedRectangle(cornerRadius: 24))
        .roundedBorder(violet.opacity(0.1), radius: 24)
        .shadow(color: violet.opacity(0.15), radius: 30, y: 20)
    }

    private func prompt(_ text: String) -> Text {
        Text(text.tr).foregroundStyle(Color(argb: 0xFFB4BCC8))
    }

    /// Outlined field with the label sitting on its top border.
    private func input<F: View>(_ label: String, icon: String, error: String?, @ViewBuilder field: () -> F) -> some View {
        let showError = validated && error != nil
        return VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: icon).foregroundStyle(violet).frame(width: 22)
                field().font(.poppins(15))
            }
            .padding(.horizontal, 16)
            .frame(height: 58)
            .background(.white.opacity(0.8), in: RoundedRectangle(cornerRadius: 12))
            .roundedBorder(showError ? .red : violet.opacity(0.12), radius: 12, width: 2)
            .overlay(alignment: .topLeading) {
                Text(label.tr)
                    .font(.poppins(12, .semibold))
                    .foregroundStyle(Color(argb: 0xFF475569))
                    .padding(.horizontal, 4)
                    .background(.white)
                    .offset(x: 12, y: -9)
            }
            if showError, let error {
                Text(error.tr).font(.poppins(12)).foregroundStyle(.red).padding(.leading, 12)
            }
        }
    }

    private var accountType: some View {
        VStack(spacing: 14) {
            Text("Men sifatida ro'yxatdan o'tmoqchiman:".tr)
                .font(.poppins(14, .bold)).foregroundStyle(dark).multilineTextAlignment(.center)
            HStack(spacing: 12) {
                typeButton("FOYDALANUVCHI", icon: "person.fill", agent: false)
                typeButton("AGENT", icon: "scooter", agent: true)
            }
        }
        .padding(16)
        .background(Brand.gradient([violet.opacity(0.05), purple.opacity(0.05)]), in: RoundedRectangle(cornerRadius: 16))
        .roundedBorder(violet.opacity(0.1), radius: 16, width: 2)
    }

    private func typeButton(_ label: String, icon: String, agent: Bool) -> some View {
        let active = isAgent == agent
        return Button { isAgent = agent } label: {
            HStack(spacing: 6) {
                Image(systemName: icon).font(.system(size: 17))
                Text(label.tr).font(.poppins(13.5, .bold)).kerning(0.5).lineLimit(1).minimumScaleFactor(0.6)
            }
            .foregroundStyle(active ? .white : violet)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(active ? Brand.gradient([violet, purple]) : Brand.gradient([.white.opacity(0.8), .white.opacity(0.8)]),
                        in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(active ? .clear : violet.opacity(0.3), lineWidth: 2))
            .shadow(color: active ? violet.opacity(0.3) : .clear, radius: 8, y: 4)
        }
        .buttonStyle(.plain)
    }

    private func submit() {
        validated = true
        guard nickError == nil, passwordError == nil, phoneError == nil, !busy else { return }
        focus = nil
        busy = true
        error = nil
        Task {
            defer { busy = false }
            do {
                if signup {
                    try await session.signup(SignupForm(nick: nick, password: password, phone: phone, isAgent: isAgent))
                } else {
                    try await session.login(nick: nick, password: password)
                }
            } catch {
                self.error = error.localizedDescription
            }
        }
    }
}
