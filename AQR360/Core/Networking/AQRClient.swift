import Foundation

/// Read-only client for the AQR360 public API.
///
/// ## Scope
///
/// Only `GET`, only public endpoints, only paths whose response shape has been
/// observed against the live API. See `Docs/API-FINDINGS.md` for the evidence
/// behind every constant here.
///
/// This deliberately contains **no** authenticated request, no write, and no
/// payment path. Those need credentials we do not have.
///
/// ## Base URL
///
/// `https://api.aqr360.com/api/client/v1`. The `/api` segment is part of the
/// path — omitting it returns 404. That was measured, not assumed.
struct APIEnvironment: Sendable {

    /// Override for a future sandbox host. Currently unverified whether one
    /// exists; see API-FINDINGS §9.
    ///
    /// A `let`, not a `static var`, so there is no shared mutable state.
    var baseURLOverride: URL?

    init(baseURLOverride: URL? = nil) {
        self.baseURLOverride = baseURLOverride
    }

    static let live = APIEnvironment()

    var baseURL: URL {
        baseURLOverride ?? URL(string: "https://api.aqr360.com/api/client/v1")!
    }
}

/// The observed response envelope.
///
/// ```json
/// { "data": …, "isSuccess": true, "errors": [],
///   "responseTime": "…", "responseStatus": 200 }
/// ```
struct APIEnvelope<Payload: Decodable & Sendable>: Decodable, Sendable {
    let data: Payload
    let isSuccess: Bool
    let errors: [String]?
    let responseStatus: Int?
}

/// Error cases the client itself raises. These describe *transport and status*
/// outcomes only, not the server's business errors.
///
/// Note from API-FINDINGS §4: a 401 carries an **empty body** with
/// `WWW-Authenticate: Bearer`. There is no envelope to decode, so
/// `.unauthenticated` must not attempt to parse one.
enum AQRClientError: Error, Equatable, Sendable {
    case badURL(String)
    case http(Int)
    case unauthenticated
    case notFound
    case rateLimited(retryAfter: TimeInterval?)
    case server(Int)
    case decoding(String)
    case transport(String)

    /// Whether retrying the same request could plausibly succeed.
    ///
    /// Only idempotent verbs on 429/5xx. The client issues GET only, so every
    /// request here is idempotent — but that is a property of this type, not a
    /// licence to add writes later.
    var isRetryable: Bool {
        switch self {
        case .rateLimited, .transport, .server: true
        default: false
        }
    }
}

/// Reads one endpoint. Parameterised so implementations need not be actors and
/// so any `Payload` crossing the boundary is required to be `Sendable`.
protocol HTTPGet: Sendable {
    func get<Payload: Decodable & Sendable>(_ path: String, as type: Payload.Type) async throws -> Payload
}

/// Formats the server's ISO-8601 timestamps.
///
/// `ISO8601DateFormatter` is not `Sendable`, so instances are created per use
/// rather than shared as statics. Cost is irrelevant next to a network round
/// trip, and this keeps strict concurrency clean without suppression.
enum AQRDates {

    static func parse(_ raw: String) -> Date? {
        let fractional = ISO8601DateFormatter()
        fractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = fractional.date(from: raw) { return date }

        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]
        return plain.date(from: raw)
    }
}

/// Read-only HTTP client.
///
/// A `struct` rather than an `actor`: URLSession is already thread-safe and
/// Sendable, so actor isolation bought nothing while forcing every payload
/// across an isolation boundary.
struct AQRClient: HTTPGet, Sendable {

    private let session: URLSession
    private let environment: APIEnvironment

    init(session: URLSession = .shared, environment: APIEnvironment = .live) {
        self.session = session
        self.environment = environment
    }

    func get<Payload: Decodable & Sendable>(_ path: String, as type: Payload.Type) async throws -> Payload {
        let url = Self.url(for: path, in: environment)
        guard url != nil else { throw AQRClientError.badURL(path) }

        var request = URLRequest(url: url!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 20

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw AQRClientError.transport(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw AQRClientError.transport("Non-HTTP response")
        }

        switch http.statusCode {
        case 200..<300:
            break
        case 401, 403:
            throw AQRClientError.unauthenticated
        case 404:
            throw AQRClientError.notFound
        case 429:
            throw AQRClientError.rateLimited(
                retryAfter: http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init))
        default:
            throw AQRClientError.server(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            guard let date = AQRDates.parse(raw) else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath,
                          debugDescription: "Unrecognised ISO-8601 date: \(raw)"))
            }
            return date
        }

        do {
            return try decoder.decode(Payload.self, from: data)
        } catch {
            throw AQRClientError.decoding(String(describing: error))
        }
    }

    /// Built by concatenation rather than `URL(string:relativeTo:)`, which is
    /// awkward when the base carries no trailing slash.
    static func url(for path: String, in environment: APIEnvironment) -> URL? {
        let base = environment.baseURL.absoluteString
        let trimmedBase = base.hasSuffix("/") ? String(base.dropLast()) : base
        let suffix = path.hasPrefix("/") ? String(path.dropFirst()) : path
        return URL(string: "\(trimmedBase)/\(suffix)")
    }
}