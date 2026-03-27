import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            GroupsView(viewModel: GroupsViewModel.makeDefault())
                .tabItem {
                    Label("Groups", systemImage: "person.3")
                }
            
            HomeMapView()
                .tabItem {
                    Label("tab.home", systemImage: "map")
                }

            DiscoverView(viewModel: DiscoverViewModel.makeDefault())
                .tabItem {
                    Label("tab.discover", systemImage: "magnifyingglass")
                }

            ProfileView(viewModel: ProfileViewModel.makeDefault())
                .tabItem {
                    Label("tab.profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    RootTabView()
}
