import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel

    init(viewModel: DiscoverViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profiles.isEmpty && viewModel.hasActiveQuery {
                    ProgressView("Searching people...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty {
                    ContentUnavailableView(
                        "Discover unavailable",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text(errorMessage)
                    )
                } else if !viewModel.hasActiveQuery {
                    ContentUnavailableView(
                        "Search people",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Find user profiles and add them as friends.")
                    )
                } else if viewModel.profiles.isEmpty {
                    ContentUnavailableView(
                        "No people found",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching by username or bio.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                profileRow(profile)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .padding(viewModel.profiles.isEmpty ? 16 : 0)
            .navigationTitle("Discover People")
            .searchable(text: $viewModel.searchText, prompt: "Search user profiles")
            .onSubmit(of: .search) {
                Task {
                    await viewModel.searchProfiles()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthToolbarButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                bannerMessage
            }
        }
        .tinyMeetPageBackground()
    }

    @ViewBuilder
    private func profileRow(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            profileHeader(profile)
            addFriendButton(for: profile)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }

    private func profileHeader(_ profile: UserProfile) -> some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(TinyMeetTheme.playfulGradient)
                    .frame(width: 54, height: 54)

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("@\(profile.username)")
                    .font(.headline)

                if let age = profile.age {
                    Text("Age \(age)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let bio = profile.bio, !bio.isEmpty {
                    Text(bio)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func addFriendButton(for profile: UserProfile) -> some View {
        Button(action: {
            Task {
                await viewModel.addFriend(profile)
            }
        }, label: {
            Label(
                viewModel.hasAddedFriend(profile) ? "Friend Added" : "Add Friend",
                systemImage: viewModel.hasAddedFriend(profile) ? "checkmark.circle.fill" : "person.badge.plus"
            )
        })
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(viewModel.hasAddedFriend(profile) || viewModel.isLoading)
    }

    @ViewBuilder
    private var bannerMessage: some View {
        if let message = viewModel.successMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(TinyMeetTheme.mint)
                .clipShape(Capsule())
                .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
                .padding(.bottom, 10)
        } else if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(TinyMeetTheme.accent)
                .clipShape(Capsule())
                .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
                .padding(.bottom, 10)
        }
    }
}

#Preview {
    DiscoverView(viewModel: DiscoverViewModel.makeDefault())
}
