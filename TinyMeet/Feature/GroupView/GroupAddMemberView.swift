import SwiftUI

struct GroupAddMemberView: View {
    @ObservedObject var viewModel: GroupDetailViewModel
    @State private var searchText = ""

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.friends.isEmpty {
                ProgressView("Loading friends...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.friends.isEmpty {
                ContentUnavailableView(
                    "Friends unavailable",
                    systemImage: "person.2.slash",
                    description: Text(errorMessage)
                )
            } else if filteredFriends.isEmpty {
                ContentUnavailableView(
                    viewModel.friends.isEmpty ? "No friends available" : "No matching friends",
                    systemImage: viewModel.friends.isEmpty ? "person.2" : "magnifyingglass",
                    description: Text(
                        viewModel.friends.isEmpty
                            ? "Add friends first, then come back to invite them to this group."
                            : emptyStateDescription
                    )
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(filteredFriends) { friend in
                            friendRow(friend)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("Invite Member")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search friends")
        .task {
            await viewModel.loadFriends()
        }
        .refreshable {
            await viewModel.loadFriends()
        }
        .tinyMeetPageBackground()
    }

    private var filteredFriends: [UserProfile] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return viewModel.availableFriendsToAdd
        }

        let normalizedQuery = query.localizedLowercase
        return viewModel.availableFriendsToAdd.filter { friend in
            friend.displayName.localizedLowercase.contains(normalizedQuery)
                || friend.username.localizedLowercase.contains(normalizedQuery)
                || (friend.bio?.localizedLowercase.contains(normalizedQuery) ?? false)
        }
    }

    private var emptyStateDescription: String {
        if viewModel.availableFriendsToAdd.isEmpty {
            return "All of your friends are already in this group or already invited."
        }

        return "Try a different name or keyword."
    }

    // swiftlint:disable function_body_length
    private func friendRow(_ friend: UserProfile) -> some View {
        Button {
            Task {
                await viewModel.addFriendToGroup(friend)
            }
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TinyMeetTheme.playfulGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(friend.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("@\(friend.username)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let age = friend.age {
                        Text("Age \(age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let bio = friend.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 12)

                if viewModel.isLoading {
                    ProgressView()
                        .controlSize(.small)
                        .frame(width: 32, height: 32)
                } else {
                    Image(systemName: "paperplane.fill")
                        .font(.title3)
                        .foregroundStyle(TinyMeetTheme.accent)
                        .frame(width: 32, height: 32)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tinyMeetCardStyle()
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isLoading)
    }
    // swiftlint:enable function_body_length
}

#Preview {
    NavigationStack {
        GroupAddMemberView(viewModel: GroupDetailViewModel.makeDefault(groupID: "1"))
    }
}
