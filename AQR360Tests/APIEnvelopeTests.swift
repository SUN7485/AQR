import Foundation
import XCTest
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
///
/// ## Why XCTest and not Swift Testing
///
/// The Swift Testing macros (`#require`, `#expect`) failed to compile here with
/// "No exact matches in call to initializer". There is no local Swift toolchain
/// on this machine to iterate against, so the safest choice is the API with no
/// macro expansion involved. Assertions are `XCTAssert*` and unwrapping is
/// `XCTUnwrap`.
final class APIEnvelopeTests: XCTestCase {

    enum FixtureError: Error, CustomStringConvertible {
        case missing(String)
        var description: String {
            switch self {
            case .missing(let path): "Fixture missing at \(path)"
            }
        }
    }

    // MARK: - Helpers

    /// Loads the fixture from the checkout rather than from the test bundle.
    ///
    /// A `.json` inside a file-system synchronized group has to be picked up by
    /// the Resources build phase to be found via `Bundle.url(forResource:)`,
    /// which cannot be verified without a local Swift toolchain. Reading the
    /// checked-out source via `#filePath` removes that dependency entirely — and
    /// the runner always has the checkout.
    static func loadFixture() throws -> Data {
        let url = URL(fileURLWithPath: #filePath)      // …/AQR360Tests/APIEnvelopeTests.swift
            .deletingLastPathComponent()               // …/AQR360Tests
            .appendingPathComponent("Fixtures/countries.sample.json")
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw FixtureError.missing(url.path)
        }
        return try Data(contentsOf: url)
    }

    static func decodeFixture() throws -> APIEnvelope<[Country]> {
        try JSONDecoder().decode(APIEnvelope<[Country]>.self, from: try loadFixture())
    }

    // MARK: - Envelope

    func testEnvelopeShape() throws {
        let envelope = try Self.decodeFixture()

        XCTAssertTrue(envelope.isSuccess)
        XCTAssertEqual(envelope.errors ?? [], [])
        XCTAssertEqual(envelope.responseStatus, 200)
        XCTAssertEqual(envelope.data.count, 6)
    }

    func testUnitedArabEmiratesCarriesAED() throws {
        let envelope = try Self.decodeFixture()

        let ae = try XCTUnwrap(envelope.data.first { $0.countryId == "AE" })
        XCTAssertEqual(ae.name, "United Arab Emirates")
        XCTAssertEqual(ae.currencyISO3, "AED")
        XCTAssertTrue(ae.hasCurrency)
    }

    func testEveryRecordDecodesWithRequiredFields() throws {
        let envelope = try Self.decodeFixture()

        for country in envelope.data {
            XCTAssertFalse(country.countryId.isEmpty, "empty countryId")
            XCTAssertFalse(country.name.isEmpty, "empty name for \(country.countryId)")
        }
    }

    // MARK: - The awkward cases the live data actually contains

    /// Observed in the real response: `countryId: "ZZ"` with `currencyISO3: ""`.
    /// A naive `currencyISO3!` would produce a bogus "currency".
    func testEmptyCurrencyStringIsTreatedAsAbsent() throws {
        let envelope = try Self.decodeFixture()

        let empty = try XCTUnwrap(envelope.data.first { $0.currencyISO3 == "" })
        XCTAssertFalse(empty.hasCurrency)
        XCTAssertEqual(empty.currencyISO3?.isEmpty, true)
    }

    /// Observed in the real response: some records omit `currencyISO3` entirely.
    func testMissingCurrencyFieldDecodesToNil() throws {
        let envelope = try Self.decodeFixture()

        let missing = try XCTUnwrap(envelope.data.first { $0.currencyISO3 == nil })
        XCTAssertFalse(missing.hasCurrency)
    }

    // MARK: - Client error mapping

    func testRetryability() {
        XCTAssertTrue(AQRClientError.transport("timeout").isRetryable)
        XCTAssertTrue(AQRClientError.rateLimited(retryAfter: 30).isRetryable)
        XCTAssertTrue(AQRClientError.server(503).isRetryable)

        // A 401 has an empty body, so retrying without new credentials is futile.
        XCTAssertFalse(AQRClientError.unauthenticated.isRetryable)
        XCTAssertFalse(AQRClientError.notFound.isRetryable)
        XCTAssertFalse(AQRClientError.http(400).isRetryable)
    }

    // MARK: - URL construction

    /// The `/api` segment is part of the path; omitting it returns 404.
    func testBaseURLIncludesAPISegment() {
        XCTAssertTrue(APIEnvironment.live.baseURL.absoluteString
            .hasSuffix("/api/client/v1"))
    }

    func testPathJoining() {
        let env = APIEnvironment.live

        let joined = AQRClient.url(for: "MetaLookup/countries", in: env)
        XCTAssertEqual(joined?.absoluteString,
                       "https://api.aqr360.com/api/client/v1/MetaLookup/countries")

        // A leading slash must not produce a double slash.
        XCTAssertEqual(AQRClient.url(for: "/MetaLookup/countries", in: env), joined)

        // A future sandbox override must be honoured, not silently ignored.
        let sandbox = APIEnvironment(
            baseURLOverride: URL(string: "https://sandbox.example/api/client/v1"))
        XCTAssertEqual(
            AQRClient.url(for: "MetaLookup/countries", in: sandbox)?.absoluteString,
            "https://sandbox.example/api/client/v1/MetaLookup/countries")
    }

    // MARK: - Dates

    func testISODateParsingAcceptsBothForms() {
        let fractional = AQRDates.parse("2026-10-12T22:28:10.8514733Z")
        let plain = AQRDates.parse("2026-10-12T22:28:10Z")

        XCTAssertNotNil(fractional)
        XCTAssertNotNil(plain)
        XCTAssertNil(AQRDates.parse("not a date"))

        if let fractional, let plain {
            // ~852 ms apart, not the same instant.
            XCTAssertEqual(fractional.timeIntervalSince(plain), 0.8514733, accuracy: 0.001)
        }
    }
}