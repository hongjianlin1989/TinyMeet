import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 12) {
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 44))
                    .foregroundStyle(.tint)

                Text("profile.placeholder.title")
                    .font(.title2)
                    .fontWeight(.semibold)

                Text("profile.placeholder.message")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .navigationTitle("profile.navigation.title")
        }
    }
}

#Preview {
    ProfileView()
}
