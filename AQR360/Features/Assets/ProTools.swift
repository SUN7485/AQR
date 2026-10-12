import SwiftUI

/// Renders a Pro tool screen. Lives here so the Assets stack's
/// `navigationDestination` and the workspace preview share one mapping.
struct ProToolView: View {
    let tool: AssetWorkspaceView.Tool

    var body: some View {
        switch tool {
        case .contracts: ContractsView()
        case .responsibility: ResponsibilityMatrixView()
        case .vault: VaultView()
        case .manage, .services, .market: EmptyView()
        }
    }
}

/// Pro → Contracts. Renewal windows and payment terms for the selected asset.
struct ContractsView: View {
    private let contracts = SampleData.contracts()

    var body: some View {
        List {
            Section {
                ForEach(contracts) { contract in
                    ContractRow(contract: contract)
                }
            } header: {
                Text("Active contracts")
            } footer: {
                Text("Renewals are flagged 30 days before expiry. The owner remains the moderator on every contract.")
            }
        }
        .navigationTitle("Contracts")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ContractRow: View {
    @Environment(\.configuration) private var configuration

    let contract: Contract

    var body: some View {
        HStack(spacing: Metric.m) {
            Image(systemName: contract.kind.systemImage)
                .font(.footnote)
                .foregroundStyle(tone.foreground)
                .frame(width: 34, height: 34)
                .background(tone.background, in: .rect(cornerRadius: Metric.chipRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(contract.title)
                    .font(.subheadline.weight(.medium))
                Text(contract.counterparty)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Metric.s)

            VStack(alignment: .trailing, spacing: 2) {
                AQBadge(text: statusLabel, tone: tone)
                if contract.deposit > 0 {
                    Text("Deposit " + contract.deposit.moneyLabel(configuration.currencyCode,
                                                                       locale: configuration.locale))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .padding(.vertical, 2)
    }

    private var statusLabel: String {
        switch contract.status {
        case .active: "Active"
        case .renewalDue: "\(max(0, contract.daysRemaining))d left"
        case .expired: "Expired"
        }
    }

    private var tone: AQBadge.Tone {
        switch contract.status {
        case .active: .success
        case .renewalDue: .warning
        case .expired: .danger
        }
    }
}

extension Contract.Kind {
    var systemImage: String {
        switch self {
        case .lease: "house"
        case .maintenance: "wrench.and.screwdriver"
        case .service: "gearshape"
        case .listing: "storefront"
        }
    }
}

/// Pro → Vault. Title deeds, contracts and Admin-managed document types.
struct VaultView: View {
    private let documents = SampleData.documents()

    var body: some View {
        List {
            Section {
                ForEach(documents) { document in
                    VaultRow(document: document)
                }
            } footer: {
                Label("Documents marked secure are encrypted at rest.", systemImage: "lock.shield")
                    .font(.caption)
            }
        }
        .navigationTitle("Vault")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct VaultRow: View {
    @Environment(\.configuration) private var configuration

    let document: VaultDocument

    var body: some View {
        HStack(spacing: Metric.m) {
            Image(systemName: document.kind.systemImage)
                .font(.footnote)
                .foregroundStyle(Brand.primary)
                .frame(width: 34, height: 34)
                .background(Brand.primary.opacity(0.12), in: .rect(cornerRadius: Metric.chipRadius))

            VStack(alignment: .leading, spacing: 2) {
                Text(document.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: Metric.s) {
                    Text(document.kind.rawValue)
                    Text("·")
                    Text(document.sizeLabel)
                    if document.isSecure {
                        Image(systemName: "lock.fill").foregroundStyle(Brand.success)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: Metric.s)

            Text(document.updated.relativeToNow(configuration.locale))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 2)
    }
}

extension VaultDocument.Kind {
    var systemImage: String {
        switch self {
        case .titleDeed: "seal"
        case .tenantContract: "doc.text"
        case .maintenance: "wrench.and.screwdriver"
        case .receipt: "banknote"
        case .other: "doc"
        }
    }
}

/// Pro → Responsibility. The owner-defined approver/payee matrix.
struct ResponsibilityMatrixView: View {
    private let entries = SampleData.responsibilityMatrix()

    var body: some View {
        List {
            Section {
                ForEach(entries) { entry in
                    HStack(spacing: Metric.m) {
                        Image(systemName: entry.role.systemImage)
                            .font(.footnote)
                            .foregroundStyle(Brand.accent)
                            .frame(width: 34, height: 34)
                            .background(Brand.accent.opacity(0.12), in: .rect(cornerRadius: Metric.chipRadius))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(entry.scope)
                                .font(.subheadline.weight(.medium))
                            Text(entry.personName)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: Metric.s)

                        AQBadge(text: entry.role.rawValue, tone: .accent)
                    }
                    .padding(.vertical, 2)
                }
            } footer: {
                Text("The same approver and payee resolves for every Pro service on this asset.")
            }
        }
        .navigationTitle("Responsibility")
        .navigationBarTitleDisplayMode(.inline)
    }
}