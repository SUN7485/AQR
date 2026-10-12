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
enum APIEnvironment {

    /// Override for a future sandbox host. Currently unverified whether one
    /// exists; see API-FINDINGS §9.
    static var baseURLOverride: URL?

    static var baseURL: URL {
        if let baseURLOverride { return baseURLOverride }
        return URL(string: "https://api.aqr360.com/api/client/v1")!
    }
}

/// The observed response envelope.
///
/// ```json
/// { "data": …, "isSuccess": true, "errors": [],
///   "responseTime": "…", "responseStatus": 200 }
/// ```
struct APIEnvelope<Payload: Decodable>: Decodable {
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
enum AQRClientError: Error, Equatable {
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
        case .rateLimited, .transport: true
        case .server: true
        default: false
        }
    }
}

protocol HTTPGet: Sendable {
    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T
}

actor AQRClient: HTTPGet {

    private let session: URLSession
    private let decoder: JSONDecoder

    init(session: URLSession = .shared) {
        self.session = session
        // The API emits ISO-8601 with fractional seconds and a Z suffix.
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let raw = try decoder.singleValueContainer().decode(String.self)
            if let d = ISO8601DateFormatter.withFractional.date(from: raw) { return d }
            if let d = ISO8601DateFormatter.plain.date(from: raw) { return d }
            throw DecodingError.dataCorrupted(
                .init(codingPath: decoder.codingPath,
                      debugDescription: "Unrecognised ISO-8601 date: \(raw)"))
        }
        self.decoder = d
    }

    func get<T: Decodable>(_ path: String, as type: T.Type) async throws -> T {
        guard let url = URL(string: path, relativeTo: APIEnvironment.baseURL) else {
            throw AQRClientError.badURL(path)
        }

        var request = URLRequest(url: url)
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
            let retryAfter = (http.value(forHTTPHeaderField: "Retry-After"))
                .flatMap(TimeInterval.init)
            throw AQRClientError.rateLimited(retryAfter: retryAfter)
        default:
            throw AQRClientError.server(http.statusCode)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AQRClientError.decoding(String(describing: error))
        }
    }
}

extension ISO8601DateFormatter {
    static let withFractional: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static let plain: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()
}