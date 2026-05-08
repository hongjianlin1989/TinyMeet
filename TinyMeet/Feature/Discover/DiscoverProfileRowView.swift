import SwiftUI

struct DiscoverProfileRowView: View {
    private let viewModel: DiscoverProfileRowViewModel

    init(viewModel: DiscoverProfileRowViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            profileHeader
            addFriendButton
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }

    private var profileHeader: some View {
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
                Text(viewModel.displayName)
                    .font(.headline)

                Text(viewModel.usernameText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)

                if let ageText = viewModel.ageText {
                    Text(ageText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                if let bioText = viewModel.bioText {
                    Text(bioText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
            }
        }
    }

    private var addFriendButton: some View {
        Button {
            viewModel.addFriendTapped()
        } label: {
            Label(
                viewModel.addFriendButtonTitle,
                systemImage: viewModel.addFriendButtonSystemImage
            )
        }
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(viewModel.isAddFriendDisabled)
    }
}

#Preview {
    DiscoverProfileRowView(
        viewModel: DiscoverProfileRowViewModel(
            profile: .mock,
            isAdded: false,
            isLoading: false
        )
    )
    .padding()
    .tinyMeetPageBackground()
}
