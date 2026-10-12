import SwiftUI

struct AssetsView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Metric.m) {
                    ForEach(store.assets) { asset in
                        NavigationLink(value: asset) {
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
            .navigationDestination(for: Asset.self) { asset in
                AssetWorkspaceView(asset: asset)
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
                    AQStat(value: asset.netMonthlyLabel(configuration), label: "Net / month",
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
}