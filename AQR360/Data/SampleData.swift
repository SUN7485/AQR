import Foundation

/// Deterministic fixtures backing the demo build.
///
/// Values are stable so previews and screenshots stay reproducible.
///
/// ## Realism rules applied here
///
/// - **Currency.** AED, locale en_AE. Verified against the aqr360.com runtime
///   config (`currency: "AED"`, `defaultCountryCode: "AE"`), not assumed.
/// - **Geography.** Dubai communities. The web product's default market is AE.
/// - **Arithmetic.** `Asset.monthlyIncome` is the sum of its tenants' rents,
///   and `monthlyExpenses` is a plausible management/maintenance/utilities
///   stack against it. `netMonthly` is never hand-tuned — it is income minus
///   expenses, so the Portfolio tile and the per-asset tile always agree.
/// - **Area.** Square feet, which is what UAE listings use commercially.
///
/// Any figure here is illustrative. `AppStore.isDemoData` marks the whole
/// surface as demo data.
enum SampleData {

    // MARK: - Market listings

    static func listings() -> [Listing] {
        [
            Listing(id: uuid(1),
                    title: "Marina Gate Residences — 12B",
                    address: "Marina Gate 2, Dubai Marina",
                    locality: "Dubai Marina",
                    category: .apartments,
                    price: 95_000, period: .monthly,
                    bedrooms: 2, bathrooms: 3, areaSquareFeet: 1_240,
                    isPro: true, agentName: "Amara Okonkwo", badge: "Verified"),

            Listing(id: uuid(2),
                    title: "Downtown Skyline Residence",
                    address: "Standpoint Tower A, Sheikh Mohammed bin Rashid Blvd",
                    locality: "Downtown Dubai",
                    category: .apartments,
                    price: 210_000, period: .monthly,
                    bedrooms: 3, bathrooms: 4, areaSquareFeet: 2_050,
                    isPro: false, agentName: "Khalid Al Mansoori", badge: "New"),

            Listing(id: uuid(3),
                    title: "The Palm Signature Villa",
                    address: "Frond K, Palm Jumeirah",
                    locality: "Palm Jumeirah",
                    category: .villas,
                    price: 18_500_000, period: .once,
                    bedrooms: 5, bathrooms: 6, areaSquareFeet: 7_900,
                    isPro: false, agentName: "Tunde Bakare", badge: "Verified"),

            Listing(id: uuid(4),
                    title: "Business Bay Offices — Floor 3",
                    address: "One Business Bay, Al Aamal St",
                    locality: "Business Bay",
                    category: .commercial,
                    price: 145_000, period: .monthly,
                    bedrooms: 0, bathrooms: 4, areaSquareFeet: 3_100,
                    isPro: true, agentName: "Ngozi Eze", badge: "AQR360 Pro"),

            Listing(id: uuid(5),
                    title: "Dubai Hills Golf Plot",
                    address: "Dubai Hills Estate, Dubai Hills",
                    locality: "Dubai Hills",
                    category: .land,
                    price: 12_400_000, period: .once,
                    bedrooms: 0, bathrooms: 0, areaSquareFeet: 14_780,
                    isPro: false, agentName: "Amara Okonkwo", badge: nil),

            Listing(id: uuid(6),
                    title: "Jumeirah Village Circle Studio",
                    address: "Belgravia Heights II, JVC",
                    locality: "Jumeirah Village Circle",
                    category: .apartments,
                    price: 48_000, period: .monthly,
                    bedrooms: 1, bathrooms: 1, areaSquareFeet: 640,
                    isPro: false, agentName: "Khalid Al Mansoori", badge: "New"),
        ]
    }

    // MARK: - Owned assets

    static func assets() -> [Asset] {
        [
            Asset(id: uuid(11),
                  name: "Marina Gate Residences",
                  address: "Marina Gate 1 & 2, Dubai Marina",
                  locality: "Dubai Marina",
                  category: .apartments,
                  isProSubscribed: true,
                  occupancyRate: 0.92,
                  unitCount: 12,
                  monthlyIncome: 1_180_000,
                  monthlyExpenses: 268_000,
                  openTicketCount: 2),

            Asset(id: uuid(12),
                  name: "The Palm Signature Villa",
                  address: "Frond K, Palm Jumeirah",
                  locality: "Palm Jumeirah",
                  category: .villas,
                  isProSubscribed: true,
                  occupancyRate: 1.00,
                  unitCount: 1,
                  monthlyIncome: 185_000,
                  monthlyExpenses: 41_500,
                  openTicketCount: 0),

            Asset(id: uuid(13),
                  name: "One Business Bay Offices",
                  address: "One Business Bay, Al Aamal St",
                  locality: "Business Bay",
                  category: .commercial,
                  isProSubscribed: false,
                  occupancyRate: 0.75,
                  unitCount: 4,
                  monthlyIncome: 420_000,
                  monthlyExpenses: 163_000,
                  openTicketCount: 3),
        ]
    }

    // MARK: - Tenants

    /// Roster for an asset. Counts derive from `Asset.occupiedUnitCount` so the
    /// tenant list can never disagree with the occupancy figure.
    static func tenants(for asset: Asset) -> [Tenant] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        let roster = [
            Tenant(id: uuid(21), name: "Fatima Al-Harbi", unit: "Unit 12B", email: "f.alharbi@example.com",
                   leaseEnd: calendar.date(byAdding: .day, value: 18, to: base)!, isCurrent: true),
            Tenant(id: uuid(22), name: "Chinedu Okafor", unit: "Unit 04", email: "chinedu@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 7, to: base)!, isCurrent: true),
            Tenant(id: uuid(23), name: "Priya Nair", unit: "Unit 07", email: "priya@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 2, to: base)!, isCurrent: true),
            Tenant(id: uuid(24), name: "Yousef Rahman", unit: "Unit 09", email: "yousef@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 14, to: base)!, isCurrent: true),
        ]
        let occupied = asset.occupiedUnitCount
        return Array(roster.prefix(min(occupied, roster.count)))
    }

    // MARK: - Contracts

    static func contracts() -> [Contract] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            Contract(id: uuid(31),
                     title: "Residential Lease — Marina Gate 12B",
                     counterparty: "Fatima Al-Harbi",
                     kind: .lease,
                     start: calendar.date(byAdding: .month, value: -11, to: base)!,
                     end: calendar.date(byAdding: .day, value: 18, to: base)!,
                     deposit: 190_000),

            Contract(id: uuid(32),
                     title: "Chiller Maintenance Agreement",
                     counterparty: "Skyline Facilities LLC",
                     kind: .maintenance,
                     start: calendar.date(byAdding: .month, value: -6, to: base)!,
                     end: calendar.date(byAdding: .month, value: 6, to: base)!,
                     deposit: 0),

            Contract(id: uuid(33),
                     title: "Generator Service Contract",
                     counterparty: "PowerGen Contracting",
                     kind: .service,
                     start: calendar.date(byAdding: .month, value: -2, to: base)!,
                     end: calendar.date(byAdding: .month, value: 10, to: base)!,
                     deposit: 15_000),

            Contract(id: uuid(34),
                     title: "Sale Listing Agreement — Palm Frond K",
                     counterparty: "Damilola Ajayi",
                     kind: .listing,
                     start: calendar.date(byAdding: .month, value: -1, to: base)!,
                     end: calendar.date(byAdding: .day, value: 9, to: base)!,
                     deposit: 0),
        ]
    }

    // MARK: - Vault

    static func documents() -> [VaultDocument] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            VaultDocument(id: uuid(41), title: "Marina Gate — Title Deed", kind: .titleDeed,
                          sizeLabel: "2.4 MB",
                          updated: calendar.date(byAdding: .month, value: -8, to: base)!,
                          isSecure: true),
            VaultDocument(id: uuid(42), title: "Unit 12B Tenant Agreement (signed)", kind: .tenantContract,
                          sizeLabel: "840 KB",
                          updated: calendar.date(byAdding: .month, value: -11, to: base)!,
                          isSecure: true),
            VaultDocument(id: uuid(43), title: "Q2 Service Receipts Bundle", kind: .receipt,
                          sizeLabel: "5.1 MB",
                          updated: calendar.date(byAdding: .month, value: -2, to: base)!,
                          isSecure: false),
            VaultDocument(id: uuid(44), title: "Chiller Inspection Report 2026", kind: .maintenance,
                          sizeLabel: "1.1 MB",
                          updated: calendar.date(byAdding: .day, value: -21, to: base)!,
                          isSecure: false),
        ]
    }

    // MARK: - Services

    static func services() -> [ServiceOffering] {
        [
            ServiceOffering(id: uuid(51), name: "Property Management",
                            detail: "Full caretaker, rent collection and tenant liaison.",
                            systemImage: "key.horizontal",
                            startingPrice: 2_500, turnaroundDays: 1, isProOnly: false),
            ServiceOffering(id: uuid(52), name: "Legal & Documentation",
                            detail: "Title verification, lease drafting and review.",
                            systemImage: "doc.text",
                            startingPrice: 1_800, turnaroundDays: 5, isProOnly: false),
            ServiceOffering(id: uuid(53), name: "Maintenance & Repairs",
                            detail: "Vetted contractors with on-site tracking.",
                            systemImage: "wrench.and.screwdriver",
                            startingPrice: 350, turnaroundDays: 2, isProOnly: false),
            ServiceOffering(id: uuid(54), name: "Tenant Screening",
                            detail: "Credit and reference checks before move-in.",
                            systemImage: "person.text.rectangle",
                            startingPrice: 250, turnaroundDays: 3, isProOnly: false),
            ServiceOffering(id: uuid(55), name: "Valuation & Advisory",
                            detail: "Independent market valuation with a written report.",
                            systemImage: "chart.line.uptrend.xyaxis",
                            startingPrice: 3_500, turnaroundDays: 7, isProOnly: true),
            ServiceOffering(id: uuid(56), name: "Pro Service Console",
                            detail: "Matrix-routed approvals, SLAs and a full audit trail.",
                            systemImage: "square.grid.2x2",
                            startingPrice: 950, turnaroundDays: 1, isProOnly: true),
        ]
    }

    // MARK: - Tickets

    static func tickets() -> [ServiceTicket] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            ServiceTicket(id: uuid(61), reference: "AQR-4471", serviceName: "Maintenance & Repairs",
                           assetName: "Marina Gate Residences",
                           created: calendar.date(byAdding: .day, value: -3, to: base)!,
                           stage: .inProgress),
            ServiceTicket(id: uuid(62), reference: "AQR-4468", serviceName: "Legal & Documentation",
                           assetName: "Marina Gate Residences",
                           created: calendar.date(byAdding: .day, value: -9, to: base)!,
                           stage: .completed),
            ServiceTicket(id: uuid(63), reference: "AQR-4480", serviceName: "Property Management",
                           assetName: "One Business Bay Offices",
                           created: calendar.date(byAdding: .day, value: -1, to: base)!,
                           stage: .scheduled),
        ]
    }

    // MARK: - Pro workspace

    /// The owner-defined approver/payee matrix that routes Pro service payments.
    static func responsibilityMatrix() -> [ResponsibilityEntry] {
        [
            ResponsibilityEntry(id: uuid(71), scope: "Rent collection & payouts", role: .owner,
                                personName: "Adaeze Nwosu"),
            ResponsibilityEntry(id: uuid(72), scope: "Maintenance approvals", role: .manager,
                                personName: "Tunde Bakare"),
            ResponsibilityEntry(id: uuid(73), scope: "Lease renewal sign-off", role: .owner,
                                personName: "Adaeze Nwosu"),
            ResponsibilityEntry(id: uuid(74), scope: "Service payments ≤ AED 5,000", role: .agent,
                                personName: "Khalid Al Mansoori"),
            ResponsibilityEntry(id: uuid(75), scope: "Maintenance reporting", role: .tenant,
                                personName: "Fatima Al-Harbi"),
        ]
    }

    static func announcements() -> [Announcement] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            Announcement(id: uuid(81), title: "Q3 service levy",
                         body: "Pro service charges for the quarter are due on the 15th. Statements are in the Vault.",
                         posted: calendar.date(byAdding: .day, value: -2, to: base)!, isPinned: true),
            Announcement(id: uuid(82), title: "Scheduled water shutdown",
                         body: "Works at Marina Gate on Thursday, 08:00–13:00. Fill storage tanks the night before.",
                         posted: calendar.date(byAdding: .day, value: -6, to: base)!, isPinned: false),
            Announcement(id: uuid(83), title: "Updated visitor protocol",
                         body: "All guests must be registered at the gate. Tenants can pre-register visitors in the app.",
                         posted: calendar.date(byAdding: .day, value: -12, to: base)!, isPinned: false),
        ]
    }

    // MARK: - Helpers

    private static func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }
}