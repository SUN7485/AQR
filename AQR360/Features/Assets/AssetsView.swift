import SwiftUI

struct AssetsView: View {
    @Environment(AppStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        // `@Environment` gives no `$` projection for an @Observable, so bind it
        // locally before projecting.
        @Bindable var router = router

        NavigationStack(path: $router.assetsPath) {
            ScrollView {
                LazyVStack(spacing: Metric.m) {
                    ForEach(store.assets) { asset in
                        NavigationLink(value: AssetsRoute.asset(asset)) {
                            AssetCard(asset: asset)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, Metric.l)
                .padding(.bottom, Metric.scrollBottomInset)
            }
            .background(Brand.canvas)
            .navigationTitle("My Assets")
            // One destination for the whole stack, so pushing an asset and then
            // a Pro tool is one continuous back stack rather than nesting
            // NavigationStacks.
            .navigationDestination(for: AssetsRoute.self) { route in
                switch route {
                case .asset(let asset):
                    AssetWorkspaceView(asset: asset)
                case .tool(let tool):
                    ProToolView(tool: tool)
                }
            }
        }
    }
}

private struct AssetCard: View {
    @Environment(\.configuration) private var configuration

    let asset: Asset

    var body: some View {
        AQCard {
            VStack(alignment: .leading, spacing: Metric.m) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Metric.xs) {
                        Text(asset.name)
                            .font(.headline)
                        Text(asset.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: Metric.s)
                    if asset.isProSubscribed {
                        AQBadge(text: "Pro", systemImage: "star.fill", tone: .accent)
                    } else {
                        AQBadge(text: "Standard", tone: .neutral)
                    }
                }

                HStack(spacing: Metric.m) {
                    AQStat(value: asset.netMonthlyCompact(configuration), label: "Net / month",
                           systemImage: "arrow.up.right", tone: .success)
                    AQStat(value: asset.occupancyLabel, label: "Occupancy",
                           systemImage: "person.2", tone: .accent)
                }

                HStack(spacing: Metric.s) {
                    AQBadge(text: "\(asset.occupiedUnitCount) of \(asset.unitCount) let",
                            systemImage: "person.2")
                    if asset.openTicketCount > 0 {
                        AQBadge(text: "\(asset.openTicketCount) open", systemImage: "wrench.and.screwdriver",
                                tone: .warning)
                    }
                }
            }
        }
    }
}

#Preview("Assets") {
    AssetsView()
        .environment(AQRFixture.store)
        .environment(AppRouter())
}