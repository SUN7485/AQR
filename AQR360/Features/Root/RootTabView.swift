import SwiftUI

struct RootTabView: View {
    @Environment(AppStore.self) private var store

    @State private var selection: RootTab

    /// Named `RootTab`, not `Tab` — a nested type named `Tab` shadows
    /// `SwiftUI.Tab` inside this type and breaks every tab declaration below.
    enum RootTab: String, Hashable, CaseIterable {
        case home, market, assets, services, account

        var title: String {
            switch self {
            case .home: "Home"
            case .market: "Market"
            case .assets: "Assets"
            case .services: "Services"
            case .account: "Account"
            }
        }

        var systemImage: String {
            switch self {
            case .home: "square.grid.2x2.fill"
            case .market: "storefront.fill"
            case .assets: "building.2.fill"
            case .services: "wrench.and.screwdriver.fill"
            case .account: "person.crop.circle.fill"
            }
        }
    }

    /// Launch with `-startTab assets` (or `home`, `market`, `services`,
    /// `account`) to open directly on that tab.
    ///
    /// This is how CI captures one screenshot per tab: it drives the real app
    /// instead of guessing at navigation, so the shots cannot drift from what
    /// the app actually renders.
    private static func requestedTab() -> RootTab {
        let args = ProcessInfo.processInfo.arguments
        guard let flag = args.firstIndex(of: "-startTab"),
              args.indices.contains(flag + 1),
              let tab = RootTab(rawValue: args[flag + 1])
        else { return .home }
        return tab
    }

    init() {
        _selection = State(initialValue: Self.requestedTab())
    }

    var body: some View {
        TabView(selection: $selection) {
            ForEach(RootTab.allCases, id: \.self) { tab in
                SwiftUI.Tab(tab.title, systemImage: tab.systemImage, value: tab) {
                    content(for: tab)
                }
            }
        }
        .task { await store.load() }
    }

    @ViewBuilder
    private func content(for tab: RootTab) -> some View {
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
}