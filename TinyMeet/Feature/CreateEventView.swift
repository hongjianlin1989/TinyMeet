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
                    createButton
                }
                .padding(20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Create Playdate")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Create Playdate")
                .font(.title2.weight(.bold))

            Text("Set up a quick event and decide who can join.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            formField(title: "Title", text: $viewModel.title, prompt: "Playground")
            formField(title: "Location", text: $viewModel.location, prompt: "Central Park")
            formField(title: "Time", text: $viewModel.time, prompt: "Tomorrow 3pm")
            formField(title: "Kids Age", text: $viewModel.kidsAge, prompt: "3 - 5")
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
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
                                .foregroundStyle(viewModel.joinVisibility == option ? Color.accentColor : Color.secondary)

                            Text(option.rawValue)
                                .foregroundStyle(.primary)

                            Spacer()
                        }
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(18)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var createButton: some View {
        Button {
            viewModel.createEvent()
            dismiss()
        } label: {
            Text("Create")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
        }
        .buttonStyle(.borderedProminent)
        .disabled(!viewModel.isFormValid)
    }

    private func formField(title: String, text: Binding<String>, prompt: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)

            TextField(prompt, text: text)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color(.systemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

#Preview {
    CreateEventView(viewModel: CreateEventViewModel.makeDefault())
}
