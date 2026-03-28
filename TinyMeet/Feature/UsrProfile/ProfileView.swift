import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel
    @State private var isShowingCreateEvent = false

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.userProfile == nil {
                    ProgressView("Loading profile...")
                } else if let userProfile = viewModel.userProfile {
                    profileContent(userProfile)
                } else {
                    ContentUnavailableView(
                        "Profile unavailable",
                        systemImage: "person.crop.circle.badge.exclamationmark",
                        description: Text(viewModel.errorMessage ?? "We couldn't load your profile yet.")
                    )
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("profile.navigation.title")
            .task {
                await viewModel.fetchUserProfile()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        isShowingCreateEvent = true
                    } label: {
                        Label("Create Event", systemImage: "calendar.badge.plus")
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.fetchUserProfile()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .sheet(isPresented: $isShowingCreateEvent) {
            CreateEventView()
        }
    }

    @ViewBuilder
    private func profileContent(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "person.crop.circle.badge.checkmark")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text(userProfile.username)
                .font(.title2)
                .fontWeight(.semibold)

            if let age = userProfile.age {
                Text("Age \(age)")
                    .foregroundStyle(.secondary)
            }

            if let bio = userProfile.bio, !bio.isEmpty {
                Text(bio)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }

            if let avatarURL = userProfile.avatarURL {
                Text(avatarURL.absoluteString)
                    .font(.footnote)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel.makeDefault())
}
