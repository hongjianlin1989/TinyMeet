import SwiftUI

struct HomeEventCardView: View {
    private let viewModel: HomeEventCardViewModel

    init(viewModel: HomeEventCardViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(viewModel.themeEmoji)
                    .font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(TinyMeetTheme.badge)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Text(viewModel.title)
                            .font(.headline)
                    }

                    Label(viewModel.locationName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(viewModel.distanceDescription)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TinyMeetTheme.badge)
                    .clipShape(Capsule())
            }

            Text(viewModel.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                detailPill(title: viewModel.timeDescription, color: TinyMeetTheme.sky)
                detailPill(title: viewModel.ageRange, color: TinyMeetTheme.mint)

                if let eventURL = viewModel.eventURL {
                    linkPill(destination: eventURL)
                }
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.hostName)
                        .font(.subheadline.weight(.semibold))

                    Text(viewModel.attendeeSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                interestButton
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
    }

    private var visibilityBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: viewModel.visibilitySymbolName)
                .font(.caption2.weight(.bold))

            Text(viewModel.visibilityTitle)
                .font(.caption2.weight(.bold))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(viewModel.visibilityBadgeColor)
        .foregroundStyle(.primary)
        .clipShape(Capsule())
    }

    private func detailPill(title: String, color: Color) -> some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(color.opacity(0.18))
            .foregroundStyle(.primary)
            .clipShape(Capsule())
    }

    private func linkPill(destination: URL) -> some View {
        Link("Link", destination: destination)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(TinyMeetTheme.peach.opacity(0.22))
            .foregroundStyle(TinyMeetTheme.accent)
            .clipShape(Capsule())
    }

    @ViewBuilder
    private var interestButton: some View {
        let buttonWidth: CGFloat = 150
        let buttonHeight: CGFloat = 44

        let label = Group {
            if viewModel.isInterestUpdating {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                Label(viewModel.interestButtonTitle, systemImage: viewModel.interestButtonSystemImage)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        if viewModel.isInterested {
            Button {
                viewModel.interestedTapped()
            } label: {
                label
            }
            .buttonStyle(TinyMeetPrimaryButtonStyle())
            .frame(width: buttonWidth, height: buttonHeight)
            .disabled(viewModel.isInterestUpdating)
        } else {
            Button {
                viewModel.interestedTapped()
            } label: {
                label
            }
            .buttonStyle(TinyMeetSecondaryButtonStyle())
            .frame(width: buttonWidth, height: buttonHeight)
            .disabled(viewModel.isInterestUpdating)
        }
    }
}

#Preview {
    HomeEventCardView(
        viewModel: HomeEventCardViewModel(
            event: NearbyEvent(
                title: "Playground Picnic Crew",
                locationName: "Central Park Playground",
                timeDescription: "Today · 4:00 PM",
                ageRange: "Ages 3-5",
                distanceDescription: "0.4 mi away",
                hostName: "Hosted by Mia",
                attendeeSummary: "8 families going",
                themeEmoji: "🛝",
                summary: "Meet other families for snacks, bubbles, and easy playground fun after nap time.",
                eventUrl: "https://tinymeet.app/events/playground-picnic-crew",
                isInterested: true,
                visibility: .public
            )
        )
    )
    .padding()
    .tinyMeetPageBackground()
}
