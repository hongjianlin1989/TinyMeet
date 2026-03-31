import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel
    @State private var selectedGroupIDs: [Int: Int] = [:]

    init(viewModel: DiscoverViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profiles.isEmpty && !viewModel.hasActiveQuery {
                    ProgressView("Preparing groups...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty && !viewModel.hasActiveQuery {
                    ContentUnavailableView(
                        "Discover unavailable",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text(errorMessage)
                    )
                } else if !viewModel.hasActiveQuery {
                    ContentUnavailableView(
                        "Search people",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Find user profiles and add them into one of your existing groups.")
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
            .task {
                await viewModel.loadGroups()
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

            if viewModel.groups.isEmpty {
                emptyGroupsMessage
            } else {
                groupPicker(for: profile)
                addToGroupButton(for: profile)
            }
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

    private var emptyGroupsMessage: some View {
        Text("No groups available yet. Create a group first to add members.")
            .font(.footnote)
            .foregroundStyle(.secondary)
    }

    private func groupPicker(for profile: UserProfile) -> some View {
        Picker(
            "Choose group",
            selection: bindingForSelectedGroupID(profileID: profile.id)
        ) {
            Text("Select a group")
                .tag(Optional<Int>.none)

            ForEach(viewModel.groups) { group in
                Text(group.name)
                    .tag(Optional(group.id))
            }
        }
        .pickerStyle(.menu)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(TinyMeetTheme.badge)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func addToGroupButton(for profile: UserProfile) -> some View {
        Button(action: {
            Task {
                if let groupID = selectedGroupIDs[profile.id] {
                    await viewModel.addProfileToGroup(profile, groupID: groupID)
                }
            }
        }, label: {
            Label("Add to Group", systemImage: "person.badge.plus")
        })
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(selectedGroupIDs[profile.id] == nil || viewModel.isLoading)
    }

    private func bindingForSelectedGroupID(profileID: Int) -> Binding<Int?> {
        Binding(
            get: { selectedGroupIDs[profileID] },
            set: { selectedGroupIDs[profileID] = $0 }
        )
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
