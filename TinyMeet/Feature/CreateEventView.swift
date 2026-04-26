import SwiftUI

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
                    inputSection
                    visibilitySection
                    if let errorMessage = viewModel.errorMessage {
                        errorCard(message: errorMessage)
                    }
                    createButton
                }
                .padding(20)
                .padding(.bottom, 24)
            }
            .navigationTitle("Create Playdate")
            .navigationBarTitleDisplayMode(.inline)
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

            Text("Set up a cheerful meet-up and decide who gets to join the fun.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(TinyMeetTheme.heroGradient)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: TinyMeetTheme.shadow, radius: 14, x: 0, y: 8)
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            formField(title: "Title", text: $viewModel.title, prompt: "Playground")
            formField(title: "Location", text: $viewModel.location, prompt: "Central Park")
            formField(title: "Time", text: $viewModel.time, prompt: "Tomorrow 3pm")
            formField(title: "Kids Age", text: $viewModel.kidsAge, prompt: "3 - 5")
        }
        .padding(18)
        .tinyMeetCardStyle()
    }

    private var visibilitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Who can join")
                .font(.headline)

            VStack(spacing: 12) {
                ForEach(CreateEventViewModel.JoinVisibility.allCases) { option in
                    Button {
                        viewModel.joinVisibility = option
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
                Text("Create")
            }
        }
        .buttonStyle(TinyMeetPrimaryButtonStyle())
        .disabled(!viewModel.isFormValid || viewModel.isSubmitting)
    }

    private func errorCard(message: String) -> some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .foregroundStyle(.white)
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(TinyMeetTheme.accent, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
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

#Preview {
    CreateEventView(viewModel: CreateEventViewModel.makeDefault())
}
