import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeEventsView(viewModel: HomeEventsViewModel.makeDefault())
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }

            HomeMapView()
                .tabItem {
                    Label("Map", systemImage: "map.fill")
                }

            DiscoverView(viewModel: DiscoverViewModel.makeDefault())
                .tabItem {
                    Label("tab.discover", systemImage: "sparkle.magnifyingglass")
                }

            ProfileView(viewModel: ProfileViewModel.makeDefault())
                .tabItem {
                    Label("tab.profile", systemImage: "face.smiling.fill")
                }
        }
        .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
    }
}

#Preview {
    RootTabView()
}
