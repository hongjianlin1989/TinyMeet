import SwiftUI

struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)

                Text("discover.placeholder.title")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("discover.placeholder.message")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("discover.navigation.title")
        }
    }
}

#Preview {
    DiscoverView()
}
