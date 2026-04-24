import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateGroupViewModel

    init(viewModel: CreateGroupViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
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
                                ? "Add friends first, then come back to start a new group."
                                : "Try a different name or keyword."
                        )
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerCard

                            LazyVStack(spacing: 14) {
                                ForEach(viewModel.filteredFriends) { friend in
                                    friendRow(friend)
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $viewModel.searchText, prompt: "Search friends")
            .task {
                await viewModel.loadFriends()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                }
            }
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if viewModel.canCreateGroup {
                        Text(viewModel.selectedCountText)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.white)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(TinyMeetTheme.accent)
                            .clipShape(Capsule())
                            .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
                    }

                    Button {
                        viewModel.createGroup()
                        dismiss()
                    } label: {
                        Text("Create Group")
                    }
                    .buttonStyle(TinyMeetPrimaryButtonStyle())
                    .disabled(!viewModel.canCreateGroup)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 10)
            }
        }
        .tinyMeetPageBackground()
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Pick friends for your next group")
                .font(.title3.weight(.bold))

            Text("Browse your friend list and tap people you want to group together.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyMeetTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)
    }

    private func friendRow(_ friend: UserProfile) -> some View {
        Button {
            viewModel.toggleSelection(for: friend)
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

                Image(systemName: viewModel.isSelected(friend) ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(viewModel.isSelected(friend) ? TinyMeetTheme.accent : Color.secondary)
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .tinyMeetCardStyle()
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    CreateGroupView(viewModel: CreateGroupViewModel.makeDefault())
}
