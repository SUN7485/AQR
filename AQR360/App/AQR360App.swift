import SwiftUI

@main
struct AQR360App: App {
    @State private var store = AppStore()
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