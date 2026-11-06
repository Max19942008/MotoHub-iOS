import SwiftUI

/// Pushed onto a tab's NavigationStack. Lists, and the assistant's source
/// cards, only carry the id; the detail screen loads the listing itself.
enum Route: Hashable {
    case motorbike(id: String)
    case part(id: String)
}

extension View {
    func withRoutes(_ container: AppContainer) -> some View {
        navigationDestination(for: Route.self) { route in
            switch route {
            case .motorbike(let id):
                MotorbikeDetailView(id: id, repository: container.listings)
            case .part(let id):
                PartDetailView(id: id, repository: container.listings)
            }
        }
    }
}
