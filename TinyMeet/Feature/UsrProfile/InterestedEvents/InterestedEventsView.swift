import SwiftUI

struct InterestedEventsView: View {
    @StateObject private var viewModel: InterestedEventsViewModel

    init(viewModel: InterestedEventsViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        List {
            Section {
                Picker("Filter", selection: $viewModel.selectedFilter) {
                    ForEach(InterestedEventsViewModel.Filter.allCases) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
            }
            .listRowBackground(Color.clear)

            if viewModel.isLoading {
                Section {
                    HStack {
                        Spacer()
                        ProgressView("Loading")
                        Spacer()
                    }
                }
                .listRowBackground(Color.clear)
            } else if let errorMessage = viewModel.errorMessage {
                Section {
                    ContentUnavailableView(
                        "Couldn’t load interested events",
                        systemImage: "exclamationmark.triangle",
                        description: Text(errorMessage)
                    )
                }
                .listRowBackground(Color.clear)
            } else if viewModel.filteredEvents.isEmpty {
                Section {
                    ContentUnavailableView(
                        "No interested events yet",
                        systemImage: "heart",
                        description: Text("Tap Interested on events to see them here.")
                    )
                }
                .listRowBackground(Color.clear)
            } else {
                Section {
                    ForEach(viewModel.filteredEvents) { event in
                        interestedEventRow(event)
                    }
                }
            }
        }
        .listStyle(.plain)
        .navigationTitle("Interested Events")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.loadInterestedEvents()
        }
        .tinyMeetPageBackground()
    }

    private func interestedEventRow(_ event: InterestedEventRow) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(event.visibility == .private ? TinyMeetTheme.playfulGradient : TinyMeetTheme.heroGradient)
                    .frame(width: 48, height: 48)

                Image(systemName: event.visibility == .private ? "lock.fill" : "globe")
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event.title)
                    .font(.headline)

                Text(event.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.bold))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 6)
        .contentShape(Rectangle())
    }
}

#Preview {
    NavigationStack {
        InterestedEventsView(viewModel: InterestedEventsViewModel.makeDefault())
    }
}
