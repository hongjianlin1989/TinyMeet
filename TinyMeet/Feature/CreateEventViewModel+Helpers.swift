import Foundation

extension CreateEventViewModel {
    static func formattedCoordinate(_ value: Double) -> String {
        coordinateFormatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    static let iso8601Formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()

    static let coordinateFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 6
        formatter.minimumFractionDigits = 0
        return formatter
    }()

    nonisolated static func defaultScheduledAt() -> Date {
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        return calendar.date(bySettingHour: 15, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    nonisolated static func defaultEndsAt(from scheduledAt: Date) -> Date {
        Calendar.current.date(byAdding: .hour, value: 2, to: scheduledAt) ?? scheduledAt.addingTimeInterval(7200)
    }

    nonisolated static func parseCoordinate(_ value: String, validRange: ClosedRange<Double>) -> Double? {
        let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let coordinate = Double(trimmedValue), validRange.contains(coordinate) else {
            return nil
        }

        return coordinate
    }

    nonisolated static let themeOptions: [ThemeOption] = [
        ThemeOption(emoji: "🎉", title: "Celebration"),
        ThemeOption(emoji: "🛝", title: "Playground"),
        ThemeOption(emoji: "☕️", title: "Coffee Chat"),
        ThemeOption(emoji: "🧺", title: "Picnic"),
        ThemeOption(emoji: "📚", title: "Story Time")
    ]

    nonisolated static let symbolOptions: [SymbolOption] = [
        SymbolOption(symbolName: "figure.2.and.child.holdinghands", title: "Playdate"),
        SymbolOption(symbolName: "balloon.2.fill", title: "Party"),
        SymbolOption(symbolName: "figure.play", title: "Active"),
        SymbolOption(symbolName: "book.closed.fill", title: "Learning"),
        SymbolOption(symbolName: "leaf.fill", title: "Outdoors")
    ]

    nonisolated static let tintOptions: [TintOption] = [
        TintOption(tintName: "mint", title: "Mint"),
        TintOption(tintName: "orange", title: "Peach"),
        TintOption(tintName: "pink", title: "Pink")
    ]
}

extension CreateEventViewModel.JoinVisibility {
    var apiValue: String {
        switch self {
        case .friends:
            return "friends"
        case .group:
            return "group"
        }
    }
}
