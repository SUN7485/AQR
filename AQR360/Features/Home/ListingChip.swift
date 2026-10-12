import SwiftUI

/// Compact listing tile used in the Home "Fresh on the market" carousel.
struct ListingChip: View {
    let listing: Listing

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack(alignment: .topLeading) {
                Brand.heroGradient
                Image(systemName: listing.category.systemImage)
                    .font(.system(size: 34, weight: .light))
                    .foregroundStyle(.white.opacity(0.25))
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                    .padding(Metric.s)

                if listing.isPro {
                    AQBadge(text: "Pro", systemImage: "star.fill", tone: .onBrand)
                        .padding(Metric.s)
                }
            }
            .frame(height: 96)

            VStack(alignment: .leading, spacing: Metric.xs) {
                Text(listing.title)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)

                Text(listing.priceLabel)
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(Brand.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(listing.specSummary)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .padding(Metric.m)
        }
        .frame(width: 190, alignment: .leading)
        .background(Brand.card, in: .rect(cornerRadius: Metric.cardRadius))
        .clipShape(.rect(cornerRadius: Metric.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: Metric.cardRadius)
                .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
        }
    }
}