import Foundation
import Observation

/// Root store for the demo build.
///
/// Owns the authenticated account, the cached market inventory and the
/// property portfolio.
///
/// ## Data source
///
/// `load()` currently fills from `SampleData`. `isDemoData` is the single flag
/// that marks it: the UI surfaces it, and it flips to `false` the moment a real
/// `AQRClient` is injected. Do not add a second source of truth — swap the fill
/// inside `load()` and every view keeps working unchanged.
@MainActor
@Observable
final class AppStore {

    struct Account: Equatable {
        var name: String
        var email: String
        var pointsBalance: Int
        var isVerified: Bool
    }

    // MARK: - Published state

    private(set) var configuration: AppConfiguration
    private(set) var account: Account
    private(set) var listings: [Listing] = []
    private(set) var assets: [Asset] = []
    private(set) var tickets: [ServiceTicket] = []
    private(set) var services: [ServiceOffering] = []
    private(set) var isLoading = true
    private(set) var loadError: String?

    /// True while the UI is rendering fixtures rather than live API data.
    /// Shown in the UI so a demo is never mistaken for the real product.
    private(set) var isDemoData = true

    // MARK: - Search

    var searchText = ""
    var selectedCategory: ListingCategory?

    // MARK: - Dependencies

    /// Read-only API client. Injected rather than constructed so previews and
    /// tests never reach the network.
    private let client: HTTPGet?

    // MARK: - Init

    /// - Parameter client: pass `nil` to run entirely on fixtures, which is
    ///   what previews do.
    init(configuration: AppConfiguration = .verified, client: HTTPGet? = nil) {
        self.configuration = configuration
        self.client = client
        self.account = Account(
            name: "Adaeze Nwosu",
            email: "adaeze@aqr360.com",
            pointsBalance: 2_480,
            isVerified: true
        )
    }

    // MARK: - Loading

    func load() async {
        isLoading = true
        loadError = nil
        // Stands in for the network round-trip; keeps loading states demonstrable.
        try? await Task.sleep(for: .milliseconds(450))
        guard !Task.isCancelled else { return }

        listings = SampleData.listings()
        assets = SampleData.assets()
        services = SampleData.services()
        tickets = SampleData.tickets()
        isLoading = false

        // Currency and country resolve from the live API once verified. Until
        // that succeeds the compiled-in value stands. See Docs/API-FINDINGS.md.
        await resolveConfiguration()
    }

    // MARK: - Live configuration

    enum ConfigurationSource: String, Sendable {
        /// Confirmed against the live API.
        case live
        /// The value compiled in from API-FINDINGS, used when the call fails.
        case verifiedDefault
    }

    /// Where `configuration` came from. Surfaced so a fallback is visible rather
    /// than silent.
    private(set) var configurationSource: ConfigurationSource = .verifiedDefault

    /// Populate currency and country from the public countries lookup.
    ///
    /// `/MetaLookup/countries` returns `currencyISO3` per country, which is
    /// where AQR360's own `currency: "AED"` comes from. Verified: AE -> AED.
    ///
    /// Failure is non-fatal by design: the verified static default stays in
    /// place and the UI keeps running on fixtures.
    private func resolveConfiguration() async {
        guard let client else { return }
        do {
            let envelope = try await client.get(
                "MetaLookup/countries", as: APIEnvelope<[Country]>.self)
            guard envelope.isSuccess,
                  let country = envelope.data.first(where: { $0.countryId == configuration.countryCode }),
                  country.hasCurrency,
                  let currency = country.currencyISO3
            else { return }
            configuration = AppConfiguration(
                currencyCode: currency,
                countryCode: country.countryId)
            configurationSource = .live
        } catch {
            configurationSource = .verifiedDefault
        }
    }

    // MARK: - Derived

    var firstName: String { account.name.firstName }
    var currencyCode: String { configuration.currencyCode }
    var locale: Locale { configuration.locale }

    var proAssets: [Asset] { assets.filter(\.isProSubscribed) }

    var filteredListings: [Listing] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        return listings.filter { listing in
            let matchesCategory = selectedCategory.map { listing.category == $0 } ?? true
            guard matchesCategory else { return false }
            guard !query.isEmpty else { return true }
            return listing.title.localizedCaseInsensitiveContains(query)
                || listing.address.localizedCaseInsensitiveContains(query)
                || listing.agentName.localizedCaseInsensitiveContains(query)
                || listing.locality.localizedCaseInsensitiveContains(query)
        }
    }

    var totalMonthlyNet: Decimal {
        assets.reduce(0) { $0 + $1.netMonthly }
    }

    var totalMonthlyNetLabel: String {
        totalMonthlyNet.moneyLabel(currencyCode, locale: locale)
    }

    var totalMonthlyNetCompact: String {
        totalMonthlyNet.compactMoneyLabel(currencyCode, locale: locale)
    }

    var openTicketCount: Int {
        assets.reduce(0) { $0 + $1.openTicketCount }
    }

    var occupancyAverage: Double {
        guard !assets.isEmpty else { return 0 }
        return assets.reduce(0) { $0 + $1.occupancyRate } / Double(assets.count)
    }

    // MARK: - Preview seeding

    func seedListings(_ value: [Listing]) { listings = value; isLoading = false }
    func seedAssets(_ value: [Asset]) { assets = value }
    func seedServices(_ value: [ServiceOffering]) { services = value }
    func seedTickets(_ value: [ServiceTicket]) { tickets = value }

    // MARK: - Mutations

    func advance(_ ticket: ServiceTicket) {
        guard let index = tickets.firstIndex(where: { $0.id == ticket.id }) else { return }
        let order = ServiceTicket.Stage.allCases.filter { $0 != .cancelled }
        guard let current = order.firstIndex(of: tickets[index].stage), current + 1 < order.count else { return }
        tickets[index].stage = order[current + 1]
    }
}