# AQR360 for iOS — agent guide

Read this before changing the app. It records the conventions the code actually
follows, so new work matches rather than introduces a second dialect.

## Stack

- SwiftUI, Swift 6, iOS 18 deployment target, built with the iOS 26 SDK
- MV with `@Observable` — **no view models**
- Liquid Glass adopted behind availability gates (see below)

## Project layout

`AQR360.xcodeproj` uses a **file-system synchronized group** (Xcode 16+,
`PBXFileSystemSynchronizedRootGroup`). Adding a `.swift` file anywhere under
`AQR360/` is enough — no `project.pbxproj` edit. Do not hand-edit the pbxproj
to add files.

## Conventions

**State**

- `@MainActor @Observable` for stores. Observation is not thread safety.
- `@State` owns objects a view creates; `let` / `@Bindable` receives them.
- Shared stores go through `.environment(...)`.
- `@AppStorage` stays in views, never inside an `@Observable` class.

**Views**

- `NavigationStack`, never `NavigationView`.
- `.task` for async loading, never a hand-rolled `Task` in `onAppear`.
- Stable `Identifiable` IDs — never array indices.
- `LazyVStack` / `LazyVGrid` for collections.
- `foregroundStyle(_:)`, not `foregroundColor(_:)`.
- No `AnyView`. Branch with `@ViewBuilder`.
- Keep heavy work out of `body`; hoist to a computed property or a local `let`.
- Extract a subview when it branches, owns state, has its own async lifecycle,
  or wants its own preview — not just because a view is long.

**Liquid Glass**

Glass lives in the controls and navigation layer, never on content backgrounds.
`Core/Design/LiquidGlassSupport.swift` owns all gating:

- `aqGlass(tint:)` — glass on a card-like container
- `aqGlassButtonStyle(prominent:tint:)` — glass button style
- `aqGlassGroup(spacing:content:)` — `GlassEffectContainer` equivalent

Always use those helpers rather than calling `.glassEffect()` or
`.buttonStyle(.glass)` directly — the deployment target is iOS 18 and those
APIs are iOS 26-only. Every helper has a material/bordered fallback, so the app
stays usable on iOS 18–25 and under Reduce Transparency.

`if #available(iOS 26, *)` blocks exist only in `LiquidGlassSupport.swift` and
`ListingDetailView`.

**Brand**

All colour, spacing and radius values come from `Core/Design/Brand.swift`
(`Brand`, `Metric`). Do not hard-code hex values or magic numbers in views.

## Layout rules

- Prefer adaptive stack spacing (omit `spacing:`) unless a specific value is
  intentional.
- Semantic colours so light/dark mode works without branching.
- Every interactive control needs an accessibility label if the icon alone
  doesn't name it.

## Before you commit

```bash
node Scripts/swift-lint.mjs     # structural + policy checks
```

There is no local Swift toolchain on Windows, so `swift-lint.mjs` is the gate
you can actually run. It checks:

- balanced braces / parens / brackets (comments and string literals stripped)
- strings that do not close on their line, and unbalanced `\(...)`
- iOS 26 APIs used outside an `#available` gate — `.glassEffect`,
  `.buttonStyle(.glass)`, `GlassEffectContainer`
- `NavigationView`, `ObservableObject`, `foregroundColor`, `AnyView`,
  range/index-based `ForEach` ids, `TODO`/`FIXME`

It is a lint, not a type checker. To actually compile:

```bash
builder ios build        # compiles on macOS via GitHub Actions
```

If you add a new iOS-26-only API, put the gate in `LiquidGlassSupport.swift`
and add a wrapper — do not scatter `#available` blocks through features.