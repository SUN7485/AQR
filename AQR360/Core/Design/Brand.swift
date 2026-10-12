import SwiftUI

/// AQR360 brand tokens.
///
/// Sampled directly from the production `aqr360.com` wordmark: a navy-to-azure
/// diagonal gradient (`#080070` -> `#1888F8`).
enum Brand {

    // MARK: - Core palette

    static let navy = Color(red: 0.031, green: 0.000, blue: 0.439)
    static let azure = Color(red: 0.094, green: 0.533, blue: 0.973)
    static let indigo = Color(red: 0.188, green: 0.259, blue: 0.824)

    /// Primary brand mark — used for gradients and prominent fills.
    static let gradient = LinearGradient(
        colors: [navy, indigo, azure],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Flattened mid-tone, for places a gradient cannot go (nav bar tint, etc).
    static let primary = Color(red: 0.106, green: 0.196, blue: 0.702)

    // MARK: - Semantic

    static let accent = azure
    static let success = Color(red: 0.118, green: 0.702, blue: 0.451)
    static let warning = Color(red: 0.929, green: 0.639, blue: 0.180)
    static let danger = Color(red: 0.878, green: 0.239, blue: 0.271)

    // MARK: - Surfaces

    static let canvas = Color(uiColor: .systemGroupedBackground)
    static let card = Color(uiColor: .secondarySystemGroupedBackground)

    // MARK: - Gradients by role

    static let heroGradient = LinearGradient(
        colors: [navy, indigo],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    static let accentGradient = LinearGradient(
        colors: [indigo, azure],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Spacing & radius scale

enum Metric {
    static let xs: CGFloat = 4
    static let s: CGFloat = 8
    static let m: CGFloat = 12
    static let l: CGFloat = 16
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32

    static let cardRadius: CGFloat = 18
    static let chipRadius: CGFloat = 10
    static let sheetRadius: CGFloat = 28
}