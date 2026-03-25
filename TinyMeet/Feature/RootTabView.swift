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

            ProfileView()
                .tabItem {
                    Label("tab.profile", systemImage: "person.crop.circle")
                }
        }
    }
}

#Preview {
    RootTabView()
}
