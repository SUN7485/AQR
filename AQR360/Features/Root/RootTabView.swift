import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store

    // Deliberately read from the environment, not a local @State copy.
    // Two instances meant seed() mutated a router the tabs never observed:
    // the tab switched, but the navigation path stayed empty.
    @Environment(AppRouter.self) private var router

    var body: some View {
        // `@Environment` gives no `$` projection for an @Observable, so bind it
        // locally before projecting.
        @Bindable var router = router

        TabView(selection: $router.tab) {
            ForEach(AppTab.allCases) { tab in
                SwiftUI.Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    content(for: tab)
                }
            }
        }
        .task {
            await store.load()
            // Launch arguments can only be resolved once the data exists.
            router.seed(from: store)
        }
    }

    @ViewBuilder
    private func content(for tab: AppTab) -> some View {
        switch tab {
        case .home: HomeView()
        case .market: MarketView()
        case .assets: AssetsView()
        case .services: ServicesView()
        case .account: AccountView()
        }
    }
}

#Preview("Root") {
    RootTabView()
        .environment(AQRFixture.store)
        .environment(AppRouter())
}