import SwiftUI

@main
struct ParkRidgeConnectApp: App {
    @State private var store = TownStore()
    @State private var voice = VoiceController()

    init() {
        // Larger shared cache keeps AsyncImage thumbnails warm so list
        // scrolling never stalls on re-downloads.
        URLCache.shared.memoryCapacity = 32 * 1024 * 1024
        URLCache.shared.diskCapacity = 128 * 1024 * 1024
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(store)
                .environment(voice)
                .tint(PRTheme.teal)
        }
    }
}

enum AppTab: Hashable {
    case today
    case explore
    case ask
    case services
}

struct RootView: View {
    @State private var selectedTab: AppTab = .initialLaunchTab

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab)
                .tabItem { Label("Today", systemImage: "sun.max") }
                .tag(AppTab.today)
            ExploreView()
                .tabItem { Label("Explore", systemImage: "map") }
                .tag(AppTab.explore)
            AssistantView()
                .tabItem { Label("Ask", systemImage: "sparkles") }
                .tag(AppTab.ask)
            ServicesView(selectedTab: $selectedTab)
                .tabItem { Label("Services", systemImage: "building.columns") }
                .tag(AppTab.services)
        }
    }
}

private extension AppTab {
    static var initialLaunchTab: AppTab {
        let arguments = ProcessInfo.processInfo.arguments
        guard let tabFlagIndex = arguments.firstIndex(of: "-screenshotTab"),
              arguments.indices.contains(tabFlagIndex + 1) else {
            return .today
        }
        return AppTab(argument: arguments[tabFlagIndex + 1]) ?? .today
    }

    init?(argument: String) {
        switch argument.lowercased() {
        case "today":
            self = .today
        case "explore":
            self = .explore
        case "ask":
            self = .ask
        case "services":
            self = .services
        default:
            return nil
        }
    }
}
