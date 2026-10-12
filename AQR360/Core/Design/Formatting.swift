import Foundation

extension Decimal {

    /// Whole-unit money label.
    ///
    /// Cents are noise at property magnitudes — `$185,000.00` wraps to two lines
    /// in a stat tile where `$185,000` fits on one. Always build money labels
    /// through this rather than calling `.currency(code:)` inline, so rounding
    /// is decided once.
    var moneyLabel: String {
        formatted(.currency(code: "USD").precision(.fractionLength(0)))
    }
}

extension String {

    /// Given name, for greetings. Falls back to the full name rather than an
    /// empty string when there is no space to split on.
    var firstName: String {
        split(separator: " ").first.map { String($0) } ?? self
    }

    /// Up to two initials, for avatars.
    var initials: String {
        split(separator: " ")
            .prefix(2)
            .compactMap(\.first)
            .map(String.init)
            .joined()
    }
}