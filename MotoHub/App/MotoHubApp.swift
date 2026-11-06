import SwiftUI

@main
struct MotoHubApp: App {
    @State private var container = AppContainer.live()

    var body: some Scene {
        WindowGroup {
            if AppContainer.isRunningUnitTests {
                // Unit tests are hosted by the app; don't hit the network while they run.
                Color.clear
            } else {
                RootView(container: container)
                    .environment(container.session)
                    .task { await container.session.restore() }
            }
        }
    }
}
