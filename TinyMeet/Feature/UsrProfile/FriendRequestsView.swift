import SwiftUI

struct FriendRequestsView: View {
    @StateObject private var viewModel: FriendRequestsViewModel

    init(viewModel: FriendRequestsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.requests.isEmpty {
                ProgressView("Loading requests...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let errorMessage = viewModel.errorMessage, viewModel.requests.isEmpty {
                ContentUnavailableView(
                    "Requests unavailable",
                    systemImage: "bell.slash",
                    description: Text(errorMessage)
                )
            } else if viewModel.requests.isEmpty {
                ContentUnavailableView(
                    "No requests",
                    systemImage: "bell.badge",
                    description: Text("New friend requests and group invites will show up here.")
                )
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(viewModel.requests) { request in
                            requestRow(request)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 28)
                }
            }
        }
        .navigationTitle("Invites")
        .task {
            await viewModel.loadRequests()
        }
        .safeAreaInset(edge: .bottom) {
            bannerMessage
        }
        .tinyMeetPageBackground()
    }

    @ViewBuilder
    private func requestRow(_ request: InviteRequestItem) -> some View {
        switch request {
        case .friend(let friendRequest):
            friendRequestRow(friendRequest, request: request)
        case .group(let groupInvite):
            groupInviteRow(groupInvite, request: request)
        }
    }

    // swiftlint:disable function_body_length
    private func friendRequestRow(_ request: UserProfile, request item: InviteRequestItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
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
                    Text(request.displayName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("@\(request.username)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let age = request.age {
                        Text("Age \(age)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let bio = request.bio, !bio.isEmpty {
                        Text(bio)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)
            }

            HStack(spacing: 10) {
                Button {
                    Task {
                        await viewModel.accept(item)
                    }
                } label: {
                    if viewModel.isResponding(item) {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Accept", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(TinyMeetPrimaryButtonStyle())
                .disabled(viewModel.isResponding(item))

                Button {
                    Task {
                        await viewModel.reject(item)
                    }
                } label: {
                    Label("Reject", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TinyMeetSecondaryButtonStyle())
                .disabled(viewModel.isResponding(item))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }
    // swiftlint:enable function_body_length

    // swiftlint:disable function_body_length
    private func groupInviteRow(_ invite: GroupInvite, request item: InviteRequestItem) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(TinyMeetTheme.playfulGradient)
                        .frame(width: 52, height: 52)

                    Image(systemName: "person.3.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(invite.groupName)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text("Group invite")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    if let ownerUID = invite.ownerUID, !ownerUID.isEmpty {
                        Text("Owner @\(ownerUID)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    if let summary = invite.groupSummary, !summary.isEmpty {
                        Text(summary)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                    }
                }

                Spacer(minLength: 0)
            }

            Label("Pending group invite", systemImage: "bell.badge")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(TinyMeetTheme.accent)

            HStack(spacing: 10) {
                Button {
                    Task {
                        await viewModel.accept(item)
                    }
                } label: {
                    if viewModel.isResponding(item) {
                        ProgressView()
                            .controlSize(.small)
                            .frame(maxWidth: .infinity)
                    } else {
                        Label("Accept", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(TinyMeetPrimaryButtonStyle())
                .disabled(viewModel.isResponding(item))

                Button {
                    Task {
                        await viewModel.reject(item)
                    }
                } label: {
                    Label("Reject", systemImage: "xmark.circle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TinyMeetSecondaryButtonStyle())
                .disabled(viewModel.isResponding(item))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }
    // swiftlint:enable function_body_length

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
    NavigationStack {
        FriendRequestsView(viewModel: FriendRequestsViewModel.makeDefault())
    }
}
