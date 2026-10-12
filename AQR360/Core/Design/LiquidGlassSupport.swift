import SwiftUI

/// Liquid Glass adoption, gated for the iOS 18 deployment target.
///
/// Glass is a visual upgrade, never a functional requirement: each helper has a
/// plain-material fallback so the app stays fully usable on iOS 18–25 and under
/// Reduce Transparency.
extension View {

    /// Glass treatment for a card-like container.
    @ViewBuilder
    func aqGlass(tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            if let tint {
                self.glassEffect(.regular.tint(tint), in: .rect(cornerRadius: Metric.cardRadius))
            } else {
                self.glassEffect(.regular, in: .rect(cornerRadius: Metric.cardRadius))
            }
        } else {
            self
                .background(.regularMaterial, in: .rect(cornerRadius: Metric.cardRadius))
        }
    }

    /// Glass button style. Use `prominent: true` for the one primary action.
    ///
    /// Written as explicit branches rather than a ternary: a ternary over two
    /// unrelated button styles collapses to the bare `ButtonStyle` protocol and
    /// fails to infer `.bordered` / `.glass`.
    @ViewBuilder
    func aqGlassButtonStyle(prominent: Bool = false, tint: Color? = nil) -> some View {
        if #available(iOS 26, *) {
            if let tint {
                if prominent {
                    self.buttonStyle(.glass(.regular.tint(tint)))
                } else {
                    self.buttonStyle(.glass(.clear))
                }
            } else if prominent {
                self.buttonStyle(.glassProminent)
            } else {
                self.buttonStyle(.glass)
            }
        } else {
            if prominent {
                self.buttonStyle(.borderedProminent)
            } else {
                self.buttonStyle(.bordered)
            }
        }
    }
}

/// Groups related glass shapes so they blend and morph together.
///
/// Falls back to a plain `Group` below iOS 26 — the grouped children simply
/// render without glass.
@ViewBuilder
func aqGlassGroup<Content: View>(spacing: CGFloat, @ViewBuilder content: () -> Content) -> some View {
    if #available(iOS 26, *) {
        GlassEffectContainer(spacing: spacing) { content() }
    } else {
        content()
    }
}