import SwiftUI

enum RootTab: Hashable {
    case home
    case map
    case discover
    case profile
}

struct RootTabView: View {
    @EnvironmentObject private var appSession: AppSession
    @State private var selectedTab: RootTab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeEventsView(viewModel: HomeEventsViewModel.makeDefault())
                .tag(RootTab.home)
                .tabItem {
                    Label("tab.home", systemImage: "house.fill")
                }

            HomeMapView()
                .tag(RootTab.map)
                .tabItem {
                    Label("tab.map", systemImage: "map.fill")
                }

            DiscoverView(viewModel: DiscoverViewModel.makeDefault())
                .tag(RootTab.discover)
                .tabItem {
                    Label("tab.discover", systemImage: "sparkle.magnifyingglass")
                }

            ProfileView(
                viewModel: ProfileViewModel.makeDefault(),
                onNavigateToDiscover: { selectedTab = .discover }
            )
                .tag(RootTab.profile)
                .tabItem {
                    Label("tab.profile", systemImage: "face.smiling.fill")
                }
        }
        .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
        .onChange(of: appSession.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                selectedTab = .home
            }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSession())
        .environmentObject(DeepLinkHandler())
}
