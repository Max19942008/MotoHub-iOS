import SwiftUI

/// Sign in / sign up for guests; profile, logout and account deletion for members.
struct ProfileView: View {
    @Environment(SessionStore.self) private var session

    var body: some View {
        Group {
            if let member = session.member {
                MemberProfileView(member: member)
            } else {
                AuthFormView()
            }
        }
        .navigationTitle(session.isLoggedIn ? "Profil" : "Kirish")
    }
}

private struct MemberProfileView: View {
    let member: Member
    @Environment(SessionStore.self) private var session
    @State private var confirmLogout = false
    @State private var confirmDelete = false
    @State private var isDeleting = false
    @State private var errorMessage: String?

    var body: some View {
        List {
            Section {
                HStack(spacing: 16) {
                    RemoteImage(path: member.imagePath, iconSize: 24)
                        .frame(width: 64, height: 64)
                        .clipShape(Circle())
                    VStack(alignment: .leading, spacing: 6) {
                        Text(member.nick).font(.title3.bold())
                        TagView(text: member.isAgent ? "Diler" : "Foydalanuvchi", highlighted: true)
                    }
                }
                .padding(.vertical, 4)
            }

            Section {
                if let name = member.fullName, !name.isEmpty {
                    LabeledContent("Ism", value: name)
                }
                if let phone = member.phone, !phone.isEmpty {
                    LabeledContent("Telefon", value: phone)
                }
                Link(destination: AppConfig.siteURL) {
                    Label("E’lon joylash va profilni tahrirlash — saytda", systemImage: "safari")
                }
            }

            Section {
                Button("Chiqish", systemImage: "rectangle.portrait.and.arrow.right", role: .destructive) {
                    confirmLogout = true
                }
                Button(role: .destructive) {
                    confirmDelete = true
                } label: {
                    HStack {
                        Label("Hisobni o‘chirish", systemImage: "trash")
                        if isDeleting {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isDeleting)
            }

            Section {
                Link("Maxfiylik siyosati", destination: AppConfig.privacyPolicyURL)
            }
        }
        .confirmationDialog("Hisobingizdan chiqmoqchimisiz?", isPresented: $confirmLogout, titleVisibility: .visible) {
            Button("Chiqish", role: .destructive) {
                Task { await session.logout() }
            }
        }
        .alert("Hisobni o‘chirish", isPresented: $confirmDelete) {
            Button("O‘chirish", role: .destructive) { deleteAccount() }
            Button("Bekor qilish", role: .cancel) {}
        } message: {
            Text("Hisobingiz butunlay o‘chiriladi: barcha qurilmalardagi sessiyalar yopiladi, e’lonlaringiz va maqolalaringiz saytdan olib tashlanadi. Buni qaytarib bo‘lmaydi.")
        }
        .alert("Xatolik", isPresented: Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func deleteAccount() {
        isDeleting = true
        Task {
            defer { isDeleting = false }
            do {
                try await session.deleteAccount()
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct AuthFormView: View {
    private enum Field { case nick, password, phone }

    @Environment(SessionStore.self) private var session
    @State private var isSignup = false
    @State private var nick = ""
    @State private var password = ""
    @State private var phone = ""
    @State private var isAgent = false
    @State private var isBusy = false
    @State private var errorMessage: String?
    @FocusState private var focus: Field?

    private var nickError: String? {
        let count = nick.trimmingCharacters(in: .whitespaces).count
        return (3...20).contains(count) ? nil : "3–20 ta belgi bo‘lishi kerak"
    }

    private var passwordError: String? {
        (5...30).contains(password.count) ? nil : "5–30 ta belgi bo‘lishi kerak"
    }

    private var phoneError: String? {
        guard isSignup else { return nil }
        let count = phone.trimmingCharacters(in: .whitespaces).count
        return (7...20).contains(count) ? nil : "Telefon raqamni to‘g‘ri kiriting"
    }

    private var isValid: Bool { nickError == nil && passwordError == nil && phoneError == nil }

    var body: some View {
        Form {
            Section {
                VStack(spacing: 6) {
                    Image(systemName: "person.crop.circle")
                        .font(.system(size: 52))
                        .foregroundStyle(Color.accentColor)
                    Text(isSignup ? "Hisob saytda ham, ilovada ham ishlaydi" : "Saytdagi hisobingiz bilan kiring")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Picker("Rejim", selection: $isSignup) {
                    Text("Kirish").tag(false)
                    Text("Ro‘yxatdan o‘tish").tag(true)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
                .disabled(isBusy)
                .onChange(of: isSignup) { _, _ in errorMessage = nil }
            }

            Section {
                TextField("Nik (login)", text: $nick)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focus, equals: .nick)
                    .submitLabel(.next)
                    .onSubmit { focus = .password }
                SecureField("Parol", text: $password)
                    .textContentType(isSignup ? UITextContentType.newPassword : UITextContentType.password)
                    .focused($focus, equals: .password)
                    .submitLabel(isSignup ? .next : .go)
                    .onSubmit { if isSignup { focus = .phone } else { submit() } }
                if isSignup {
                    TextField("Telefon raqam (+998 90 123 45 67)", text: $phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .focused($focus, equals: .phone)
                    Toggle(isOn: $isAgent) {
                        VStack(alignment: .leading) {
                            Text("Men dilerman")
                            Text("Mototsikl va qismlar sotuvchi do‘kon yoki agent")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } footer: {
                if !nick.isEmpty, let nickError {
                    Text("Nik: \(nickError)")
                } else if !password.isEmpty, let passwordError {
                    Text("Parol: \(passwordError)")
                } else if !phone.isEmpty, let phoneError {
                    Text(phoneError)
                }
            }
            .disabled(isBusy)

            if let errorMessage {
                Section {
                    Text(errorMessage).foregroundStyle(Color.red)
                }
            }

            Section {
                Button(action: submit) {
                    HStack {
                        Spacer()
                        if isBusy {
                            ProgressView()
                        } else {
                            Text(isSignup ? "Ro‘yxatdan o‘tish" : "Kirish").bold()
                        }
                        Spacer()
                    }
                }
                .disabled(!isValid || isBusy)
            } footer: {
                HStack {
                    Spacer()
                    Link("Maxfiylik siyosati", destination: AppConfig.privacyPolicyURL).font(.footnote)
                    Spacer()
                }
                .padding(.top, 8)
            }
        }
    }

    private func submit() {
        guard isValid, !isBusy else { return }
        focus = nil
        isBusy = true
        errorMessage = nil
        Task {
            defer { isBusy = false }
            do {
                if isSignup {
                    try await session.signup(SignupForm(nick: nick, password: password, phone: phone, isAgent: isAgent))
                } else {
                    try await session.login(nick: nick, password: password)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
