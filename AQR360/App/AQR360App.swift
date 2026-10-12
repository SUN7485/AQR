import SwiftUI

@main
struct AQR360App: App {
    /// Live client, but only for the verified public read path. Everything
    /// else still renders from fixtures — `isDemoData` stays true until a
    /// real client actually serves the data, not merely because one exists.
    @State private var store = AQR360App.liveStore()

    static func liveStore() -> AppStore {
        AppStore(client: AQRClient())
    }
    @State private var router = AppRouter()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .environment(router)
                .environment(\.configuration, store.configuration)
                .tint(Brand.primary)
        }
    }
}