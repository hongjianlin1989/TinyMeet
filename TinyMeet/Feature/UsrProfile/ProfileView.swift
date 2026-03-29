import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel: ProfileViewModel

    init(viewModel: ProfileViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.userProfile == nil {
                    ProgressView("Loading profile...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
                        viewModel.inviteFriendsTapped()
                    } label: {
                        Label("Invite Your Friend", systemImage: "person.badge.plus")
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        viewModel.createEventTapped()
                    } label: {
                        Label("Create Event", systemImage: "calendar.badge.plus")
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())

                    Button("Refresh") {
                        Task {
                            await viewModel.fetchUserProfile()
                        }
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .tinyMeetPageBackground()
        .sheet(isPresented: $viewModel.isShowingCreateEvent) {
            CreateEventView(viewModel: CreateEventViewModel.makeDefault())
        }
        .sheet(item: $viewModel.inviteSharePayload, onDismiss: {
            viewModel.clearInviteSharePayload()
        }) { payload in
            ShareSheetView(activityItems: payload.activityItems)
        }
    }

    @ViewBuilder
    private func profileContent(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 20) {
            VStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(TinyMeetTheme.heroGradient)
                        .frame(width: 118, height: 118)

                    Image(systemName: "person.crop.circle.badge.checkmark")
                        .font(.system(size: 60))
                        .foregroundStyle(.white)
                }
                .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)

                Text(userProfile.username)
                    .font(.title2.weight(.bold))

                if let age = userProfile.age {
                    Text("Age \(age)")
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(TinyMeetTheme.badge)
                        .clipShape(Capsule())
                }

                if let bio = userProfile.bio, !bio.isEmpty {
                    Text(bio)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }

                if let avatarURL = userProfile.avatarURL {
                    Label("Avatar link ready", systemImage: "sparkles")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(TinyMeetTheme.accent)

                    Text(avatarURL.absoluteString)
                        .font(.footnote)
                        .foregroundStyle(.tertiary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            .tinyMeetCardStyle()
        }
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel.makeDefault())
}
