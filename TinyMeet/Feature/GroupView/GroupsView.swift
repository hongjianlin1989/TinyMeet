import SwiftUI

struct GroupsView: View {
    @StateObject private var viewModel: GroupsViewModel

    init(viewModel: GroupsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.groups.isEmpty {
                    ProgressView("Loading groups...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "Groups unavailable",
                        systemImage: "person.3.sequence",
                        description: Text(errorMessage)
                    )
                } else if viewModel.groups.isEmpty {
                    ContentUnavailableView(
                        "No groups yet",
                        systemImage: "person.3",
                        description: Text("Check back soon for nearby communities.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.groups) { group in
                                NavigationLink {
                                    GroupDetailView(viewModel: GroupDetailViewModel.makeDefault(groupID: group.id))
                                } label: {
                                    groupRow(group)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 24)
                    }
                }
            }
            .padding(viewModel.groups.isEmpty ? 16 : 0)
            .navigationTitle("Groups")
            .task {
                await viewModel.fetchGroups()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.fetchGroups()
                        }
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .tinyMeetPageBackground()
    }

    @ViewBuilder
    private func groupRow(_ group: MeetupGroup) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Text(group.name)
                            .font(.headline)

                        Image(systemName: "sparkles")
                            .foregroundStyle(TinyMeetTheme.sunshine)
                    }

                    if let location = group.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                Text("\(group.memberCount) members")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TinyMeetTheme.badge)
                    .clipShape(Capsule())
            }

            if let summary = group.summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }
}

#Preview {
    GroupsView(viewModel: GroupsViewModel.makeDefault())
}
