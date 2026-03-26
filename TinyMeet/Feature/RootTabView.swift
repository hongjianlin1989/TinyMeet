import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            HomeMapView()
                .tabItem {
                    Label("tab.home", systemImage: "map")
                }

            DiscoverView()
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
