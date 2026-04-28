import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appSession: AppSession
    @StateObject private var viewModel: ProfileViewModel
    private let onNavigateToDiscover: () -> Void

    init(
        viewModel: ProfileViewModel,
        onNavigateToDiscover: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onNavigateToDiscover = onNavigateToDiscover
    }

    var body: some View {
        NavigationStack {
            Group {
                if appSession.isLoggedIn {
                    loggedInContent
                } else {
                    signedOutContent
                }
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .navigationTitle("profile.navigation.title")
            .task(id: appSession.isLoggedIn) {
                await viewModel.fetchUserProfile(isLoggedIn: appSession.isLoggedIn)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    inviteToolbarButton
                }

                ToolbarItemGroup(placement: .topBarTrailing) {
                    createEventToolbarButton
                    AuthToolbarButton()
                }
            }
        }
        .tinyMeetPageBackground()
        .sheet(isPresented: $viewModel.isShowingCreateEvent) {
            CreateEventView(viewModel: CreateEventViewModel.makeDefault())
        }
        .sheet(item: $viewModel.inviteSharePayload, onDismiss: {
            viewModel.clearInviteSharePayload()
        }, content: { payload in
            ShareSheetView(activityItems: payload.activityItems)
        })
    }

    @ViewBuilder
    private var loggedInContent: some View {
        if viewModel.isLoading && viewModel.userProfile == nil {
            ProgressView("profile.loading")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let userProfile = viewModel.userProfile {
            profileContent(userProfile)
        } else {
            ContentUnavailableView(
                "profile.unavailable.title",
                systemImage: "person.crop.circle.badge.exclamationmark",
                description: Text(viewModel.errorMessage ?? String(localized: "profile.unavailable.message"))
            )
        }
    }

    private var inviteToolbarButton: some View {
        Button {
            viewModel.inviteFriendsTapped()
        } label: {
            Label("profile.invite", systemImage: "person.badge.plus")
        }
        .buttonStyle(TinyMeetSecondaryButtonStyle())
    }

    private var createEventToolbarButton: some View {
        Button {
            viewModel.createEventTapped()
        } label: {
            Label("profile.createEvent", systemImage: "calendar.badge.plus")
        }
        .buttonStyle(TinyMeetSecondaryButtonStyle())
    }

    @ViewBuilder
    private func profileContent(_ userProfile: UserProfile) -> some View {
        VStack(spacing: 20) {
            profileSummaryCard(userProfile)
            friendsNavigationCard
            groupsNavigationCard
            interestedEventsNavigationCard
        }
    }

    private func profileSummaryCard(_ userProfile: UserProfile) -> some View {
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

            Text(userProfile.displayName)
                .font(.title2.weight(.bold))

            Text("@\(userProfile.username)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

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

            if let email = userProfile.email, !email.isEmpty {
                Label(email, systemImage: "envelope.fill")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TinyMeetTheme.sky)
            }

            if let avatarURL = userProfile.avatarURL {
                Label("profile.avatar.ready", systemImage: "sparkles")
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

    private var friendsNavigationCard: some View {
        NavigationLink {
            MyFriendsView(
                viewModel: MyFriendsViewModel.makeDefault(),
                onAddFriendTapped: onNavigateToDiscover
            )
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TinyMeetTheme.heroGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.2.fill")
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("profile.friends.title")
                        .font(.headline)

                    Text("profile.friends.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tinyMeetCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var groupsNavigationCard: some View {
        NavigationLink {
            GroupsView(viewModel: GroupsViewModel.makeDefault())
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TinyMeetTheme.playfulGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.3.fill")
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("profile.groups.title")
                        .font(.headline)

                    Text("profile.groups.message")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tinyMeetCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var interestedEventsNavigationCard: some View {
        NavigationLink {
            InterestedEventsView(viewModel: InterestedEventsViewModel.makeDefault())
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(TinyMeetTheme.heroGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "heart.fill")
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Interested Events")
                        .font(.headline)

                    Text("See events you’ve marked interested")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tinyMeetCardStyle()
        }
        .buttonStyle(.plain)
    }

    private var signedOutContent: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(TinyMeetTheme.heroGradient)
                    .frame(width: 118, height: 118)

                Image(systemName: "person.crop.circle.badge.questionmark")
                    .font(.system(size: 60))
                    .foregroundStyle(.white)
            }
            .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)

            Text("profile.signedOut.title")
                .font(.title2.weight(.bold))

            Text("profile.signedOut.message")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)

            AuthToolbarButton()
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .tinyMeetCardStyle()
    }
}

#Preview {
    ProfileView(viewModel: ProfileViewModel.makeDefault())
        .environmentObject(AppSession())
}
