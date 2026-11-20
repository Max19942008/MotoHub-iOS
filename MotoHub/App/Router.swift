import SwiftUI
import Observation

/// Pages reachable from the drawer, same order as the website menu.
enum AppPage: Int, CaseIterable, Sendable {
    case home, bikes, parts, agents, community, help, assistant, profile
}

/// Screens pushed over the shell (the site's sub-pages).
enum Route: Hashable {
    case motorbike(Motorbike)
    case part(Part)
    case motorbikeID(String)
    case partID(String)
    case agent(String)
    case article(String)
    case writeArticle(category: String)
    case notifications
    case addListing(part: Bool, motorbike: Motorbike?, sparePart: Part?)
}

/// Navigation and toasts, shared by every screen.
@MainActor
@Observable
final class Router {
    var path = NavigationPath()
    private(set) var page: AppPage = .home
    private(set) var visited: Set<AppPage> = [.home]
    var partsCategory = "SPARE_PART"
    /// Bumps when the drawer picks a parts category, so the parts page resets.
    private(set) var partsCategoryChange = 0
    /// A board tapped on an article page; the community page switches to it.
    var communityBoard: String?
    /// A "Mening sahifam" section to open (after saving a listing).
    var myPageSection: String?
    /// Bumps when an article was published, so the lists reload.
    private(set) var articlesChanged = 0
    var drawerOpen = false
    private(set) var toastText: String?
    @ObservationIgnored private var toastID = 0

    func go(_ page: AppPage, category: String? = nil) {
        if let category, category != partsCategory {
            partsCategory = category
            partsCategoryChange += 1
        }
        self.page = page
        visited.insert(page)
        path = NavigationPath()
        withAnimation(.easeOut(duration: 0.2)) { drawerOpen = false }
    }

    func push(_ route: Route) { path.append(route) }

    /// Opens `route` in place of the current screen ("O'xshash" cards).
    func replace(_ route: Route) {
        if !path.isEmpty { path.removeLast() }
        path.append(route)
    }

    func pop() {
        if !path.isEmpty { path.removeLast() }
    }

    func articlePublished() { articlesChanged += 1 }

    /// Opens the write form, or asks to log in first (the site redirects to login).
    func openWriteArticle(loggedIn: Bool) {
        guard loggedIn else {
            toast("Avval tizimga kiring".tr)
            return
        }
        push(.writeArticle(category: "FREE"))
    }

    /// The site's snackbar: a short message at the bottom for 3 seconds.
    func toast(_ text: String) {
        toastID += 1
        let id = toastID
        withAnimation { toastText = text }
        Task {
            try? await Task.sleep(for: .seconds(3))
            if toastID == id { withAnimation { toastText = nil } }
        }
    }
}
