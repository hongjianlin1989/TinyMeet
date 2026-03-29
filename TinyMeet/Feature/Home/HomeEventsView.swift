import SwiftUI

struct HomeEventsView: View {
    @StateObject private var viewModel: HomeEventsViewModel

    init(viewModel: HomeEventsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Finding nearby fun...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                    ContentUnavailableView(
                        "Nearby events unavailable",
                        systemImage: "party.popper.fill",
                        description: Text(errorMessage)
                    )
                } else if viewModel.events.isEmpty {
                    ContentUnavailableView(
                        "No nearby events yet",
                        systemImage: "figure.and.child.holdinghands",
                        description: Text("Check back soon for playful meet-ups around you.")
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            heroSection

                            ForEach(viewModel.events) { event in
                                eventCard(event)
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .padding(viewModel.events.isEmpty ? 16 : 0)
            .navigationTitle("Home")
            .task {
                await viewModel.loadNearbyEvents()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Refresh") {
                        Task {
                            await viewModel.refreshNearbyEvents()
                        }
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                    .disabled(viewModel.isLoading)
                }
            }
        }
        .tinyMeetPageBackground()
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Nearby events for kids")
                .font(.title2.weight(.bold))

            Text("Discover playful meet-ups, make new friends, and plan your next family outing.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyMeetTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)
    }

    private func eventCard(_ event: NearbyEvent) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Text(event.themeEmoji)
                    .font(.system(size: 34))
                    .frame(width: 56, height: 56)
                    .background(TinyMeetTheme.badge)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    Text(event.title)
                        .font(.headline)

                    Label(event.locationName, systemImage: "mappin.and.ellipse")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 8)

                Text(event.distanceDescription)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TinyMeetTheme.badge)
                    .clipShape(Capsule())
            }

            Text(event.summary)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                detailPill(title: event.timeDescription, color: TinyMeetTheme.sky)
                detailPill(title: event.ageRange, color: TinyMeetTheme.mint)
            }

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.hostName)
                        .font(.subheadline.weight(.semibold))

                    Text(event.attendeeSummary)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button("Interested") {}
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .tinyMeetCardStyle()
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
    HomeEventsView(viewModel: HomeEventsViewModel.makeDefault())
}
