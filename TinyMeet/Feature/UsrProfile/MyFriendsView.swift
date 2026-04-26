import SwiftUI

struct MyFriendsView: View {
    @StateObject private var viewModel: MyFriendsViewModel

    init(viewModel: MyFriendsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

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
            } else if viewModel.filteredFriends.isEmpty {
                ContentUnavailableView(
                    viewModel.friends.isEmpty ? "No friends yet" : "No matching friends",
                    systemImage: viewModel.friends.isEmpty ? "person.2" : "magnifyingglass",
                    description: Text(
                        viewModel.friends.isEmpty
                            ? "Add friends from Discover to see them here."
                            : "Try a different name or keyword."
                    )
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.filteredFriends) { friend in
                            friendRow(friend)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("profile.friends.navigation.title")
        .searchable(text: $viewModel.searchText, prompt: "Search friends")
        .task {
            await viewModel.loadFriends()
        }
        .tinyMeetPageBackground()
    }

    private func friendRow(_ friend: UserProfile) -> some View {
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
                Text("@\(friend.username)")
                    .font(.headline)
                    .foregroundStyle(.primary)

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
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }
}

#Preview {
    NavigationStack {
        MyFriendsView(viewModel: MyFriendsViewModel.makeDefault())
    }
}
