import AVFoundation
import SwiftUI

@main
struct MotoHubApp: App {
    @State private var container = AppContainer.live()
    @State private var router = Router()

    init() {
        // Muted background videos must not stop the user's music.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: .mixWithOthers)
    }

    var body: some Scene {
        WindowGroup {
            if AppContainer.isRunningUnitTests {
                // Unit tests are hosted by the app; don't hit the network while they run.
                Color.clear
            } else {
                RootView(router: router)
                    .environment(container)
                    .environment(container.session)
                    .preferredColorScheme(.light)
                    .task { await container.session.restore() }
            }
        }
    }
}
