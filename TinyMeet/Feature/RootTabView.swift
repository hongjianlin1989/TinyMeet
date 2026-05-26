import SwiftUI

enum RootTab: Hashable {
    case home
    case map
    case discover
    case profile
}

struct RootTabView: View {
    @EnvironmentObject private var appSession: AppSession
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @State private var selectedTab: RootTab = .home
    @State private var homeRefreshToken = 0
    @State private var pendingHomeEventID: UUID?

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeEventsView(
                viewModel: HomeEventsViewModel.makeDefault(),
                refreshTrigger: homeRefreshToken,
                requestedEventID: pendingHomeEventID,
                onRequestedEventHandled: { handledEventID in
                    if pendingHomeEventID == handledEventID {
                        pendingHomeEventID = nil
                    }
                }
            )
                .tag(RootTab.home)
                .tabItem {
                    Label("tab.home", systemImage: "house.fill")
                }

            HomeMapView(isActive: selectedTab == .map)
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
        .onChange(of: selectedTab) { previousTab, currentTab in
            if previousTab != .home, currentTab == .home {
                homeRefreshToken += 1
            }
        }
        .onChange(of: appSession.isLoggedIn) { _, isLoggedIn in
            if !isLoggedIn {
                selectedTab = .home
            }
        }
        .onChange(of: deepLinkHandler.activeDestination) { _, destination in
            guard case .eventDetail(let eventID) = destination else {
                return
            }

            selectedTab = .home
            pendingHomeEventID = eventID
            deepLinkHandler.dismissPresentedDestination()
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppSession())
        .environmentObject(DeepLinkHandler())
}
