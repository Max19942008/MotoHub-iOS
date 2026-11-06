import SwiftUI

struct RootView: View {
    let container: AppContainer
    @Environment(SessionStore.self) private var session

    var body: some View {
        TabView {
            NavigationStack {
                MotorbikeListView(repository: container.listings)
                    .withRoutes(container)
            }
            .tabItem { Label("Mototsikllar", systemImage: "scooter") }

            NavigationStack {
                PartListView(repository: container.listings)
                    .withRoutes(container)
            }
            .tabItem { Label("Qismlar", systemImage: "wrench.and.screwdriver") }

            NavigationStack {
                AssistantView(repository: container.assistant)
                    .withRoutes(container)
            }
            .tabItem { Label("AI yordamchi", systemImage: "sparkles") }

            NavigationStack {
                ProfileView()
            }
            .tabItem { Label(session.member == nil ? "Kirish" : "Profil", systemImage: "person.crop.circle") }
        }
    }
}
