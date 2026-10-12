import Foundation
import SwiftUI

/// App-wide configuration that the server owns.
///
/// Defaults are **verified** against the `aqr360.com` Nuxt runtime config, not
/// guessed:
///
/// ```
/// public: { currency: "AED", defaultCountryCode: "AE",
///            apiBase: "https://api.aqr360.com", ... }
/// ```
///
/// When the API is wired in, populate this from the server's own config
/// endpoint rather than recompiling. Every formatter in the app reads it, so
/// changing currency or market is a single assignment.
struct AppConfiguration: Sendable, Equatable {

    /// ISO 4217 code. AED for the markets AQR360 currently serves.
    var currencyCode: String

    /// ISO 3166-1 alpha-2. AE for the United Arab Emirates.
    var countryCode: String

    /// Presentation locale. en_AE groups digits the way the web product does and
    /// orders dates day-first.
    var locale: Locale { Locale(identifier: "en_\(countryCode)") }

    init(currencyCode: String, countryCode: String) {
        self.currencyCode = currencyCode
        self.countryCode = countryCode
    }

    static let verified = AppConfiguration(currencyCode: "AED", countryCode: "AE")
}

extension EnvironmentValues {
    /// Injected once at the root. Read with `@Environment(\.configuration)`.
    @Entry var configuration = AppConfiguration.verified
}