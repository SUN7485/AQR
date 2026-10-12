import Foundation

/// Deterministic fixtures backing the demo build.
/// Values are stable so previews and screenshots stay reproducible.
enum SampleData {

    static func listings() -> [Listing] {
        [
            Listing(id: uuid(1), title: "Harborview Residences — 12B", address: "14 Marine Parade, Victoria Island",
                    category: .apartments, price: 185_000, period: .monthly, bedrooms: 3, bathrooms: 2,
                    areaSquareFeet: 1_420, isPro: true, agentName: "Amara Okonkwo", badge: "Verified"),
            Listing(id: uuid(2), title: "The Cedar Court", address: "7 Adeola Odeku St, Lekki",
                    category: .houses, price: 92_000_000, period: .once, bedrooms: 5, bathrooms: 5,
                    areaSquareFeet: 5_200, isPro: false, agentName: "Tunde Bakare", badge: nil),
            Listing(id: uuid(3), title: "Orchard Studio Loft", address: "22 Bourdillon Rd, Ikoyi",
                    category: .apartments, price: 120_000, period: .monthly, bedrooms: 1, bathrooms: 1,
                    areaSquareFeet: 640, isPro: false, agentName: "Ngozi Eze", badge: "New"),
            Listing(id: uuid(4), title: "Anchor Point Offices — Floor 3", address: "1 Ozumba Mbadiwe Ave, Victoria Island",
                    category: .commercial, price: 240_000, period: .monthly, bedrooms: 0, bathrooms: 4,
                    areaSquareFeet: 3_100, isPro: true, agentName: "Kelechi Nwosu", badge: "AQR360 Pro"),
            Listing(id: uuid(5), title: "Ibeju Riverside Plot", address: "Lekki–Epe Expressway",
                    category: .land, price: 18_500_000, period: .once, bedrooms: 0, bathrooms: 0,
                    areaSquareFeet: 12_400, isPro: false, agentName: "Amara Okonkwo", badge: nil),
            Listing(id: uuid(6), title: "Palm Grove Duplex — Unit B", address: "3 Fola Osibo Rd, Lekki Phase 1",
                    category: .houses, price: 340_000, period: .monthly, bedrooms: 4, bathrooms: 3,
                    areaSquareFeet: 2_800, isPro: true, agentName: "Tunde Bakare", badge: "Verified"),
        ]
    }

    static func assets() -> [Asset] {
        [
            Asset(id: uuid(11), name: "Harborview Residences", address: "14 Marine Parade, Victoria Island",
                  category: .apartments, isProSubscribed: true, occupancyRate: 0.92,
                  monthlyIncome: 4_850_000, monthlyExpenses: 1_320_000, tenantCount: 8, openTicketCount: 2),
            Asset(id: uuid(12), name: "Palm Grove Duplex", address: "3 Fola Osibo Rd, Lekki Phase 1",
                  category: .houses, isProSubscribed: true, occupancyRate: 1.00,
                  monthlyIncome: 2_400_000, monthlyExpenses: 610_000, tenantCount: 2, openTicketCount: 0),
            Asset(id: uuid(13), name: "Anchor Point Offices", address: "1 Ozumba Mbadiwe Ave, Victoria Island",
                  category: .commercial, isProSubscribed: false, occupancyRate: 0.75,
                  monthlyIncome: 3_600_000, monthlyExpenses: 1_450_000, tenantCount: 4, openTicketCount: 3),
        ]
    }

    static func tenants(for asset: Asset) -> [Tenant] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            Tenant(id: uuid(21), name: "Chinedu Okafor", unit: "Unit 11", email: "chinedu@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 7, to: base)!, isCurrent: true),
            Tenant(id: uuid(22), name: "Fatima Bello", unit: "Unit 12B", email: "fatima@example.com",
                   leaseEnd: calendar.date(byAdding: .day, value: 18, to: base)!, isCurrent: true),
            Tenant(id: uuid(23), name: "Segun Adeyemi", unit: "Unit 04", email: "segun@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 2, to: base)!, isCurrent: true),
            Tenant(id: uuid(24), name: "Aisha Lawal", unit: "Unit 09", email: "aisha@example.com",
                   leaseEnd: calendar.date(byAdding: .month, value: 14, to: base)!, isCurrent: true),
        ].prefix(max(2, min(asset.tenantCount, 4))).map { $0 }
    }

    static func contracts() -> [Contract] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            Contract(id: uuid(31), title: "Residential Lease — Unit 12B", counterparty: "Fatima Bello",
                     kind: .lease, start: calendar.date(byAdding: .month, value: -11, to: base)!,
                     end: calendar.date(byAdding: .day, value: 18, to: base)!, deposit: 1_200_000),
            Contract(id: uuid(32), title: "Elevator Maintenance Agreement", counterparty: "Skyline Facilities Ltd",
                     kind: .maintenance, start: calendar.date(byAdding: .month, value: -6, to: base)!,
                     end: calendar.date(byAdding: .month, value: 6, to: base)!, deposit: 0),
            Contract(id: uuid(33), title: "Generator Service Contract", counterparty: "PowerGen Nigeria",
                     kind: .service, start: calendar.date(byAdding: .month, value: -2, to: base)!,
                     end: calendar.date(byAdding: .month, value: 10, to: base)!, deposit: 300_000),
            Contract(id: uuid(34), title: "Sale Listing Agreement — Palm Grove B", counterparty: "Damilola Ajayi",
                     kind: .listing, start: calendar.date(byAdding: .month, value: -1, to: base)!,
                     end: calendar.date(byAdding: .day, value: 9, to: base)!, deposit: 0),
        ]
    }

    static func documents() -> [VaultDocument] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            VaultDocument(id: uuid(41), title: "Harborview — Certificate of Title", kind: .titleDeed,
                          sizeLabel: "2.4 MB", updated: calendar.date(byAdding: .month, value: -8, to: base)!, isSecure: true),
            VaultDocument(id: uuid(42), title: "Unit 12B Tenant Agreement (signed)", kind: .tenantContract,
                          sizeLabel: "840 KB", updated: calendar.date(byAdding: .month, value: -11, to: base)!, isSecure: true),
            VaultDocument(id: uuid(43), title: "Q2 Service Receipts Bundle", kind: .receipt,
                          sizeLabel: "5.1 MB", updated: calendar.date(byAdding: .month, value: -2, to: base)!, isSecure: false),
            VaultDocument(id: uuid(44), title: "Lift Inspection Report 2026", kind: .maintenance,
                          sizeLabel: "1.1 MB", updated: calendar.date(byAdding: .day, value: -21, to: base)!, isSecure: false),
        ]
    }

    static func services() -> [ServiceOffering] {
        [
            ServiceOffering(id: uuid(51), name: "Property Management", detail: "Full caretaker, rent collection and tenant liaison.",
                            systemImage: "key.horizontal", startingPrice: 120_000, turnaroundDays: 1, isProOnly: false),
            ServiceOffering(id: uuid(52), name: "Legal & Documentation", detail: "Title verification, lease drafting and review.",
                            systemImage: "doc.text", startingPrice: 75_000, turnaroundDays: 5, isProOnly: false),
            ServiceOffering(id: uuid(53), name: "Maintenance & Repairs", detail: "Vetted artisans with on-site tracking.",
                            systemImage: "wrench.and.screwdriver", startingPrice: 25_000, turnaroundDays: 2, isProOnly: false),
            ServiceOffering(id: uuid(54), name: "Tenant Screening", detail: "Credit and reference checks before move-in.",
                            systemImage: "person.text.rectangle", startingPrice: 15_000, turnaroundDays: 3, isProOnly: false),
            ServiceOffering(id: uuid(55), name: "Valuation & Advisory", detail: "Independent market valuation with a written report.",
                            systemImage: "chart.line.uptrend.xyaxis", startingPrice: 200_000, turnaroundDays: 7, isProOnly: true),
            ServiceOffering(id: uuid(56), name: "Pro Service Console", detail: "Matrix-routed approvals, SLAs and a full audit trail.",
                            systemImage: "square.grid.2x2", startingPrice: 45_000, turnaroundDays: 1, isProOnly: true),
        ]
    }

    static func tickets() -> [ServiceTicket] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            ServiceTicket(id: uuid(61), reference: "AQR-4471", serviceName: "Maintenance & Repairs",
                           assetName: "Harborview Residences", created: calendar.date(byAdding: .day, value: -3, to: base)!,
                           stage: .inProgress),
            ServiceTicket(id: uuid(62), reference: "AQR-4468", serviceName: "Legal & Documentation",
                           assetName: "Harborview Residences", created: calendar.date(byAdding: .day, value: -9, to: base)!,
                           stage: .completed),
            ServiceTicket(id: uuid(63), reference: "AQR-4480", serviceName: "Property Management",
                           assetName: "Anchor Point Offices", created: calendar.date(byAdding: .day, value: -1, to: base)!,
                           stage: .scheduled),
        ]
    }

    static func responsibilityMatrix() -> [ResponsibilityEntry] {
        [
            ResponsibilityEntry(id: uuid(71), scope: "Rent collection & payouts", role: .owner, personName: "Adaeze Nwosu"),
            ResponsibilityEntry(id: uuid(72), scope: "Maintenance approvals", role: .manager, personName: "Tunde Bakare"),
            ResponsibilityEntry(id: uuid(73), scope: "Lease renewal sign-off", role: .owner, personName: "Adaeze Nwosu"),
            ResponsibilityEntry(id: uuid(74), scope: "Service payments ≤ ₦250k", role: .agent, personName: "Kelechi Nwosu"),
            ResponsibilityEntry(id: uuid(75), scope: "Maintenance reporting", role: .tenant, personName: "Fatima Bello"),
        ]
    }

    static func announcements() -> [Announcement] {
        let calendar = Calendar.current
        let base = calendar.startOfDay(for: .now)
        return [
            Announcement(id: uuid(81), title: "Q3 service levy",
                         body: "Pro service charges for the quarter are due on the 15th. Statements are available in the Vault.",
                         posted: calendar.date(byAdding: .day, value: -2, to: base)!, isPinned: true),
            Announcement(id: uuid(82), title: "Water supply interruption",
                         body: "Scheduled works at Marine Parade on Thursday, 08:00–13:00. Storage tanks should be filled the night before.",
                         posted: calendar.date(byAdding: .day, value: -6, to: base)!, isPinned: false),
            Announcement(id: uuid(83), title: "Updated visitor protocol",
                         body: "All guests must be registered at the gate. Tenants can pre-register visitors from the app.",
                         posted: calendar.date(byAdding: .day, value: -12, to: base)!, isPinned: false),
        ]
    }

    // MARK: - Helpers

    private static func uuid(_ n: Int) -> UUID {
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012d", n))!
    }
}