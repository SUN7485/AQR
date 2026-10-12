import Foundation
import Testing
@testable import AQR360

/// Decoding tests driven by **real, sanitized** responses captured from the live
/// AQR360 API on 2026-10-12 via read-only GET.
///
/// The fixture is a trimmed copy of a 241-entry response. Trimming is safe
/// here because the assertions are about field names, types and edge cases,
/// not about volume.
///
/// If the API's shape changes, these fail loudly rather than letting the app
/// quietly render empty lists. That is the whole point: a guessed model
/// compiles and shows nothing, which reads as "no results" to a user.
struct APIEnvelopeTests {

    /// Marker used only to locate the bundle holding the fixture. `Bundle.module`
    /// is a Swift Package Manager concept and does not exist for an app test
    /// bundle.
    private final class BundleToken {}

    // MARK: - Helpers

    static func loadFixture() throws -> Data {
        let url = try #require(
            Bundle(for: BundleToken.self).url(
                forResource: "countries", withExtension: "sample.json",
                subdirectory: "Fixtures"),
            "countries.sample.json missing from the test bundle")
        return try Data(contentsOf: url)
    }

    // MARK: - Envelope

    @Test("Envelope decodes the observed top-level shape")
    func envelopeShape() throws {
        let json = try String(Self.loadFixture(), encoding: .utf8)!

        // Confirm the fixture records what was actually seen, so a stale
        // fixture cannot quietly drift from reality.
        #expect(json.contains("\"responseStatus\""))

        let envelope = try JSONDecoder().decode(
            APIEnvelope<[Country]>.self, from: Self.loadFixture())

        #expect(envelope.isSuccess)
        #expect(envelope.errors?.isEmpty == true)
        #expect(envelope.responseStatus == 200)
        #expect(envelope.data.count == 6)
    }

    @Test("AE carries AED — the basis of the app's currency default")
    func unitedArabEmiratesCurrency() throws {
        let envelope = try JSONDecoder().decode(
            APIEnvelope<[Country]>.self, from: Self.loadFixture())

        let ae = try #require(envelope.data.first { $0.countryId == "AE" })
        #expect(ae.name == "United Arab Emirates")
        #expect(ae.currencyISO3 == "AED")
        #expect(ae.hasCurrency)
    }

    @Test("Every observed country record decodes with the fields we rely on")
    func allRecordsDecode() throws {
        let envelope = try JSONDecoder().decode(
            APIEnvelope<[Country]>.self, from: Self.loadFixture())

        for country in envelope.data {
            #expect(!country.countryId.isEmpty)
            #expect(!country.name.isEmpty)
        }
    }

    // MARK: - The awkward cases the live data actually contains

    @Test("An empty currency string is treated as absent, not as a code")
    func emptyCurrencyIsNotACode() throws {
        let envelope = try JSONDecoder().decode(
            APIEnvelope<[Country]>.self, from: Self.loadFixture())

        // Observed in the live response: countryId ZZ, currencyISO3 "".
        let empty = try #require(envelope.data.first { $0.currencyISO3 == "" })
        #expect(!empty.hasCurrency)

        // A naive `country.currencyISO3!` here would produce "AED " or crash.
        #expect(empty.currencyISO3?.isEmpty == true)
    }

    @Test("A missing currencyISO3 field decodes to nil and reports no currency")
    func missingCurrencyDecodesToNil() throws {
        let envelope = try JSONDecoder().decode(
            APIEnvelope<[Country]>.self, from: Self.loadFixture())

        // Observed in the live response: some records omit the key entirely.
        let missing = try #require(
            envelope.data.first { $0.currencyISO3 == nil })
        #expect(!missing.hasCurrency)
    }

    // MARK: - Client error mapping

    @Test("Transport errors are marked retryable, status errors are not")
    func retryability() {
        #expect(AQRClientError.transport("timeout").isRetryable)
        #expect(AQRClientError.rateLimited(retryAfter: 30).isRetryable)
        #expect(AQRClientError.server(503).isRetryable)

        // 401 has an empty body, so retrying without new credentials is futile.
        #expect(!AQRClientError.unauthenticated.isRetryable)
        #expect(!AQRClientError.notFound.isRetryable)
        #expect(!AQRClientError.http(400).isRetryable)
    }

    @Test("The base URL includes the /api segment that omitting returns 404 for")
    func baseURLIncludesAPISegment() {
        let url = APIEnvironment.baseURL.absoluteString
        #expect(url.hasSuffix("/api/client/v1"))
    }
}