import SwiftUI

struct AccountView: View {
    @Environment(AppStore.self) private var store

    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack(spacing: Metric.m) {
                        Text(initials)
                            .font(.title3.weight(.bold))
                            .foregroundStyle(.white)
                            .frame(width: 54, height: 54)
                            .background(Brand.gradient, in: .circle)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.account.name)
                                .font(.headline)
                            Text(store.account.email)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer(minLength: Metric.s)

                        if store.account.isVerified {
                            AQBadge(text: "Verified", systemImage: "checkmark.seal.fill", tone: .success)
                        }
                    }
                    .padding(.vertical, Metric.xs)
                }

                Section("AQR360 Points") {
                    LabeledContent("Balance", value: "\(store.account.pointsBalance.formatted()) pts")
                    Button("Redeem points", systemImage: "gift") { }
                }

                Section("Payments") {
                    LabeledContent("Secured by", value: "Visa · Mastercard")
                    Button("Payment methods", systemImage: "creditcard") { }
                }

                Section("Account") {
                    Button("Profile", systemImage: "person") { }
                    Button("Notifications", systemImage: "bell") { }
                    Button("Security", systemImage: "lock.shield") { }
                }

                Section {
                    LabeledContent("Version", value: Bundle.main.appVersion)
                } footer: {
                    Text("AQR360 — AQR Three Sixty LLC")
                }
            }
            .navigationTitle("Account")
            .listStyle(.insetGrouped)
        }
    }

    private var initials: String {
        store.account.name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
    }
}

extension Bundle {
    var appVersion: String {
        let short = infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }
}

#Preview("Account") {
    AccountView()
        .environment(AQRFixture.store)
}