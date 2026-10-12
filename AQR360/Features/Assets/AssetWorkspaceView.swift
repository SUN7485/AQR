import SwiftUI

/// The AQR360 Pro workspace for a single asset.
///
/// Pro capabilities stay visible but locked when the asset has no active
/// subscription, mirroring the owner-controlled policy on the web product.
struct AssetWorkspaceView: View {
    let asset: Asset

    enum Tool: String, CaseIterable, Identifiable {
        case manage, contracts, responsibility, vault, services, market

        var id: String { rawValue }

        var title: String {
            switch self {
            case .manage: "Manage"
            case .contracts: "Contracts"
            case .responsibility: "Responsibility"
            case .vault: "Vault"
            case .services: "Services"
            case .market: "Market"
            }
        }

        var detail: String {
            switch self {
            case .manage: "Asset details workspace"
            case .contracts: "Tenants, renewals and payment terms"
            case .responsibility: "Approver and payee routing"
            case .vault: "Title deeds and documents"
            case .services: "Pro service catalogue"
            case .market: "List from this asset"
            }
        }

        var systemImage: String {
            switch self {
            case .manage: "slider.horizontal.3"
            case .contracts: "doc.text"
            case .responsibility: "arrow.triangle.branch"
            case .vault: "lock.doc"
            case .services: "square.grid.2x2"
            case .market: "storefront"
            }
        }

        /// Tools that require an active Pro subscription on this asset.
        var requiresPro: Bool {
            switch self {
            case .manage, .services: false
            case .contracts, .responsibility, .vault, .market: true
            }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(spacing: Metric.l) {
                header
                financialSummary
                toolsGrid
                tenantsSection
                announcementsSection

                if !asset.isProSubscribed {
                    proUpsell
                }
            }
            .padding(.horizontal, Metric.l)
            .padding(.bottom, Metric.xl)
        }
        .background(Brand.canvas)
        .navigationTitle(asset.name)
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: Tool.self) { tool in
            switch tool {
            case .contracts: ContractsView()
            case .responsibility: ResponsibilityMatrixView()
            case .vault: VaultView()
            case .manage, .services, .market: EmptyView()
            }
        }
    }

    // MARK: - Sections

    private var header: some View {
        AQHeroHeader(eyebrow: asset.address, title: asset.name) {
            AQBadge(
                text: asset.isProSubscribed ? "Pro" : "Standard",
                systemImage: asset.isProSubscribed ? "star.fill" : "circle",
                tone: .onBrand
            )
            .padding(.top, 4)
        }
        .padding(.top, Metric.s)
        .padding(.horizontal, Metric.l)
    }

    private var financialSummary: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Performance", subtitle: "Current month")
            HStack(spacing: Metric.m) {
                AQStat(value: asset.monthlyIncome.formatted(.currency(code: "USD")),
                       label: "Income", systemImage: "arrow.down", tone: .success)
                AQStat(value: asset.monthlyExpenses.formatted(.currency(code: "USD")),
                       label: "Expenses", systemImage: "arrow.up", tone: .danger)
                AQStat(value: asset.netMonthlyLabel, label: "Net", systemImage: "equal", tone: .accent)
            }
        }
    }

    private var toolsGrid: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Pro tools", subtitle: "Six included capabilities")

            LazyVGrid(columns: [GridItem(.flexible(), spacing: Metric.m),
                                GridItem(.flexible(), spacing: Metric.m)],
                      spacing: Metric.m) {
                ForEach(Tool.allCases) { tool in
                    let isLocked = tool.requiresPro && !asset.isProSubscribed

                    if destination(for: tool) != nil, !isLocked {
                        NavigationLink(value: tool) {
                            ProToolTile(tool: tool, isLocked: false)
                        }
                        .buttonStyle(.plain)
                    } else {
                        ProToolTile(tool: tool, isLocked: isLocked)
                    }
                }
            }
        }
    }

    /// Pro tools that open a dedicated screen. Manage and Services are inline
    /// summaries in this demo build.
    private func destination(for tool: Tool) -> Tool? {
        switch tool {
        case .contracts, .responsibility, .vault: tool
        case .manage, .services, .market: nil
        }
    }

    private var tenantsSection: some View {
        let roster = SampleData.tenants(for: asset)
        let lastID = roster.last?.id

        return VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Tenant access", subtitle: "\(asset.tenantCount) invited")

            AQCard {
                VStack(spacing: Metric.m) {
                    ForEach(roster) { tenant in
                        HStack(spacing: Metric.m) {
                            Text(tenant.initials)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.white)
                                .frame(width: 34, height: 34)
                                .background(Brand.accentGradient, in: .circle)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(tenant.name)
                                    .font(.subheadline.weight(.medium))
                                Text(tenant.unit)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer(minLength: Metric.s)

                            Text(tenant.leaseEnd, format: .dateTime.month(.abbreviated).year())
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if tenant.id != lastID {
                            Divider()
                        }
                    }
                }
            }
        }
    }

    private var announcementsSection: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Announcements")

            ForEach(SampleData.announcements()) { notice in
                AQCard {
                    VStack(alignment: .leading, spacing: Metric.s) {
                        HStack(spacing: Metric.s) {
                            if notice.isPinned {
                                Image(systemName: "pin.fill")
                                    .font(.caption2)
                                    .foregroundStyle(Brand.accent)
                            }
                            Text(notice.title)
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 0)
                            Text(notice.posted, format: .relative(presentation: .named))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Text(notice.body)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var proUpsell: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            ZStack(alignment: .bottomLeading) {
                Brand.heroGradient
                VStack(alignment: .leading, spacing: Metric.s) {
                    Label("AQR360 Pro", systemImage: "star.fill")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.85))
                    Text("Turn this asset into a managed workspace")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("Contracts, vault, responsibility routing and the Pro service console — one subscription, per asset.")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .padding(.top, 2)

                    Button {
                        // Demo: purchase handoff to StoreKit in production.
                    } label: {
                        Text("Subscribe for this asset")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, Metric.s)
                    }
                    .aqGlassButtonStyle(prominent: true, tint: .white)
                    .padding(.top, Metric.s)
                }
                .padding(Metric.l)
            }
            .clipShape(.rect(cornerRadius: Metric.cardRadius))
        }
    }
}

// MARK: - Pro tool tile

private struct ProToolTile: View {
    let tool: AssetWorkspaceView.Tool
    let isLocked: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.s) {
            HStack {
                Image(systemName: tool.systemImage)
                    .font(.title3)
                    .foregroundStyle(isLocked ? Color.secondary : Brand.accent)
                Spacer(minLength: 0)
                if isLocked {
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(tool.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.primary)

            Text(tool.detail)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .frame(height: 28, alignment: .top)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metric.m)
        .background(Brand.card, in: .rect(cornerRadius: Metric.chipRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Metric.chipRadius)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
        .opacity(isLocked ? 0.62 : 1)
    }
}

// MARK: - Previews

#Preview("Pro asset") {
    NavigationStack {
        AssetWorkspaceView(asset: SampleData.assets()[0])
    }
}

#Preview("Standard asset") {
    NavigationStack {
        AssetWorkspaceView(asset: SampleData.assets()[2])
    }
}