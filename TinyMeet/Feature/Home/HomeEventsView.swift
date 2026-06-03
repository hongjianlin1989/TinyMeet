import SwiftUI

struct HomeEventsView: View {
    @StateObject private var viewModel: HomeEventsViewModel
    @State private var selectedEvent: NearbyEvent?
    @State private var pendingRequestedEventID: UUID?

    private let refreshTrigger: Int
    private let requestedEventID: UUID?
    private let onRequestedEventHandled: (UUID) -> Void

    init(
        viewModel: HomeEventsViewModel,
        refreshTrigger: Int = 0,
        requestedEventID: UUID? = nil,
        onRequestedEventHandled: @escaping (UUID) -> Void = { _ in }
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.refreshTrigger = refreshTrigger
        self.requestedEventID = requestedEventID
        self.onRequestedEventHandled = onRequestedEventHandled
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.events.isEmpty {
                    ProgressView("Finding nearby fun...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 18) {
                            heroSection
                            filterSection
                            publicFilterSection

                            if let errorMessage = viewModel.errorMessage, viewModel.events.isEmpty {
                                unavailableState(errorMessage: errorMessage)
                            } else if viewModel.filteredEvents.isEmpty {
                                emptyState
                            } else {
                                ForEach(viewModel.filteredEvents) { event in
                                    HomeEventCardView(
                                        viewModel: HomeEventCardViewModel(
                                            event: event,
                                            isInterestUpdating: viewModel.isUpdatingInterest(for: event.id),
                                            onInterestTapped: {
                                                Task {
                                                    await viewModel.toggleInterest(for: event.id)
                                                }
                                            }
                                        ),
                                        onTap: {
                                            selectedEvent = event
                                        }
                                    )
                                }
                            }
                        }
                        .padding(16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .padding(viewModel.isLoading && viewModel.events.isEmpty ? 16 : 0)
            .navigationTitle("Home")
            .task {
                await viewModel.loadNearbyEvents()
                stageRequestedEventIfNeeded(requestedEventID)
            }
            .task(id: refreshTrigger) {
                guard refreshTrigger > 0 else { return }
                await viewModel.refreshNearbyEvents()
                selectPendingRequestedEventIfPossible()
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthToolbarButton()
                }
            }
            .navigationDestination(item: $selectedEvent) { event in
                eventDetailView(for: event)
            }
            .onChange(of: requestedEventID) { _, newValue in
                stageRequestedEventIfNeeded(newValue)
            }
            .onChange(of: viewModel.events) { _, _ in
                selectPendingRequestedEventIfPossible()
            }
        }
        .tinyMeetPageBackground()
    }

    private func eventDetailView(for event: NearbyEvent) -> some View {
        let currentEvent = viewModel.event(for: event.id) ?? event

        return EventDetailView(
            viewModel: EventDetailViewModel(
                event: currentEvent,
                isInterestUpdating: viewModel.isUpdatingInterest(for: currentEvent.id),
                onInterestTapped: {
                    Task {
                        await viewModel.toggleInterest(for: currentEvent.id)
                    }
                }
            )
        )
    }

    private func stageRequestedEventIfNeeded(_ eventID: UUID?) {
        guard let eventID else { return }
        pendingRequestedEventID = eventID
        selectPendingRequestedEventIfPossible()
    }

    private func selectPendingRequestedEventIfPossible() {
        guard let pendingRequestedEventID,
              let requestedEvent = viewModel.event(for: pendingRequestedEventID) else {
            return
        }

        viewModel.selectFilter(requestedEvent.visibility)
        selectedEvent = requestedEvent
        self.pendingRequestedEventID = nil
        onRequestedEventHandled(requestedEvent.id)
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
                ForEach([NearbyEventVisibility.public, .private], id: \.id) { filter in
                    filterButton(filter)
                }
            }
        }
    }

    @ViewBuilder
    private var publicFilterSection: some View {
        if viewModel.selectedFilter == .public {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .firstTextBaseline) {
                    Text("External filters")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    Spacer(minLength: 12)

                    if viewModel.hasPublicFilters {
                        Button("Clear") {
                            Task {
                                await viewModel.clearPublicFilters()
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .buttonStyle(.plain)
                        .foregroundStyle(TinyMeetTheme.accent)
                    }
                }

                filterChipGroup(
                    title: "Category",
                    options: NearbyEventCategory.allCases,
                    selection: viewModel.selectedCategories,
                    onTap: { category in
                        Task {
                            await viewModel.toggleCategory(category)
                        }
                    }
                )

                filterChipGroup(
                    title: "Age Group",
                    options: NearbyEventAgeGroup.allCases,
                    selection: viewModel.selectedAgeGroups,
                    onTap: { ageGroup in
                        Task {
                            await viewModel.toggleAgeGroup(ageGroup)
                        }
                    }
                )

                if let publicFeedNoticeMessage = viewModel.publicFeedNoticeMessage {
                    Label(publicFeedNoticeMessage, systemImage: "location.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var emptyStateTitle: String {
        switch viewModel.selectedFilter {
        case .public:
            return "No external events yet"
        case .private:
            return "No private events yet"
        case .external:
            return "No external events yet"
        }
    }

    private var emptyStateDescription: String {
        switch viewModel.selectedFilter {
        case .public:
            return "Try adjusting the filters or check back soon for new external events nearby."
        case .private:
            return "Private invitations and family-only meet-ups will show up here."
        case .external:
            return "Try adjusting the filters or check back soon for new external events nearby."
        }
    }

    private var emptyStateSystemImage: String {
        switch viewModel.selectedFilter {
        case .public:
            return "ticket"
        case .private:
            return "person.2.badge.gearshape"
        case .external:
            return "ticket"
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label(emptyStateTitle, systemImage: emptyStateSystemImage)
        } description: {
            Text(emptyStateDescription)
        } actions: {
            Button("Reload events") {
                Task {
                    await viewModel.refreshNearbyEvents()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func unavailableState(errorMessage: String) -> some View {
        ContentUnavailableView {
            Label("Nearby events unavailable", systemImage: "party.popper.fill")
        } description: {
            Text(errorMessage)
        } actions: {
            Button("Reload events") {
                Task {
                    await viewModel.refreshNearbyEvents()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 24)
    }

    private func filterButton(_ filter: NearbyEventVisibility) -> some View {
        Button {
            viewModel.selectFilter(filter)
        } label: {
            HStack(spacing: 8) {
                let iconName: String = {
                    switch filter {
                    case .public:   return "ticket"
                    case .private:  return "lock.fill"
                    case .external: return "ticket"
                    }
                }()
                Image(systemName: iconName)
                    .font(.caption.weight(.bold))

                Text(filter == .public ? "External" : filter.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.9)
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

    private func filterChipGroup<Option: Identifiable & Hashable>(
        title: String,
        options: [Option],
        selection: [Option],
        onTap: @escaping (Option) -> Void
    ) -> some View where Option: CustomStringConvertible {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(options, id: \.id) { option in
                    let isSelected = selection.contains(option)

                    Button {
                        onTap(option)
                    } label: {
                        Text(option.description)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(isSelected ? Color.white : Color.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                            .frame(maxWidth: .infinity)
                            .background(isSelected ? TinyMeetTheme.accent : TinyMeetTheme.badge)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule()
                                    .stroke(TinyMeetTheme.cardBorder, lineWidth: isSelected ? 0 : 1)
                            }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    HomeEventsView(viewModel: HomeEventsViewModel.makeDefault())
}
