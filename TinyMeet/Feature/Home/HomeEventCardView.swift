import SwiftUI

struct HomeEventCardView: View {
    @StateObject private var viewModel: HomeEventCardViewModel

    init(viewModel: HomeEventCardViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
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

                        visibilityBadge
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

                Button("Interested") {
                    viewModel.interestedTapped()
                }
                .buttonStyle(TinyMeetSecondaryButtonStyle())
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
                visibility: .public
            )
        )
    )
    .padding()
    .tinyMeetPageBackground()
}
