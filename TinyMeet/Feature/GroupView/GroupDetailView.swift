import SwiftUI

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel

    init(viewModel: GroupDetailViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.groupDetail == nil {
                ProgressView("Loading group...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let groupDetail = viewModel.groupDetail {
                List {
                    Section {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(groupDetail.name)
                                .font(.title2)
                                .fontWeight(.semibold)

                            if let location = groupDetail.location, !location.isEmpty {
                                Label(location, systemImage: "mappin.and.ellipse")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            if let summary = groupDetail.summary, !summary.isEmpty {
                                Text(summary)
                                    .font(.body)
                                    .foregroundStyle(.secondary)
                            }

                            Text("\(groupDetail.memberCount) members")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }

                    Section("Add member") {
                        TextField("Member name", text: $viewModel.newMemberName)
                            .textInputAutocapitalization(.words)

                        Button("Add Member") {
                            Task {
                                await viewModel.addMember()
                            }
                        }
                        .disabled(viewModel.isLoading || viewModel.newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }

                    Section("Members") {
                        if groupDetail.members.isEmpty {
                            ContentUnavailableView(
                                "No members yet",
                                systemImage: "person.2.slash",
                                description: Text("Add the first member to get this group started.")
                            )
                        } else {
                            ForEach(groupDetail.members) { member in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(member.name)
                                            .font(.body)

                                        Text(member.role)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Button(role: .destructive) {
                                        Task {
                                            await viewModel.deleteMember(memberID: member.id)
                                        }
                                    } label: {
                                        Image(systemName: "trash")
                                    }
                                    .buttonStyle(.borderless)
                                    .disabled(viewModel.isLoading)
                                }
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    if let errorMessage = viewModel.errorMessage {
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
            } else {
                ContentUnavailableView(
                    "Group unavailable",
                    systemImage: "person.3.sequence",
                    description: Text(viewModel.errorMessage ?? "We couldn't load the group right now.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .navigationTitle("Group Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGroupDetail()
        }
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(viewModel: GroupDetailViewModel.makeDefault(groupID: 1))
    }
}
