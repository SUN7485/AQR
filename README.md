# AQR360 for iOS

Native iOS client for AQR360 — the all-in-one real estate platform at
[aqr360.com](https://www.aqr360.com). SwiftUI, Swift 6, iOS 18+ with a Liquid
Glass treatment on iOS 26+.

## Status

Demo build. Every screen runs against deterministic fixtures in
`AQR360/Data/SampleData.swift`; no network client is wired yet. The seams for
it are already in place — see *Production integration* below.

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

`builder.json` is already set up. See the repo README for signing and TestFlight.

## Production integration

The demo deliberately stops at the UI layer. When wiring the real backend:

- `AppStore.load()` is the single entry point — swap the fixture fill for
  `aqr360.com` REST calls behind the same accessors so no view changes.
- Add an `AuthenticationStore` and inject it alongside `AppStore`; the
  `authentication` skill covers Sign in with Apple and passkeys.
- Booking a Pro service needs StoreKit 2 (`storekit` skill) plus server-side
  receipt validation. Subscription state must gate the Pro tiles, not just
  their appearance.
- The document vault holds title deeds — treat it as sensitive: encrypt at rest
  and gate behind biometrics (`swift-security` skill).
- Push notifications for ticket and announcement updates
  (`push-notifications` skill).

## Agent skills

This project carries the [Swift/iOS agent skills](https://github.com/dpearson2699/swift-ios-skills)
in `.agents/skills` (mirrored to `.claude/skills` and `agent/skills` for other
assistants). 86 skills covering SwiftUI, SwiftData, StoreKit, networking,
accessibility and App Store submission.

`npx skills check` / `npx skills update` keeps them current.