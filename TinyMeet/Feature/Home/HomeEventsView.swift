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
                } else if viewModel.filteredEvents.isEmpty {
                    ContentUnavailableView(
                        emptyStateTitle,
                        systemImage: emptyStateSystemImage,
                        description: Text(emptyStateDescription)
                    )
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            heroSection
                            filterSection

                            ForEach(viewModel.filteredEvents) { event in
                                HomeEventCardView(
                                    viewModel: HomeEventCardViewModel(event: event)
                                )
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
                    AuthToolbarButton()
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

    private var filterSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event type")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 10) {
                ForEach(NearbyEventVisibility.allCases) { filter in
                    filterButton(filter)
                }
            }
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .public:
            return "No public events yet"
        case .private:
            return "No private events yet"
        }
    }

    private var emptyStateDescription: String {
        switch viewModel.selectedFilter {
        case .public:
            return "Try again soon for new community events nearby."
        case .private:
            return "Private invitations and family-only meet-ups will show up here."
        }
    }

    private var emptyStateSystemImage: String {
        switch viewModel.selectedFilter {
        case .public:
            return "figure.and.child.holdinghands"
        case .private:
            return "person.2.badge.gearshape"
        }
    }

    private func filterButton(_ filter: NearbyEventVisibility) -> some View {
        Button {
            viewModel.selectFilter(filter)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: filter == .public ? "globe" : "lock.fill")
                    .font(.caption.weight(.bold))

                Text(filter.title)
                    .font(.subheadline.weight(.semibold))
            }
            .foregroundStyle(viewModel.selectedFilter == filter ? Color.white : Color.primary)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(viewModel.selectedFilter == filter ? TinyMeetTheme.accent : TinyMeetTheme.badge)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(TinyMeetTheme.cardBorder, lineWidth: viewModel.selectedFilter == filter ? 0 : 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    HomeEventsView(viewModel: HomeEventsViewModel.makeDefault())
}
