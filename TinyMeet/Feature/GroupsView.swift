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
                    List(viewModel.groups) { group in
                        NavigationLink {
                            GroupDetailView(viewModel: GroupDetailViewModel.makeDefault(groupID: group.id))
                        } label: {
                            groupRow(group)
                        }
                        .buttonStyle(.plain)
                        .listRowSeparator(.hidden)
                        .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
                    }
                    .listStyle(.plain)
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
                    .disabled(viewModel.isLoading)
                }
            }
        }
    }

    @ViewBuilder
    private func groupRow(_ group: MeetupGroup) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.headline)

                    if let location = group.location, !location.isEmpty {
                        Label(location, systemImage: "mappin.and.ellipse")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer(minLength: 12)

                Text("\(group.memberCount) members")
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(Capsule())
            }

            if let summary = group.summary, !summary.isEmpty {
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
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
}

#Preview {
    GroupsView(viewModel: GroupsViewModel.makeDefault())
}
