# AQR360 for iOS

Native iOS client for AQR360 — the all-in-one real estate platform at
[aqr360.com](https://www.aqr360.com). SwiftUI, Swift 6, iOS 18+ with a Liquid
Glass treatment on iOS 26+.

## Status

Demo build. Every screen runs against deterministic fixtures in
`AQR360/Data/SampleData.swift`; no network client is wired yet. `AppStore.isDemoData`
marks it and shows a banner so fixtures are never mistaken for live records.
The seams are already in place — see *Production integration* below.

## Currency and market

**AED**, locale `en_AE`, country `AE`. Not assumed — read from the
`aqr360.com` Nuxt runtime config:

```json
{ "currency": "AED", "defaultCountryCode": "AE", "apiBase": "https://api.aqr360.com" }
```

`Core/Config/AppConfiguration.swift` owns this and is injected through
`EnvironmentValues`. Every money, date and number in the UI formats through
`Core/Design/Formatting.swift` using that configuration, so a server-supplied
currency change is one assignment rather than a sweep through the views.

## Screens

| Tab | What it covers |
| --- | --- |
| **Home** | Portfolio roll-up, quick actions, active tickets, fresh market listings, Care entry |
| **Market** | Searchable + filterable listings, listing detail, agent card |
| **Assets** | Owned properties with income, expenses and occupancy |
| **Services** | Service catalogue, ticket tracking with stage advancement, booking sheet |
| **Account** | Profile, AQR360 Points, payment methods, version |

The **AQR360 Pro workspace** opens from any asset and carries the six Pro
capabilities — Manage, Contracts, Responsibility, Vault, Services, Market —
plus tenant access and announcements. Pro-only tiles stay visible but locked
when an asset has no active subscription, matching the owner-controlled policy
on the web product.

### Screenshots

CI boots a simulator and captures every tab on each push to `main`. Grab them
from the Actions run's `screenshots` artifact:

```bash
gh run download --name screenshots
```

The app opens directly to a tab given `-startTab <name>`, which is how the
capture drives it:

```bash
# locally, in Xcode's scheme arguments
-startTab assets
```

## Architecture

```
AQR360/
├── App/          @main entry point
├── Core/
│   ├── Design/   Brand tokens, components, Liquid Glass helpers
│   └── Models/   Domain types (Listing, Asset, Tenant, Contract, …)
├── Data/         AppStore (@Observable) + SampleData fixtures + preview fixtures
└── Features/
    ├── Root/     TabView
    ├── Home/     Market/ Assets/ Services/ Account/
```

- **MV**, no view models. `@MainActor @Observable` stores, `@Environment`
  injection, `.task` for async work.
- Views never mutate model state directly — `AppStore` owns it.
- Deterministic preview fixtures via `AQRFixture`, so previews never touch the
  network or a shared singleton.

## Brand

Colours are sampled from the production wordmark:

| Token | Value | Use |
| --- | --- | --- |
| `Brand.navy` | `#080070` | Gradient start, hero surfaces |
| `Brand.indigo` | `#303FCE` | Gradient mid |
| `Brand.azure` | `#1888F8` | Accent, primary actions |

`AQR360/Resources/Assets.xcassets/AppIcon.appiconset` is generated from the real
logo composited onto the brand gradient.

## Building

You need a Mac, or a CI runner.

```bash
# macOS
open AQR360.xcodeproj
```

No Mac? [MobAI `ios-builder`](https://github.com/MobAI-App/ios-builder) builds
from Windows or Linux through GitHub Actions:

```bash
builder init
builder ios build
```

`builder.json` is already set up. See that repo's README for signing and
TestFlight.

### Local checks

There is no Swift toolchain on Windows, so `Scripts/swift-lint.mjs` is the gate
you can actually run:

```bash
npm run lint
```

To compile without a Mac, push and read the CI result — the build job is the
real type check.

## Production integration

The demo deliberately stops at the UI layer. The contract has been identified
but **nothing has been called** — see [Docs/API-INTEGRATION.md](Docs/API-INTEGRATION.md)
for the verified endpoints, the providers in play (Firebase Auth/Storage/FCM,
Telr payments, Mapbox, reCAPTCHA) and the seven open questions for the backend
team.

When wiring the real backend:

- `AppStore.load()` stays the single entry point — swap the fixture fill for an
  injected `AQRClient`. No view changes; `isLoading`, `loadError` and
  `isDemoData` are already wired for it.
- `AppConfiguration` should be populated from the server's own config rather
  than the compiled-in default.
- Auth is Firebase-based on the web product. Confirm whether native should use
  Firebase Auth directly or AQR360's own `accessToken`/`refreshToken` pair, and
  whether OTP or passkeys are required — Sign in with Apple is mandatory if
  third-party social login is offered.
- Booking a Pro service needs Telr checkout. Subscription state must gate the
  Pro tiles, not just their appearance.
- The document vault holds title deeds — treat as sensitive: encrypt at rest
  and gate behind biometrics (`swift-security` skill).
- Push notifications for ticket and announcement updates ride on FCM
  (`push-notifications` skill).

## Agent skills

This project vendors the [Swift/iOS agent skills](https://github.com/dpearson2699/swift-ios-skills)
— 86 skills covering SwiftUI, SwiftData, StoreKit, networking, authentication,
push notifications, accessibility and App Store submission.

`.agents/skills` is the canonical tracked copy. `.claude/skills` and
`agent/skills` are generated mirrors for other assistants and are not
committed. Regenerate them with:

```bash
npx skills add dpearson2699/swift-ios-skills --all
npx skills check      # report drift
npx skills update     # pull upstream changes
```

## CI

`.github/workflows/ios-build.yml` runs two jobs on every push:

- **Build (simulator)** — `xcodebuild` against an iOS Simulator destination on
  `macos-15`. Signless, so it needs no Apple Developer account, and it catches
  every compile and link error.
- **Structural lint** — `Scripts/swift-lint.mjs` on `ubuntu-latest`.

The build job is the real type check. If you add a file that does not compile,
that job goes red before anyone opens Xcode.