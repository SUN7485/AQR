import SwiftUI

struct MarketView: View {
    @Environment(AppStore.self) private var store
    @Environment(AppRouter.self) private var router

    var body: some View {
        NavigationStack(path: $router.marketPath) {
            Group {
                if store.isLoading {
                    ProgressView()
                } else if store.filteredListings.isEmpty {
                    ContentUnavailableView.search(text: store.searchText)
                } else {
                    ScrollView {
                        LazyVStack(spacing: Metric.m) {
                            categoryFilter
                            ForEach(store.filteredListings) { listing in
                                NavigationLink(value: listing) {
                                    ListingRow(listing: listing)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, Metric.l)
                        .padding(.bottom, Metric.scrollBottomInset)
                    }
                    .background(Brand.canvas)
                }
            }
            .navigationTitle("Market")
            .searchable(text: Bindable(store).searchText, prompt: "Search listings, agents, areas")
            .navigationDestination(for: Listing.self) { ListingDetailView(listing: $0) }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    // Mutate through the store directly: `Bindable(store).x = y`
                    // cannot assign, because a Bindable wrapper is a temporary.
                    if store.selectedCategory != nil {
                        Button("Clear") { store.selectedCategory = nil }
                            .font(.subheadline)
                    }
                }
            }
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Metric.s) {
                CategoryChip(title: "All", systemImage: "square.grid.2x2",
                             isSelected: store.selectedCategory == nil) {
                    store.selectedCategory = nil
                }
                ForEach(ListingCategory.allCases) { category in
                    CategoryChip(title: category.rawValue, systemImage: category.systemImage,
                                 isSelected: store.selectedCategory == category) {
                        store.selectedCategory = store.selectedCategory == category ? nil : category
                    }
                }
            }
            .padding(.vertical, Metric.xs)
        }
        .scrollClipDisabled()
    }
}

// MARK: - Pieces

private struct CategoryChip: View {
    let title: String
    let systemImage: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.medium))
                .padding(.horizontal, Metric.m)
                .padding(.vertical, Metric.s)
                .foregroundStyle(isSelected ? .white : .primary)
                .background {
                    Capsule().fill(isSelected ? AnyShapeStyle(Brand.accentGradient) : AnyShapeStyle(.quaternary))
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ListingRow: View {
    @Environment(\.configuration) private var configuration

    let listing: Listing

    var body: some View {
        AQCard {
            VStack(alignment: .leading, spacing: Metric.m) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: Metric.xs) {
                        Text(listing.title)
                            .font(.headline)
                            .foregroundStyle(.primary)
                        Text(listing.address)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer(minLength: Metric.s)
                    Image(systemName: listing.category.systemImage)
                        .font(.title3)
                        .foregroundStyle(Brand.accent)
                }

                HStack(spacing: Metric.xs) {
                    AQBadge(text: listing.category.rawValue, systemImage: "tag", tone: .neutral)
                    if listing.isPro {
                        AQBadge(text: "Pro", systemImage: "star.fill", tone: .accent)
                    }
                    if let badge = listing.badge, badge != listing.category.rawValue {
                        AQBadge(text: badge, tone: .success)
                    }
                }

                Divider()

                HStack(alignment: .firstTextBaseline) {
                    Text(listing.priceLabel(configuration))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(Brand.primary)
                        .contentTransition(.numericText())
                    Spacer(minLength: Metric.s)
                    Text(listing.agentName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(listing.specSummary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Detail

struct ListingDetailView: View {
    @Environment(\.configuration) private var configuration

    let listing: Listing

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Metric.l) {
                ZStack(alignment: .bottomLeading) {
                    Brand.heroGradient
                    Image(systemName: listing.category.systemImage)
                        .font(.system(size: 72, weight: .light))
                        .foregroundStyle(.white.opacity(0.18))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                        .padding(Metric.l)

                    VStack(alignment: .leading, spacing: Metric.xs) {
                        Text(listing.priceLabel(configuration))
                            .font(.largeTitle.weight(.bold))
                            .foregroundStyle(.white)
                        Text(listing.address)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.85))
                    }
                    .padding(Metric.l)
                }

                VStack(alignment: .leading, spacing: Metric.m) {
                    AQSectionHeader("Details")
                    HStack(spacing: Metric.m) {
                        AQStat(value: "\(listing.bedrooms)", label: "Bedrooms", systemImage: "bed.double", tone: .accent)
                        AQStat(value: "\(listing.bathrooms)", label: "Bathrooms", systemImage: "shower", tone: .accent)
                        AQStat(value: listing.areaSquareFeet.formatted(), label: "Square feet", systemImage: "ruler", tone: .accent)
                    }
                }

                AQCard {
                    VStack(alignment: .leading, spacing: Metric.s) {
                        Text("Listed by")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(listing.agentName)
                            .font(.headline)
                        Text("AQR360 certified agent")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if #available(iOS 26, *) {
                    Button {
                        // Demo: scheduling is the production integration point.
                    } label: {
                        Label("Schedule a viewing", systemImage: "calendar.badge.plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.large)
                } else {
                    Button("Schedule a viewing", systemImage: "calendar.badge.plus") { }
                        .frame(maxWidth: .infinity)
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                }
            }
            .padding(.horizontal, Metric.l)
            .padding(.bottom, Metric.scrollBottomInset)
        }
        .background(Brand.canvas)
        .navigationTitle(listing.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Market") {
    MarketView()
        .environment(AQRFixture.store)
        .environment(AppRouter())
}