import SwiftUI

@main
struct AQR360App: App {
    @State private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environment(store)
                .tint(Brand.primary)
        }
    }
}