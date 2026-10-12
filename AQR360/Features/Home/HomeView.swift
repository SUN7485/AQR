import SwiftUI

struct HomeView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Metric.l) {
                    demoBanner
                    header
                    quickActions
                    portfolioSummary
                    ticketsSection
                    marketPreview
                    careCard
                }
                .padding(.horizontal, Metric.l)
                .padding(.bottom, Metric.scrollBottomInset)
            }
            .background(Brand.canvas)
            .navigationTitle("AQR360")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await store.load() }
        }
    }

    // MARK: - Sections

    /// Surfaced whenever `AppStore.isDemoData` is true, so a demo is never
    /// mistaken for live AQR360 data. Disappears the moment a real client is
    /// wired into `load()`.
    @ViewBuilder
    private var demoBanner: some View {
        if store.isDemoData {
            HStack(spacing: Metric.s) {
                Image(systemName: "testtube.2")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.warning)

                Text("Demo data — not live AQR360 records")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)

                Spacer(minLength: 0)

                AQBadge(text: store.configuration.currencyCode, tone: .warning)
            }
            .padding(.horizontal, Metric.m)
            .padding(.vertical, Metric.s)
            .background(Brand.warning.opacity(0.10), in: .rect(cornerRadius: Metric.chipRadius))
            .accessibilityElement(children: .combine)
        }
    }

    private var header: some View {
        AQHeroHeader(
            eyebrow: "Good day",
            title: store.firstName
        )
        .padding(.horizontal, Metric.l)
        .padding(.top, Metric.s)
    }

    private var quickActions: some View {
        // Quick actions are real controls, so they are the one place on this
        // screen where interactive glass is appropriate.
        aqGlassGroup(spacing: Metric.m) {
            HStack(spacing: Metric.m) {
                QuickActionTile(title: "List\nProperty", systemImage: "plus.rectangle.on.rectangle") { }
                QuickActionTile(title: "Book\nService", systemImage: "calendar.badge.plus") { }
                QuickActionTile(title: "Care\nTicket", systemImage: "questionmark.bubble") { }
                QuickActionTile(title: "Pay", systemImage: "creditcard") { }
            }
        }
    }

    private var portfolioSummary: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Portfolio", subtitle: "Across \(store.assets.count) assets")

            HStack(spacing: Metric.m) {
                AQStat(value: store.totalMonthlyNetCompact,
                       label: "Net per month",
                       systemImage: "arrow.up.right",
                       tone: .success)
                AQStat(value: store.occupancyAverage.formatted(.percent.precision(.fractionLength(0))),
                       label: "Occupancy",
                       systemImage: "person.2",
                       tone: .accent)
                AQStat(value: "\(store.openTicketCount)",
                       label: "Open tickets",
                       systemImage: "wrench.and.screwdriver",
                       tone: .warning)
            }
        }
    }

    private var ticketsSection: some View {
        let active = Array(store.tickets.prefix(2))
        let lastID = active.last?.id

        return VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Active tickets", subtitle: "Track progress end to end")

            AQCard {
                VStack(spacing: Metric.m) {
                    ForEach(active) { ticket in
                        TicketRow(ticket: ticket)
                        if ticket.id != lastID {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var marketPreview: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Fresh on the market", subtitle: "Listings added recently")

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: Metric.m) {
                    ForEach(store.listings.filter { $0.badge == "New" || $0.isPro }.prefix(4)) { listing in
                        ListingChip(listing: listing)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var careCard: some View {
        AQCard {
            HStack(spacing: Metric.m) {
                Image(systemName: "lifepreserver.fill")
                    .font(.title3)
                    .foregroundStyle(Brand.accent)
                    .frame(width: 42, height: 42)
                    .background(Brand.accent.opacity(0.12), in: .rect(cornerRadius: Metric.chipRadius))

                VStack(alignment: .leading, spacing: 2) {
                    Text("AQR360 Care")
                        .font(.subheadline.weight(.semibold))
                    Text("Open a ticket and follow every reply from your account.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: Metric.s)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
    }
}

// MARK: - Pieces

private struct QuickActionTile: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: Metric.xs) {
                Image(systemName: systemImage)
                    .font(.title3)
                Text(title)
                    .font(.caption2.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineSpacing(0)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 66)
        }
        .aqGlassButtonStyle()
        .accessibilityLabel(title.replacingOccurrences(of: "\n", with: " "))
    }
}

private struct TicketRow: View {
    let ticket: ServiceTicket

    var body: some View {
        HStack(spacing: Metric.m) {
            Image(systemName: ticket.stage.systemImage)
                .font(.footnote)
                .foregroundStyle(ticket.stage.tone.foreground)
                .frame(width: 34, height: 34)
                .background(ticket.stage.tone.background, in: .rect(cornerRadius: Metric.chipRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(ticket.serviceName)
                    .font(.subheadline.weight(.medium))
                Text("\(ticket.reference) · \(ticket.assetName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: Metric.s)

            AQBadge(text: ticket.stage.rawValue, tone: ticket.stage.tone)
        }
    }
}

#Preview("Home — loaded") {
    NavigationStack { HomeView() }
        .environment(AQRFixture.store)
}

#Preview("Home — empty") {
    NavigationStack { HomeView() }
        .environment(AQRFixture.emptyStore)
}