import Foundation

/// Deterministic preview dependencies, so previews never touch the network or
/// the shared store singleton.
@MainActor
enum AQRFixture {

    static var store: AppStore {
        let store = AppStore()
        store.seed(listings: SampleData.listings(),
                   assets: SampleData.assets(),
                   services: SampleData.services(),
                   tickets: SampleData.tickets())
        return store
    }

    static var emptyStore: AppStore {
        AppStore()
    }
}

extension AppStore {
    /// Preview/testing hook. Production loading goes through `load()`.
    func seed(listings: [Listing], assets: [Asset], services: [ServiceOffering], tickets: [ServiceTicket]) {
        self.seedListings(listings)
        self.seedAssets(assets)
        self.seedServices(services)
        self.seedTickets(tickets)
    }
}