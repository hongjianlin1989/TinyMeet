import CoreLocation
import Foundation
import MapKit

struct AddressSuggestion: Identifiable, Equatable {
    let title: String
    let subtitle: String

    var id: String {
        [title, subtitle].joined(separator: "|")
    }

    var displayText: String {
        let trimmedSubtitle = subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmedSubtitle.isEmpty ? title : "\(title), \(trimmedSubtitle)"
    }
}

struct ResolvedAddressLocation: Equatable {
    let suggestion: AddressSuggestion
    let latitude: Double
    let longitude: Double

    var displayText: String {
        suggestion.displayText
    }
}

@MainActor
protocol AddressSearchServicing {
    func suggestions(for query: String) async throws -> [AddressSuggestion]
    func resolve(_ suggestion: AddressSuggestion) async throws -> ResolvedAddressLocation
}

@MainActor
final class AppleAddressSearchService: NSObject, AddressSearchServicing, MKLocalSearchCompleterDelegate {
    private let completer: MKLocalSearchCompleter
    private var suggestionsContinuation: CheckedContinuation<[AddressSuggestion], Error>?

    override init() {
        let completer = MKLocalSearchCompleter()
        completer.resultTypes = .address
        self.completer = completer
        super.init()
        self.completer.delegate = self
    }

    func suggestions(for query: String) async throws -> [AddressSuggestion] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedQuery.isEmpty == false else {
            return []
        }

        if let suggestionsContinuation {
            suggestionsContinuation.resume(returning: [])
            self.suggestionsContinuation = nil
        }

        return try await withCheckedThrowingContinuation { continuation in
            suggestionsContinuation = continuation
            completer.queryFragment = trimmedQuery
        }
    }

    func resolve(_ suggestion: AddressSuggestion) async throws -> ResolvedAddressLocation {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = suggestion.displayText
        request.resultTypes = .address

        let response = try await MKLocalSearch(request: request).start()
        guard let placemark = response.mapItems.first?.placemark else {
            throw AddressSearchError.noResults
        }

        let coordinate = placemark.coordinate
        guard CLLocationCoordinate2DIsValid(coordinate) else {
            throw AddressSearchError.invalidCoordinate
        }

        return ResolvedAddressLocation(
            suggestion: suggestion,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        let uniqueSuggestions = completer.results.reduce(into: [AddressSuggestion]()) { partialResult, completion in
            let suggestion = AddressSuggestion(title: completion.title, subtitle: completion.subtitle)
            if partialResult.contains(suggestion) == false {
                partialResult.append(suggestion)
            }
        }

        suggestionsContinuation?.resume(returning: Array(uniqueSuggestions.prefix(6)))
        suggestionsContinuation = nil
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        suggestionsContinuation?.resume(throwing: error)
        suggestionsContinuation = nil
    }
}

enum AddressSearchError: LocalizedError {
    case noResults
    case invalidCoordinate

    var errorDescription: String? {
        switch self {
        case .noResults:
            return "We couldn't find that address. Try a different location."
        case .invalidCoordinate:
            return "That location did not include valid coordinates."
        }
    }
}
