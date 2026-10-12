import Foundation
import Observation
import SwiftUI

/// Top-level destinations. Hoisted out of `RootTabView` so navigation state and
/// the router can reference it without depending on a view type.
enum AppTab: String, Hashable, CaseIterable, Identifiable {
    case home, market, assets, services, account

    var id: String { rawValue }

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

/// Destinations on the Assets stack.
///
/// One route type for the whole stack, so pushing an asset and then a Pro tool
/// is a single continuous back-stack rather than a nested `NavigationStack`.
enum AssetsRoute: Hashable {
    case asset(Asset, opening: AssetWorkspaceView.Tool?)
    case tool(AssetWorkspaceView.Tool)
}

/// Navigation state for the whole app.
///
/// Split out of `RootTabView` because three separate views bind to it. Held in
/// the environment so any view can push.
@MainActor
@Observable
final class AppRouter {

    var tab: AppTab = .home
    var marketPath: [Listing] = []
    var assetsPath: [AssetsRoute] = []

    // MARK: - Launch arguments
    //
    // The app can be opened straight onto a screen:
    //
    //     -startTab assets
    //     -startListing 0
    //     -startAsset 0
    //     -startAsset 0 -startTool contracts
    //
    // This is how CI reaches screens it cannot tap to. It is deliberately a
    // launch argument rather than a URL scheme: registering `CFBundleURLTypes`
    // would mean hand-maintaining an Info.plist, and deep links are worth doing
    // properly once the API can mint real share URLs.

    private var requestedTab: AppTab?
    private var requestedListingIndex: Int?
    private var requestedAssetIndex: Int?
    private var requestedTool: AssetWorkspaceView.Tool?

    init(arguments: [String] = ProcessInfo.processInfo.arguments) {
        func value(for flag: String) -> String? {
            guard let i = arguments.firstIndex(of: flag),
                  arguments.indices.contains(i + 1) else { return nil }
            return arguments[i + 1]
        }

        requestedTab = value(for: "-startTab").flatMap(AppTab.init(rawValue:))
        requestedListingIndex = value(for: "-startListing").flatMap(Int.init)
        requestedAssetIndex = value(for: "-startAsset").flatMap(Int.init)
        requestedTool = value(for: "-startTool").flatMap(AssetWorkspaceView.Tool.init(rawValue:))

        if requestedTab != nil { tab = requestedTab! }
    }

    /// Resolve launch arguments against loaded data. Called once after
    /// `AppStore.load()`, because listings and assets do not exist before then.
    func seed(from store: AppStore) {
        if let i = requestedListingIndex, store.listings.indices.contains(i) {
            tab = .market
            marketPath = [store.listings[i]]
        }

        if let i = requestedAssetIndex, store.assets.indices.contains(i) {
            tab = .assets
            assetsPath = [.asset(store.assets[i], opening: requestedTool)]
        }
    }

    // MARK: - Pushing

    func open(_ tool: AssetWorkspaceView.Tool) {
        assetsPath.append(.tool(tool))
    }

    func popToRoot() {
        marketPath = []
        assetsPath = []
    }
}