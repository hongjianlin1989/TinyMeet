import SwiftUI

// swiftlint:disable type_body_length
struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: CreateEventViewModel

    init(viewModel: CreateEventViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    headerSection
                    modeSection
                    inputSection
                    if viewModel.isPrivateEvent {
                        audienceSection
                    }
                    if let errorMessage = viewModel.errorMessage {
                        errorCard(message: errorMessage)
                    } else if let validationMessage = viewModel.validationMessage {
                        validationCard(message: validationMessage)
                    }
                    createButton
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Create Playdate")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                await viewModel.loadAudienceOptions()
            }
            .onChange(of: viewModel.scheduledAt) { _, _ in
                viewModel.syncEndsAtIfNeeded()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                    .buttonStyle(TinyMeetSecondaryButtonStyle())
                }
            }
        }
        .tinyMeetPageBackground()
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Create Playdate")
                .font(.title2.weight(.bold))

            Text("Create either a private playdate for friends/groups or a public event for the community.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyMeetTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)
    }

    private var modeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Event Type")
                .font(.headline)

            Picker("Event Type", selection: $viewModel.eventMode) {
                ForEach(CreateEventViewModel.EventMode.allCases) { mode in
                    Text(mode.rawValue).tag(mode)
                }
            }
            .pickerStyle(.segmented)
        }
        .padding(18)
        .tinyMeetCardStyle()
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            formField(title: "Title", text: $viewModel.title, prompt: "Playground")
            locationFieldSection
            formField(title: "Kids Age", text: $viewModel.kidsAge, prompt: "3 - 5")

            VStack(alignment: .leading, spacing: 12) {
                Text("Schedule")
                    .font(.headline)

                DatePicker(
                    "Date",
                    selection: $viewModel.scheduledAt,
                    in: Date()...,
                    displayedComponents: .date
                )
                .labelsHidden()
                .datePickerStyle(.graphical)
                .padding(.horizontal, 6)
                .padding(.vertical, 8)
                .background(TinyMeetTheme.badge)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                HStack(alignment: .top, spacing: 12) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Begin Time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "Begin Time",
                            selection: $viewModel.scheduledAt,
                            in: Date()...,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TinyMeetTheme.badge)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("End Time")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        DatePicker(
                            "End Time",
                            selection: $viewModel.endsAt,
                            in: viewModel.scheduledAt...,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(.compact)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TinyMeetTheme.badge)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Summary")
                    .font(.headline)

                TextField("A fun private playdate for local families.", text: $viewModel.summary, axis: .vertical)
                    .lineLimit(3...5)
                    .textInputAutocapitalization(.sentences)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(TinyMeetTheme.badge)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }

            if viewModel.isPublicEvent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Event URL")
                        .font(.headline)

                    TextField("https://tinymeet.app/events/spring-picnic", text: $viewModel.eventURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .autocorrectionDisabled()
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(TinyMeetTheme.badge)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
            }
        }
        .padding(18)
        .tinyMeetCardStyle()
    }

    private var audienceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Who can join")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(CreateEventViewModel.JoinVisibility.allCases) { option in
                    Button {
                        viewModel.selectJoinVisibility(option)
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: viewModel.joinVisibility == option ? "largecircle.fill.circle" : "circle")
                                .font(.title3)
                                .foregroundStyle(viewModel.joinVisibility == option ? TinyMeetTheme.accent : Color.secondary)

                            Text(option.rawValue)
                                .foregroundStyle(.primary)
                                .fontWeight(.semibold)

                            Spacer()
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(viewModel.joinVisibility == option ? TinyMeetTheme.badge : Color.white.opacity(0.55))
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.joinVisibility == .friends {
                if viewModel.isLoadingOptions && viewModel.friends.isEmpty {
                    ProgressView("Loading friends...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.friends.isEmpty {
                    Text("No friends available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Friends")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        ForEach(viewModel.friends) { friend in
                            Button {
                                viewModel.toggleFriendSelection(friend)
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: viewModel.selectedFriendIDs.contains(friend.id) ? "checkmark.circle.fill" : "circle")
                                        .font(.title3)
                                        .foregroundStyle(viewModel.selectedFriendIDs.contains(friend.id) ? TinyMeetTheme.accent : Color.secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(friend.displayName)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(.primary)

                                        Text("@\(friend.username)")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()
                                }
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(viewModel.selectedFriendIDs.contains(friend.id) ? TinyMeetTheme.badge : Color.white.opacity(0.55))
                                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }

            if viewModel.shouldShowGroupPicker {
                if viewModel.isLoadingOptions && viewModel.availableGroups.isEmpty {
                    ProgressView("Loading groups...")
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if viewModel.availableGroups.isEmpty {
                    Text("No groups available yet.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Choose Group")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)

                        Picker("Choose Group", selection: $viewModel.selectedGroupID) {
                            ForEach(viewModel.availableGroups) { group in
                                Text(group.name).tag(Optional(group.id))
                            }
                        }
                        .pickerStyle(.menu)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(TinyMeetTheme.badge)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }

            Text(viewModel.automaticInviteSummary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .tinyMeetCardStyle()
    }

    private var createButton: some View {
        Button {
            Task {
                let didCreate = await viewModel.createEvent()
                if didCreate {
                    dismiss()
                }
            }
        } label: {
            if viewModel.isSubmitting {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity)
            } else {
                Text(viewModel.isPublicEvent ? "Create Public Event" : "Create Private Playdate")
            }
        }
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting || (viewModel.isPrivateEvent && viewModel.isLoadingOptions))
    }

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TinyMeetTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func validationCard(message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TinyMeetTheme.badge, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var locationFieldSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Location")
                .font(.headline)

            TextField(
                "Start typing an address",
                text: Binding(
                    get: { viewModel.location },
                    set: { viewModel.updateLocationQuery($0) }
                )
            )
            .textInputAutocapitalization(.words)
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(TinyMeetTheme.badge)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            if viewModel.isSearchingLocations {
                HStack(spacing: 8) {
                    ProgressView()
                        .controlSize(.small)
                    Text("Finding matching addresses...")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else if viewModel.locationSuggestions.isEmpty == false {
                VStack(spacing: 8) {
                    ForEach(viewModel.locationSuggestions) { suggestion in
                        Button {
                            Task {
                                await viewModel.selectLocationSuggestion(suggestion)
                            }
                        } label: {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(suggestion.title)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                if suggestion.subtitle.isEmpty == false {
                                    Text(suggestion.subtitle)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(Color.white.opacity(0.55))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let coordinateSummary = viewModel.locationCoordinateSummary {
                Text(coordinateSummary)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(TinyMeetTheme.sky)
            } else if viewModel.isPrivateEvent {
                Text("Choose a suggested location to automatically save latitude and longitude for this playdate.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func formField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            TextField(prompt, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(TinyMeetTheme.badge)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }

}
// swiftlint:enable type_body_length

#Preview {
    CreateEventView(viewModel: CreateEventViewModel.makeDefault())
}
