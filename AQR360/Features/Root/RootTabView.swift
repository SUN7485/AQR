import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store

    @State private var selection: Tab = .home

    enum Tab: Hashable {
        case home, market, assets, services, account
    }

    var body: some View {
        TabView(selection: $selection) {
            Tab("Home", systemImage: "square.grid.2x2.fill", value: .home) {
                HomeView()
            }
            Tab("Market", systemImage: "storefront.fill", value: .market) {
                MarketView()
            }
            Tab("Assets", systemImage: "building.2.fill", value: .assets) {
                AssetsView()
            }
            Tab("Services", systemImage: "wrench.and.screwdriver.fill", value: .services) {
                ServicesView()
            }
            Tab("Account", systemImage: "person.crop.circle.fill", value: .account) {
                AccountView()
            }
        }
        .task { await store.load() }
    }
}

#Preview("Root") {
    RootTabView()
        .environment(AppStore())
}