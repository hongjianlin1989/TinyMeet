import SwiftUI

struct CreateGroupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateGroupViewModel
    private let onGroupCreated: @Sendable () async -> Void

    init(
        viewModel: CreateGroupViewModel,
        onGroupCreated: @escaping @Sendable () async -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onGroupCreated = onGroupCreated
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.friends.isEmpty {
                    ProgressView("Loading friends...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            headerCard
                            groupDetailsCard

                            if let errorMessage = viewModel.errorMessage {
                                errorBanner(errorMessage)
                            }

                            VStack(alignment: .leading, spacing: 14) {
                                Text("Invite friends")
                                    .font(.headline)

                                if let errorMessage = viewModel.errorMessage, viewModel.friends.isEmpty {
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
                                    LazyVStack(spacing: 14) {
                                        ForEach(viewModel.filteredFriends) { friend in
                                            friendRow(friend)
                                        }
                                    }
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
                        Task {
                            if await viewModel.createGroup() {
                                await onGroupCreated()
                                dismiss()
                            }
                        }
                    } label: {
                        Text(viewModel.isSubmitting ? "Creating Group..." : "Create Group")
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
            Text("Create your next group")
                .font(.title3.weight(.bold))

            Text("Add a name, location, summary, and choose the friends you want to invite.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyMeetTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)
    }

    private var groupDetailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Group details")
                .font(.headline)

            formField(title: "Name", prompt: "Weekend Hikers", text: $viewModel.groupName)
            formField(title: "Location", prompt: "Palo Alto", text: $viewModel.groupLocation)

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                TextField(
                    "Tell people what this group is about",
                    text: $viewModel.groupSummary,
                    axis: .vertical
                )
                .lineLimit(3...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(TinyMeetTheme.badge)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    private func errorBanner(_ message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TinyMeetTheme.accent)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func formField(title: String, prompt: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            TextField(prompt, text: text)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(TinyMeetTheme.badge)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
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
