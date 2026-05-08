import Foundation

struct DiscoverProfileRowViewModel {
    let profile: UserProfile
    let isAdded: Bool
    let isLoading: Bool
    let onAddFriendTapped: () -> Void

    init(
        profile: UserProfile,
        isAdded: Bool,
        isLoading: Bool,
        onAddFriendTapped: @escaping () -> Void = {}
    ) {
        self.profile = profile
        self.isAdded = isAdded
        self.isLoading = isLoading
        self.onAddFriendTapped = onAddFriendTapped
    }

    var displayName: String {
        return profile.displayName.isEmpty ? profile.username : profile.displayName
    }

    var usernameText: String {
        "@\(profile.username)"
    }

    var ageText: String? {
        guard let age = profile.age else {
            return nil
        }

        return "Age \(age)"
    }

    var bioText: String? {
        guard let bio = profile.bio?.trimmingCharacters(in: .whitespacesAndNewlines),
              bio.isEmpty == false else {
            return nil
        }

        return bio
    }

    var addFriendButtonTitle: String {
        isAdded ? "Friend Added" : "Add Friend"
    }

    var addFriendButtonSystemImage: String {
        isAdded ? "checkmark.circle.fill" : "person.badge.plus"
    }

    var isAddFriendDisabled: Bool {
        isAdded || isLoading
    }

    func addFriendTapped() {
        onAddFriendTapped()
    }
}
