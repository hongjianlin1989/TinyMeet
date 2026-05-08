import SwiftUI

struct DiscoverView: View {
    @StateObject private var viewModel: DiscoverViewModel

    init(viewModel: DiscoverViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.profiles.isEmpty && viewModel.hasActiveQuery {
                    ProgressView("Searching people...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let errorMessage = viewModel.errorMessage, viewModel.profiles.isEmpty {
                    ContentUnavailableView(
                        "Discover unavailable",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text(errorMessage)
                    )
                } else if !viewModel.hasActiveQuery {
                    ContentUnavailableView(
                        "Search people",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Find user profiles and add them as friends.")
                    )
                } else if viewModel.profiles.isEmpty {
                    ContentUnavailableView(
                        "No people found",
                        systemImage: "magnifyingglass",
                        description: Text("Try searching by username or bio.")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(viewModel.profiles) { profile in
                                DiscoverProfileRowView(
                                    viewModel: DiscoverProfileRowViewModel(
                                        profile: profile,
                                        isAdded: viewModel.hasAddedFriend(profile),
                                        isLoading: viewModel.isLoading,
                                        onAddFriendTapped: {
                                            Task {
                                                await viewModel.addFriend(profile)
                                            }
                                        }
                                    )
                                )
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.bottom, 28)
                    }
                }
            }
            .padding(viewModel.profiles.isEmpty ? 16 : 0)
            .navigationTitle("Discover People")
            .searchable(text: $viewModel.searchText, prompt: "Search user profiles")
            .onSubmit(of: .search) {
                Task {
                    await viewModel.searchProfiles()
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthToolbarButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                bannerMessage
            }
        }
        .tinyMeetPageBackground()
    }

    @ViewBuilder
    private var bannerMessage: some View {
        if let message = viewModel.successMessage {
            Text(message)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(TinyMeetTheme.mint)
                .clipShape(Capsule())
                .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
                .padding(.bottom, 10)
        } else if let errorMessage = viewModel.errorMessage, !errorMessage.isEmpty {
            Text(errorMessage)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(TinyMeetTheme.accent)
                .clipShape(Capsule())
                .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
                .padding(.bottom, 10)
        }
    }
}

#Preview {
    DiscoverView(viewModel: DiscoverViewModel.makeDefault())
}
