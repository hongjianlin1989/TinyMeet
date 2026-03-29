import SwiftUI

enum TinyMeetTheme {
    static let accent = Color(red: 0.98, green: 0.49, blue: 0.66)
    static let sunshine = Color(red: 1.00, green: 0.86, blue: 0.47)
    static let sky = Color(red: 0.54, green: 0.79, blue: 0.98)
    static let mint = Color(red: 0.57, green: 0.87, blue: 0.71)
    static let lavender = Color(red: 0.75, green: 0.68, blue: 0.98)
    static let peach = Color(red: 1.00, green: 0.74, blue: 0.62)

    static let pageTop = Color(red: 1.00, green: 0.97, blue: 0.90)
    static let pageBottom = Color(red: 0.93, green: 0.97, blue: 1.00)
    static let card = Color.white.opacity(0.92)
    static let cardBorder = Color.white.opacity(0.55)
    static let badge = Color.white.opacity(0.9)
    static let shadow = Color(red: 0.72, green: 0.67, blue: 0.90).opacity(0.18)

    static let backgroundGradient = LinearGradient(
        colors: [pageTop, pageBottom],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let heroGradient = LinearGradient(
        colors: [accent, peach, sunshine],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let playfulGradient = LinearGradient(
        colors: [sky, accent, lavender],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

struct TinyMeetPageBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TinyMeetTheme.backgroundGradient.ignoresSafeArea())
    }
}

struct TinyMeetCardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(TinyMeetTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(TinyMeetTheme.cardBorder, lineWidth: 1.5)
            }
            .shadow(color: TinyMeetTheme.shadow, radius: 16, x: 0, y: 8)
    }
}

struct TinyMeetPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline.weight(.bold))
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(TinyMeetTheme.playfulGradient)
            )
            .shadow(
                color: TinyMeetTheme.shadow.opacity(configuration.isPressed ? 0.10 : 0.22),
                radius: configuration.isPressed ? 6 : 12,
                x: 0,
                y: configuration.isPressed ? 3 : 8
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(
                .spring(response: 0.22, dampingFraction: 0.75),
                value: configuration.isPressed
            )
    }
}

struct TinyMeetSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(TinyMeetTheme.accent)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                Capsule(style: .continuous)
                    .fill(TinyMeetTheme.badge)
            )
            .overlay {
                Capsule(style: .continuous)
                    .stroke(TinyMeetTheme.accent.opacity(0.22), lineWidth: 1)
            }
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(
                .spring(response: 0.22, dampingFraction: 0.75),
                value: configuration.isPressed
            )
    }
}

extension View {
    func tinyMeetPageBackground() -> some View {
        modifier(TinyMeetPageBackground())
    }

    func tinyMeetCardStyle() -> some View {
        modifier(TinyMeetCardStyle())
    }
}
