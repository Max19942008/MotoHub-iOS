import Observation

/// App-wide auth state for the UI. Views read `member`; everything else goes
/// through the AuthRepository.
@MainActor
@Observable
final class SessionStore {
    private(set) var member: Member?
    private let repository: any AuthRepository

    init(repository: any AuthRepository) {
        self.repository = repository
    }

    var isLoggedIn: Bool { member != nil }

    func restore() async {
        member = await repository.restoreSession()
        await repository.onSessionExpired { [weak self] in
            guard let self else { return }
            Task { @MainActor in self.member = nil }
        }
    }

    func login(nick: String, password: String) async throws {
        member = try await repository.login(nick: nick, password: password)
    }

    func signup(_ form: SignupForm) async throws {
        member = try await repository.signup(form)
    }

    func logout() async {
        member = nil
        await repository.logout()
    }

    func updateProfile(nick: String? = nil, phone: String? = nil, address: String? = nil, imagePath: String? = nil) async throws {
        if let updated = try await repository.updateProfile(nick: nick, phone: phone, address: address, imagePath: imagePath) {
            member = updated
        }
    }

    func deleteAccount() async throws {
        try await repository.deleteAccount()
        member = nil
    }
}
