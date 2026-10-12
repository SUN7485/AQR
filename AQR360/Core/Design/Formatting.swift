import Foundation
import SwiftUI

// MARK: - Money

extension Decimal {

    /// Whole-unit money label in the configured currency.
    ///
    /// Fraction digits are dropped deliberately: at property magnitudes AED
    /// 185,000.00 carries no information and wraps to two lines in a stat tile.
    ///
    /// Always build money through this or `moneyLabel(_:locale:)` — never call
    /// `.currency(code:)` inline, so currency and rounding are decided once.
    func moneyLabel(
        _ currencyCode: String = AppConfiguration.verified.currencyCode,
        locale: Locale = AppConfiguration.verified.locale
    ) -> String {
        formatted(.currency(code: currencyCode).precision(.fractionLength(0)).locale(locale))
    }

    /// Compact form for dense tiles: AED 1.3M, AED 145K.
    ///
    /// Falls back to the full label below 10,000 so small amounts stay exact.
    func compactMoneyLabel(
        _ currencyCode: String = AppConfiguration.verified.currencyCode,
        locale: Locale = AppConfiguration.verified.locale
    ) -> String {
        let magnitude = abs(self)
        guard magnitude >= 10_000 else { return moneyLabel(currencyCode, locale: locale) }

        let style = Decimal.FormatStyle.Currency(code: currencyCode)
            .precision(.fractionLength(0))
            .locale(locale)

        // Take everything before the first digit as the symbol, then strip the
        // group separator the full form left behind. Filtering out non-digits
        // keeps the separator, so "AED 912,000" yields "AED ," and the compact
        // figure renders as "AED ,912K" instead of "AED 912K".
        let symbol = style.format(self)
            .prefix(while: { !$0.isNumber })
            .trimmingCharacters(in: .whitespaces)
            .trimmingCharacters(in: CharacterSet(charactersIn: ",.;'\u{2019}\u{00A0}\u{202F}"))
            .trimmingCharacters(in: .whitespaces)

        switch magnitude {
        case 1_000_000...:
            let value = (self / 1_000_000)
                .formatted(.number.precision(.fractionLength(0...1)).locale(locale))
            return "\(symbol) \(value)M"
        default:
            let value = (self / 1_000)
                .formatted(.number.precision(.fractionLength(0)).locale(locale))
            return "\(symbol) \(value)K"
        }
    }
}

// MARK: - Dates

extension Date {

    /// Day-first short date — 12 Mar 2027 under en_AE.
    func shortDate(_ locale: Locale = AppConfiguration.verified.locale) -> String {
        formatted(.dateTime.day().month(.abbreviated).year().locale(locale))
    }

    /// Month and year only — Mar 2027. Used where the day is noise.
    func monthYear(_ locale: Locale = AppConfiguration.verified.locale) -> String {
        formatted(.dateTime.month(.abbreviated).year().locale(locale))
    }

    /// "3 days ago" / "in 2 weeks".
    func relativeToNow(_ locale: Locale = AppConfiguration.verified.locale) -> String {
        formatted(.relative(presentation: .named).locale(locale))
    }
}

// MARK: - Numbers

extension Int {
    /// Grouped count — 5,200.
    func grouped(_ locale: Locale = AppConfiguration.verified.locale) -> String {
        formatted(.number.locale(locale))
    }
}

// MARK: - Strings

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