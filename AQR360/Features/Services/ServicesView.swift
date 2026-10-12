import SwiftUI

struct ServicesView: View {
    @Environment(AppStore.self) private var store

    @State private var selectedOffering: ServiceOffering?

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: Metric.l) {
                    ticketsSection
                    catalogueSection
                }
                .padding(.horizontal, Metric.l)
                .padding(.bottom, Metric.xl)
            }
            .background(Brand.canvas)
            .navigationTitle("Services")
            .sheet(item: $selectedOffering) { offering in
                BookServiceSheet(offering: offering)
                    .presentationDetents([.medium, .large])
                    .presentationCornerRadius(Metric.sheetRadius)
            }
        }
    }

    // MARK: - Sections

    private var ticketsSection: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Your tickets", subtitle: "Track every request")

            if store.tickets.isEmpty {
                AQCard {
                    ContentUnavailableView("No tickets",
                                           systemImage: "tray",
                                           description: Text("Booked services will appear here."))
                }
            } else {
                AQCard {
                    VStack(spacing: 0) {
                        ForEach(store.tickets) { ticket in
                            TicketDetailRow(
                                ticket: ticket,
                                onAdvance: { store.advance(ticket) }
                            )
                            if ticket.id != store.tickets.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
    }

    private var catalogueSection: some View {
        VStack(alignment: .leading, spacing: Metric.m) {
            AQSectionHeader("Service catalogue", subtitle: "From trusted providers")

            ForEach(store.services) { offering in
                ServiceRow(offering: offering) { selectedOffering = offering }
            }
        }
    }
}

// MARK: - Pieces

private struct TicketDetailRow: View {
    let ticket: ServiceTicket
    let onAdvance: () -> Void

    var body: some View {
        HStack(spacing: Metric.m) {
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: Metric.s) {
                    Text(ticket.serviceName)
                        .font(.subheadline.weight(.semibold))
                    AQBadge(text: ticket.stage.rawValue, tone: ticket.stage.tone)
                }
                Text("\(ticket.reference) · \(ticket.assetName)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: Metric.s)

            if ticket.stage != .completed && ticket.stage != .cancelled {
                Button("Advance", systemImage: "arrow.right") { onAdvance() }
                    .labelStyle(.iconOnly)
                    .aqGlassButtonStyle()
                    .accessibilityLabel("Advance ticket \(ticket.reference) to the next stage")
            } else {
                Image(systemName: ticket.stage.systemImage)
                    .foregroundStyle(ticket.stage.tone.foreground)
            }
        }
        .padding(.vertical, Metric.s)
    }
}

private struct ServiceRow: View {
    let offering: ServiceOffering
    let onBook: () -> Void

    var body: some View {
        Button(action: onBook) {
            AQCard {
                HStack(alignment: .top, spacing: Metric.m) {
                    Image(systemName: offering.systemImage)
                        .font(.title3)
                        .foregroundStyle(offering.isProOnly ? Brand.accent : Brand.primary)
                        .frame(width: 42, height: 42)
                        .background(
                            (offering.isProOnly ? Brand.accent : Brand.primary).opacity(0.12),
                            in: .rect(cornerRadius: Metric.chipRadius)
                        )

                    VStack(alignment: .leading, spacing: 3) {
                        HStack(spacing: Metric.s) {
                            Text(offering.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            if offering.isProOnly {
                                AQBadge(text: "Pro", systemImage: "star.fill", tone: .accent)
                            }
                        }
                        Text(offering.detail)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.leading)
                        HStack(spacing: Metric.m) {
                            Text("From \(offering.startingPrice.formatted(.currency(code: "USD")))")
                                .font(.caption.weight(.medium))
                                .foregroundStyle(Brand.primary)
                            Label("\(offering.turnaroundDays)d", systemImage: "clock")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Booking sheet

private struct BookServiceSheet: View {
    @Environment(\.dismiss) private var dismiss

    let offering: ServiceOffering

    @State private var assetName = ""
    @State private var note = ""
    @State private var confirmed = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Service") {
                    LabeledContent("Provider", value: offering.name)
                    LabeledContent("Starting at", value: offering.startingPrice.formatted(.currency(code: "USD")))
                    LabeledContent("Turnaround", value: "\(offering.turnaroundDays) days")
                }

                Section("Where") {
                    TextField("Asset name", text: $assetName)
                }

                Section("Notes") {
                    TextField("Anything the provider should know?", text: $note, axis: .vertical)
                        .lineLimit(3...6)
                        .writingToolsBehavior(.disabled)
                }

                if confirmed {
                    Section {
                        Label("Request submitted. Track it under Your tickets.",
                              systemImage: "checkmark.seal.fill")
                            .foregroundStyle(Brand.success)
                            .font(.callout)
                    }
                }
            }
            .navigationTitle("Book service")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(confirmed ? "Done" : "Submit") {
                        if confirmed { dismiss() } else { confirmed = true }
                    }
                    .disabled(!confirmed && assetName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview("Services") {
    ServicesView()
        .environment(AQRFixture.store)
}