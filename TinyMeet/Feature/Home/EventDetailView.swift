import SwiftUI

struct EventDetailView: View {
    private let viewModel: EventDetailViewModel
    @State private var sharePayload: EventSharePayload?

    init(viewModel: EventDetailViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                heroCard
                highlightsCard
                aboutCard
                actionsCard
            }
            .padding(16)
            .padding(.bottom, 32)
        }
        .tinyMeetPageBackground()
        .navigationTitle("Event Detail")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $sharePayload) { payload in
            ShareSheetView(activityItems: payload.activityItems)
        }
    }

    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 14) {
                Text(viewModel.themeEmoji)
                    .font(.system(size: 42))
                    .frame(width: 72, height: 72)
                    .background(TinyMeetTheme.badge)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .top, spacing: 8) {
                        Text(viewModel.title)
                            .font(.title2.weight(.bold))
                            .multilineTextAlignment(.leading)

                        Spacer(minLength: 8)

                        visibilityBadge
                    }

                    Label(viewModel.locationName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Label(viewModel.timeDescription, systemImage: "clock.fill")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            Text(viewModel.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    private var highlightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Highlights")
                .font(.headline)

            VStack(spacing: 12) {
                detailRow(title: "Age Group", value: viewModel.ageRange, systemImage: "figure.and.child.holdinghands")
                detailRow(title: "Distance", value: viewModel.distanceDescription, systemImage: "location.fill")
                detailRow(title: "Host", value: viewModel.hostName, systemImage: "person.crop.circle.fill")
                detailRow(title: "Attendees", value: viewModel.attendeeSummary, systemImage: "person.2.fill")
            }
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About this event")
                .font(.headline)

            Text(viewModel.summary)
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .tinyMeetCardStyle()
    }

    @ViewBuilder
    private var actionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Actions")
                .font(.headline)

            Button {
                sharePayload = viewModel.sharePayload
            } label: {
                Label("Share Event", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(TinyMeetSecondaryButtonStyle())

            interestButton

            if let eventURL = viewModel.eventURL {
                Link(destination: eventURL) {
                    Label("Open Event Link", systemImage: "arrow.up.right.square")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(TinyMeetSecondaryButtonStyle())
            }
        }
        .padding(20)
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

    private func detailRow(title: String, value: String, systemImage: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(TinyMeetTheme.accent)
                .frame(width: 20)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text(value)
                    .font(.body.weight(.medium))
            }

            Spacer(minLength: 0)
        }
    }

    @ViewBuilder
    private var interestButton: some View {
        let label = Group {
            if viewModel.isInterestUpdating {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            } else {
                Label(viewModel.interestButtonTitle, systemImage: viewModel.interestButtonSystemImage)
                    .frame(maxWidth: .infinity)
            }
        }

        if viewModel.isInterested {
            Button {
                viewModel.interestedTapped()
            } label: {
                label
            }
            .buttonStyle(TinyMeetPrimaryButtonStyle())
            .disabled(viewModel.isInterestUpdating)
        } else {
            Button {
                viewModel.interestedTapped()
            } label: {
                label
            }
            .buttonStyle(TinyMeetSecondaryButtonStyle())
            .disabled(viewModel.isInterestUpdating)
        }
    }
}

#Preview {
    NavigationStack {
        EventDetailView(
            viewModel: EventDetailViewModel(
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
    }
}
