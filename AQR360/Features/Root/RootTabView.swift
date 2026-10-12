import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store

    @State private var selection: RootTab = .home

    /// Named `RootTab`, not `Tab` — a nested type named `Tab` shadows
    /// `SwiftUI.Tab` inside this type and breaks every tab declaration below.
    enum RootTab: Hashable {
        case home, market, assets, services, account
    }

    var body: some View {
        TabView(selection: $selection) {
            SwiftUI.Tab("Home", systemImage: "square.grid.2x2.fill", value: .home) {
                HomeView()
            }
            SwiftUI.Tab("Market", systemImage: "storefront.fill", value: .market) {
                MarketView()
            }
            SwiftUI.Tab("Assets", systemImage: "building.2.fill", value: .assets) {
                AssetsView()
            }
            SwiftUI.Tab("Services", systemImage: "wrench.and.screwdriver.fill", value: .services) {
                ServicesView()
            }
            SwiftUI.Tab("Account", systemImage: "person.crop.circle.fill", value: .account) {
                AccountView()
            }
        }
        .task { await store.load() }
    }
}

#Preview("Root") {
    RootTabView()
        .environment(AQRFixture.store)
}