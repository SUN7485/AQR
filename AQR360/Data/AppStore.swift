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

    // MARK: - Init

    init(configuration: AppConfiguration = .verified) {
        self.configuration = configuration
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