import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store
    @State private var router = AppRouter()

    var body: some View {
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