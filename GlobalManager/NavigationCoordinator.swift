import SwiftUI
import Combine
import Combine

class NavigationCoordinator: ObservableObject {
    static let shared = NavigationCoordinator()
    
    @Published var path = NavigationPath()
    @Published var selectedTab: Int = 1
    @Published var routeStack: [AppRoute] = []
    
    @Published var generatedPageHtml: String = ""
    @Published var elemeOrderUrl: String = ""
    
    func navigate(to route: AppRoute) {
        path.append(route)
        routeStack.append(route)
    }
    
    func pop() {
        if !path.isEmpty {
            path.removeLast()
            if !routeStack.isEmpty { routeStack.removeLast() }
        }
    }
    
    func popToRoot() {
        path = NavigationPath()
        routeStack.removeAll()
    }
    
    func switchTab(_ tab: Int) {
        selectedTab = tab
        path = NavigationPath()
        routeStack.removeAll()
    }
    
    func navigateToAuth() {
        popToRoot()
    }

    func pathContains(_ routeToFind: AppRoute) -> Bool {
        return routeStack.contains(routeToFind)
    }
}
