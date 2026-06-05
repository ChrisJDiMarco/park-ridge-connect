import SwiftUI

@main
struct ParkRidgeConnectApp: App {
    @State private var store = TownStore()
    @State private var voice = VoiceController()

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
    @State private var selectedTab: AppTab = .today

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
