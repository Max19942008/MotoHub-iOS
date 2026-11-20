import Foundation
import Observation

/// Composition root: the only place that knows concrete types. Screens get
/// repository protocols (through the environment), so tests can use fakes.
@MainActor
@Observable
final class AppContainer {
    let listings: any ListingRepository
    let agents: any AgentRepository
    let community: any CommunityRepository
    let myPage: any MyPageRepository
    let notifications: any NotificationRepository
    let assistant: any AssistantRepository
    let session: SessionStore
    let chat: ChatService

    init(
        repository: GraphQLRepository,
        assistant: any AssistantRepository,
        auth: any AuthRepository,
        chatURL: URL
    ) {
        listings = repository
        agents = repository
        community = repository
        myPage = repository
        notifications = repository
        self.assistant = assistant
        session = SessionStore(repository: auth)
        chat = ChatService(url: chatURL, auth: auth)
    }

    static func live() -> AppContainer {
        let tokenStore = KeychainTokenStore()
        clearKeychainOnFreshInstall(tokenStore)

        let publicClient = GraphQLClient(endpoint: AppConfig.graphQLURL)
        let authSession = AuthSession(client: publicClient, store: tokenStore)
        let client = GraphQLClient(endpoint: AppConfig.graphQLURL, tokenProvider: authSession)

        return AppContainer(
            repository: GraphQLRepository(client: client),
            assistant: GraphQLAssistantRepository(client: client),
            auth: GraphQLAuthRepository(publicClient: publicClient, client: client, session: authSession),
            chatURL: AppConfig.chatSocketURL
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
