import Foundation

/// Composition root: the only place that knows concrete types. Screens get
/// repository protocols, so they can be previewed and tested with fakes.
@MainActor
final class AppContainer {
    let listings: any ListingRepository
    let assistant: any AssistantRepository
    let session: SessionStore

    init(listings: any ListingRepository, assistant: any AssistantRepository, auth: any AuthRepository) {
        self.listings = listings
        self.assistant = assistant
        self.session = SessionStore(repository: auth)
    }

    static func live() -> AppContainer {
        let tokenStore = KeychainTokenStore()
        clearKeychainOnFreshInstall(tokenStore)

        let publicClient = GraphQLClient(endpoint: AppConfig.graphQLURL)
        let authSession = AuthSession(client: publicClient, store: tokenStore)
        let client = GraphQLClient(endpoint: AppConfig.graphQLURL, tokenProvider: authSession)

        return AppContainer(
            listings: GraphQLListingRepository(client: client),
            assistant: GraphQLAssistantRepository(client: client),
            auth: GraphQLAuthRepository(publicClient: publicClient, client: client, session: authSession)
        )
    }

    static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    /// Keychain items survive an uninstall; without this a reinstall would come back logged in.
    private static func clearKeychainOnFreshInstall(_ store: some TokenStore) {
        let key = "uz.motohub.app.hasLaunched"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        store.clear()
        UserDefaults.standard.set(true, forKey: key)
    }
}
