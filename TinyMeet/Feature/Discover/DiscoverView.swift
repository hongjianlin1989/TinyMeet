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
                    List(viewModel.profiles) { profile in
                        profileRow(profile)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listStyle(.plain)
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
                    Button("Search") {
                        Task {
                            await viewModel.searchProfiles()
                        }
                    }
                    .disabled(viewModel.isLoading)
                }
            }
            .safeAreaInset(edge: .bottom) {
                bannerMessage
            }
        }
    }

    @ViewBuilder
    private func profileRow(_ profile: UserProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.tint)

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

            if viewModel.groups.isEmpty {
                Text("No groups available yet. Create a group first to add members.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
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

                Button(action: {
                    Task {
                        if let groupID = selectedGroupIDs[profile.id] {
                            await viewModel.addProfileToGroup(profile, groupID: groupID)
                        }
                    }
                }) {
                    Label("Add to Group", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(selectedGroupIDs[profile.id] == nil || viewModel.isLoading)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(.separator).opacity(0.2), lineWidth: 1)
        }
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
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.green.opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, 8)
        } else if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.footnote)
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.red.opacity(0.9))
                .clipShape(Capsule())
                .padding(.bottom, 8)
        }
    }
}

#Preview {
    DiscoverView(viewModel: DiscoverViewModel.makeDefault())
}
