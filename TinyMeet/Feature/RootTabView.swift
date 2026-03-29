import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            GroupsView(viewModel: GroupsViewModel.makeDefault())
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            HomeMapView()
                .tabItem {
                    Label("tab.home", systemImage: "map.fill")
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
