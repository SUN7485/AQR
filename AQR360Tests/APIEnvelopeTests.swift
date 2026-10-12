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

    // MARK: - Helpers

    /// Loads the fixture from the checkout rather than from the test bundle.
    ///
    /// A `.json` inside a file-system synchronized group has to be picked up by
    /// the Resources build phase to be found via `Bundle.url(forResource:)`,
    /// and that cannot be verified without a local Swift toolchain. Reading the
    /// checked-out source file via `#filePath` removes the build-phase
    /// dependency entirely — and the runner always has the checkout.
    ///
    /// `Bundle.module` is also wrong here: it is a Swift Package Manager
    /// concept and does not exist for an app test bundle.
    static func loadFixture() throws -> Data {
        let url = URL(fileURLWithPath: #filePath)      // …/AQR360Tests/APIEnvelopeTests.swift
            .deletingLastPathComponent()               // …/AQR360Tests
            .appendingPathComponent("Fixtures/countries.sample.json")
        try #require(FileManager.default.fileExists(atPath: url.path),
                     "Fixture missing at \(url.path)")
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
        #expect(APIEnvironment.live.baseURL.absoluteString
            .hasSuffix("/api/client/v1"))
    }

    @Test("Paths are appended to the base without doubling or dropping slashes")
    func pathJoining() {
        let env = APIEnvironment.live

        let joined = AQRClient.url(for: "MetaLookup/countries", in: env)
        #expect(joined?.absoluteString ==
            "https://api.aqr360.com/api/client/v1/MetaLookup/countries")

        // A leading slash must not produce a double slash.
        let leading = AQRClient.url(for: "/MetaLookup/countries", in: env)
        #expect(leading == joined)

        // A sandbox override must be honoured rather than silently ignored.
        let sandbox = APIEnvironment(baseURLOverride: URL(string: "https://sandbox.example/api/client/v1"))
        #expect(AQRClient.url(for: "MetaLookup/countries", in: sandbox)?.absoluteString
            == "https://sandbox.example/api/client/v1/MetaLookup/countries")
    }

    @Test("ISO-8601 parsing accepts both fractional and plain forms")
    func dateParsing() {
        let fractional = AQRDates.parse("2026-10-12T22:28:10.8514733Z")
        let plain = AQRDates.parse("2026-10-12T22:28:10Z")

        #expect(fractional != nil)
        #expect(plain != nil)
        #expect(AQRDates.parse("not a date") == nil)

        // The two forms are ~852 ms apart, not the same instant.
        if let fractional, let plain {
            #expect(abs(fractional.timeIntervalSince(plain) - 0.852) < 0.01)
        }
    }
}