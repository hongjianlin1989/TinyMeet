import SwiftUI

struct HomeMapPanelCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .shadow(color: TinyMeetTheme.shadow, radius: 10, x: 0, y: 4)
    }
}

#Preview {
    ZStack {
        TinyMeetTheme.backgroundGradient.ignoresSafeArea()

        HomeMapPanelCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Selected playdate")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)

                Text("Playground Meetup")
                    .font(.headline)

                Text("Today · 4:00 PM")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
