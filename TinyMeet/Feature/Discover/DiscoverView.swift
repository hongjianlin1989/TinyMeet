import SwiftUI

struct DiscoverView: View {
    @EnvironmentObject private var appSession: AppSession
    @EnvironmentObject private var deepLinkHandler: DeepLinkHandler
    @StateObject private var viewModel: DiscoverViewModel

    init(viewModel: DiscoverViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            Group {
                if appSession.isLoggedIn {
                    discoverContent
                        .searchable(text: $viewModel.searchText, prompt: "Search user profiles")
                        .onSubmit(of: .search) {
                            Task {
                                await viewModel.searchProfiles()
                            }
                        }
                } else {
                    loginRequiredOverlay
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(contentPadding)
            .navigationTitle("Discover People")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    AuthToolbarButton()
                }
            }
            .safeAreaInset(edge: .bottom) {
                if appSession.isLoggedIn {
                    bannerMessage
                }
            }
        }
        .tinyMeetPageBackground()
        .onAppear {
            viewModel.onAppear(isLoggedIn: appSession.isLoggedIn)
        }
        .onChange(of: appSession.isLoggedIn) { _, isLoggedIn in
            viewModel.authenticationStateChanged(isLoggedIn: isLoggedIn)
        }
    }

    @ViewBuilder
    private var discoverContent: some View {
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

    private var contentPadding: CGFloat {
        appSession.isLoggedIn && viewModel.profiles.isEmpty == false ? 0 : 16
    }

    private var loginRequiredOverlay: some View {
        overlayCard(
            titleKey: "Log in to use Discover",
            messageKey: "Log in to search profiles, find new people, and send friend requests.",
            buttonTitleKey: "login.submit",
            action: { deepLinkHandler.presentLogin() }
        )
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

    private func overlayCard(
        titleKey: LocalizedStringResource,
        messageKey: LocalizedStringResource,
        buttonTitleKey: LocalizedStringResource?,
        action: (() -> Void)?
    ) -> some View {
        VStack {
            Spacer()

            VStack(alignment: .leading, spacing: 12) {
                Text(titleKey)
                    .font(.headline)

                Text(messageKey)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if let buttonTitleKey, let action {
                    Button(action: action) {
                        Text(buttonTitleKey)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}

#Preview {
    DiscoverView(viewModel: DiscoverViewModel.makeDefault())
        .environmentObject(AppSession())
        .environmentObject(DeepLinkHandler())
}
