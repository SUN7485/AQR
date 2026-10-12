import Foundation

// MARK: - Listing

/// A property listing on the AQR360 Market.
struct Listing: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let address: String
    let category: ListingCategory
    let price: Decimal
    let period: PaymentPeriod
    let bedrooms: Int
    let bathrooms: Int
    let areaSquareFeet: Int
    let isPro: Bool
    let agentName: String
    let badge: String?

    var priceLabel: String {
        period == .once ? price.moneyLabel : price.moneyLabel + "/mo"
    }

    var specSummary: String {
        "\(bedrooms) bed · \(bathrooms) bath · \(areaSquareFeet.formatted()) sqft"
    }
}

enum ListingCategory: String, CaseIterable, Identifiable, Sendable {
    case apartments = "Apartments"
    case houses = "Houses"
    case commercial = "Commercial"
    case land = "Land"

    var id: String { rawValue }

    var systemImage: String {
        switch self {
        case .apartments: "building.2"
        case .houses: "house"
        case .commercial: "briefcase"
        case .land: "map"
        }
    }
}

enum PaymentPeriod: String, Sendable {
    case once, monthly

    var suffix: String { self == .once ? "" : " / month" }
}

// MARK: - Asset

/// A property the user owns, managed through AQR360 Pro.
struct Asset: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let address: String
    let category: ListingCategory
    let isProSubscribed: Bool
    var occupancyRate: Double
    let monthlyIncome: Decimal
    let monthlyExpenses: Decimal
    let tenantCount: Int
    let openTicketCount: Int

    var netMonthly: Decimal { monthlyIncome - monthlyExpenses }

    var netMonthlyLabel: String {
        netMonthly.moneyLabel
    }

    var occupancyLabel: String {
        occupancyRate.formatted(.percent.precision(.fractionLength(0)))
    }
}

// MARK: - Tenant

struct Tenant: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let unit: String
    let email: String
    let leaseEnd: Date
    let isCurrent: Bool

    var initials: String { name.initials }
}

// MARK: - Contract

struct Contract: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let counterparty: String
    let kind: Kind
    let start: Date
    let end: Date
    let deposit: Decimal

    enum Kind: String, Sendable {
        case lease = "Lease"
        case maintenance = "Maintenance"
        case service = "Service"
        case listing = "Listing"
    }

    var daysRemaining: Int {
        Calendar.current.dateComponents([.day], from: .now, to: end).day ?? 0
    }

    var status: Status {
        if daysRemaining < 0 { return .expired }
        if daysRemaining <= 30 { return .renewalDue }
        return .active
    }

    enum Status: Sendable {
        case active, renewalDue, expired
    }
}

// MARK: - Document

struct VaultDocument: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let kind: Kind
    let sizeLabel: String
    let updated: Date
    let isSecure: Bool

    enum Kind: String, Sendable {
        case titleDeed = "Title Deed"
        case tenantContract = "Tenant Contract"
        case maintenance = "Maintenance"
        case receipt = "Receipt"
        case other = "Other"
    }
}

// MARK: - Service

struct ServiceOffering: Identifiable, Hashable, Sendable {
    let id: UUID
    let name: String
    let detail: String
    let systemImage: String
    let startingPrice: Decimal
    let turnaroundDays: Int
    let isProOnly: Bool
}

struct ServiceTicket: Identifiable, Hashable, Sendable {
    let id: UUID
    let reference: String
    let serviceName: String
    let assetName: String
    let created: Date
    var stage: Stage

    enum Stage: String, Sendable, CaseIterable {
        case submitted = "Submitted"
        case scheduled = "Scheduled"
        case inProgress = "In Progress"
        case completed = "Completed"
        case cancelled = "Cancelled"

        var tone: AQBadge.Tone {
            switch self {
            case .submitted: .neutral
            case .scheduled: .accent
            case .inProgress: .warning
            case .completed: .success
            case .cancelled: .danger
            }
        }

        var systemImage: String {
            switch self {
            case .submitted: "paperplane"
            case .scheduled: "calendar"
            case .inProgress: "wrench.and.screwdriver"
            case .completed: "checkmark.seal"
            case .cancelled: "xmark.circle"
            }
        }
    }
}

// MARK: - Pro workspace

/// The owner-defined approver/payee matrix that routes Pro service payments.
struct ResponsibilityEntry: Identifiable, Hashable, Sendable {
    let id: UUID
    let scope: String
    let role: Role
    let personName: String

    enum Role: String, Sendable {
        case owner = "Owner"
        case agent = "Agent"
        case manager = "Manager"
        case tenant = "Tenant"

        var systemImage: String {
            switch self {
            case .owner: "crown"
            case .agent: "person.badge.key"
            case .manager: "briefcase"
            case .tenant: "person"
            }
        }
    }
}

struct Announcement: Identifiable, Hashable, Sendable {
    let id: UUID
    let title: String
    let body: String
    let posted: Date
    let isPinned: Bool
}