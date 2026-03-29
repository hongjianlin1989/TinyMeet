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
                ScrollView {
                    VStack(spacing: 18) {
                        summaryCard(groupDetail)
                        addMemberCard
                        membersCard(groupDetail)
                    }
                    .padding(16)
                    .padding(.bottom, 32)
                }
                .overlay(alignment: .bottom) {
                    if let errorMessage = viewModel.errorMessage {
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
            } else {
                ContentUnavailableView(
                    "Group unavailable",
                    systemImage: "person.3.sequence",
                    description: Text(viewModel.errorMessage ?? "We couldn't load the group right now.")
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .tinyMeetPageBackground()
        .navigationTitle("Group Detail")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.fetchGroupDetail()
        }
    }

    private func summaryCard(_ groupDetail: GroupDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(groupDetail.name)
                    .font(.title2.weight(.bold))

                Spacer()

                Text("\(groupDetail.memberCount) members")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TinyMeetTheme.badge)
                    .clipShape(Capsule())
            }

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
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    private var addMemberCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add member")
                .font(.headline)

            TextField("Member name", text: $viewModel.newMemberName)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(TinyMeetTheme.badge)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

            Button("Add Member") {
                Task {
                    await viewModel.addMember()
                }
            }
            .buttonStyle(TinyMeetPrimaryButtonStyle())
            .disabled(viewModel.isLoading || viewModel.newMemberName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    private func membersCard(_ groupDetail: GroupDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Members")
                .font(.headline)

            if groupDetail.members.isEmpty {
                ContentUnavailableView(
                    "No members yet",
                    systemImage: "person.2.slash",
                    description: Text("Add the first member to get this group started.")
                )
            } else {
                ForEach(groupDetail.members) { member in
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(TinyMeetTheme.playfulGradient)
                                .frame(width: 42, height: 42)

                            Image(systemName: "person.fill")
                                .foregroundStyle(.white)
                        }

                        VStack(alignment: .leading, spacing: 4) {
                            Text(member.name)
                                .font(.body.weight(.semibold))

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
                            Image(systemName: "trash.fill")
                                .foregroundStyle(.white)
                                .padding(10)
                                .background(TinyMeetTheme.accent)
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .disabled(viewModel.isLoading)
                    }
                    .padding(14)
                    .background(TinyMeetTheme.badge)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
            }
        }
        .padding(20)
        .tinyMeetCardStyle()
    }
}

#Preview {
    NavigationStack {
        GroupDetailView(viewModel: GroupDetailViewModel.makeDefault(groupID: 1))
    }
}
