import SwiftUI

/// Elevated surface used across Home, Market, Assets and the Pro workspace.
struct AQCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(Metric.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card, in: .rect(cornerRadius: Metric.cardRadius))
            .overlay {
                RoundedRectangle(cornerRadius: Metric.cardRadius)
                    .strokeBorder(.primary.opacity(0.06), lineWidth: 1)
            }
    }
}

/// Compact status/label chip.
struct AQBadge: View {
    enum Tone {
        case neutral, accent, success, warning, danger, onBrand

        var foreground: Color {
            switch self {
            case .neutral: .secondary
            case .accent: Brand.accent
            case .success: Brand.success
            case .warning: Brand.warning
            case .danger: Brand.danger
            case .onBrand: .white
            }
        }

        var background: Color {
            switch self {
            case .neutral: Color.primary.opacity(0.07)
            case .accent: Brand.accent.opacity(0.13)
            case .success: Brand.success.opacity(0.13)
            case .warning: Brand.warning.opacity(0.16)
            case .danger: Brand.danger.opacity(0.13)
            case .onBrand: .white.opacity(0.20)
            }
        }
    }

    let text: String
    var systemImage: String?
    var tone: Tone = .neutral

    var body: some View {
        HStack(spacing: Metric.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.caption2.weight(.bold))
            }
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .foregroundStyle(tone.foreground)
        .padding(.horizontal, Metric.s)
        .padding(.vertical, 5)
        .background(tone.background, in: .rect(cornerRadius: Metric.chipRadius))
    }
}

/// Single-value statistic used in Home and the Pro workspace summaries.
struct AQStat: View {
    let value: String
    let label: String
    var systemImage: String?
    var tone: AQBadge.Tone = .accent

    var body: some View {
        VStack(alignment: .leading, spacing: Metric.xs) {
            if let systemImage {
                Image(systemName: systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(tone.foreground)
            }
            Text(value)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .contentTransition(.numericText())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Metric.m)
        .background(Brand.card, in: .rect(cornerRadius: Metric.chipRadius))
    }
}

/// Section header with an optional trailing action.
struct AQSectionHeader<Trailing: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var trailing: Trailing

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.headline)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: Metric.s)
            trailing
        }
    }
}

extension AQSectionHeader where Trailing == EmptyView {
    init(_ title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

/// Full-bleed brand header used at the top of Home and Asset detail.
struct AQHeroHeader<Trailing: View>: View {
    let eyebrow: String
    let title: String
    @ViewBuilder var trailing: Trailing

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Brand.heroGradient

            // Soft light bloom so the flat gradient does not read as a slab.
            Circle()
                .fill(.white.opacity(0.16))
                .frame(width: 260, height: 260)
                .blur(radius: 60)
                .offset(x: 110, y: -70)

            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: Metric.xs) {
                    Text(eyebrow.uppercased())
                        .font(.caption2.weight(.bold))
                        .tracking(1.2)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(title)
                        .font(.largeTitle.weight(.bold))
                        .foregroundStyle(.white)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: Metric.s)
                trailing
            }
            .padding(Metric.l)
        }
        .frame(height: 148)
        .clipShape(.rect(bottomLeadingRadius: Metric.sheetRadius, bottomTrailingRadius: Metric.sheetRadius))
    }
}

extension AQHeroHeader where Trailing == EmptyView {
    init(eyebrow: String, title: String) {
        self.init(eyebrow: eyebrow, title: title) { EmptyView() }
    }
}