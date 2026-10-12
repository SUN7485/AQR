# API integration plan

**Status: contract identified, nothing connected.** No endpoint below has been
called. This document records what was *verified* and what still needs the
backend team to confirm.

## How the contract was found

Not from documentation — there is none public. By reading the Nuxt runtime
config and the compiled route chunks served by `aqr360.com`.

### Runtime config (from `www.__NUXT__.config.public`)

```json
{
  "siteUrl":  "https://www.aqr360.com",
  "apiBase":  "https://api.aqr360.com",
  "assetUrl": "https://api.aqr360.com",
  "appEnvironment": "production",
  "defaultCountryCode": "AE",
  "currency": "AED"
}
```

These are authoritative and identical on every page checked (`/`, `/market`,
`/services`, `/assets`, `/assets/pro`, `/register`).

> **This settled the currency question.** The app's hardcoded `USD` was wrong.
> AQR360 serves AED / `en_AE` / country `AE`. See `Core/Config/AppConfiguration.swift`.

### Endpoints recovered from route chunks

Scanning 101 JS chunks across the app's routes for `/api/client/v1/…`:

| Path | Area | Relevance |
| --- | --- | --- |
| `/api/client/v1/listings/` | Market | Replaces `SampleData.listings()` |
| `/api/client/v1/seo/market-categories/` | Market | Replaces `ListingCategory` |
| `/api/client/v1/seo/service-categories/` | Services | Replaces the service catalogue |
| `/api/client/v1/vendors/service-providers/` | Services | Provider directory |
| `/api/client/v1/vendors/agents/` | Market | Agent attribution on listings |
| `/api/client/v1/seo/redirect` | Routing | Unknown purpose — **ask** |
| `/api/client/v1/ApplicationStatus` | Infra | Unknown purpose — **ask** |
| `/api/client/v1/AssetProCheckout/exchange` | Pro | Matches the Pro upsell button |

`AssetProCheckout/exchange` was recovered from inline bootstrap script on
`/register` and `/native-checkout/asset-pro`. It is a `POST` with
`credentials: include`, `cache: no-store`, body `{ flowId, exchangeCode }`, and
returns `{ isSuccess, data: { context } }`.

### Infrastructure

| Concern | Provider | Evidence |
| --- | --- | --- |
| Auth | **Firebase Auth** | `firebaseApiKey`, `firebaseAuthDomain`, `firebaseProjectId: aqr360-86afe`, plus `token`/`refreshToken`/`tokenExpiresAt` in the auth store |
| Push | **Firebase Cloud Messaging** | `firebaseMessagingSenderId`, `firebaseVapidKey` |
| File storage | **Firebase Storage** | `firebaseStorageBucket` |
| Maps | **Mapbox** | `mapboxToken` (`pk.…`) |
| Payments | **Telr** | `TelrIframeCheckout` chunk, native-checkout route |
| Bot defence | **reCAPTCHA** | `recaptchaSiteKey` |

### Response envelope

Token-level evidence only: `isSuccess`, `pageSize`, `totalCount`,
`totalRecords`. The web client also branches on `data` and `message`.

## Confirmed vs unconfirmed

**Confirmed from the running product** — currency, country, API base, endpoint
paths, response field names, auth/payment/maps providers.

**Unconfirmed — do not build against these yet:**

- Exact request/response JSON shapes per endpoint (field names inside `data`)
- HTTP verbs and query parameters for each path
- The `Authorization` header shape (`Bearer <accessToken>` is likely but unverified)
- Whether `listings/` returns geo coordinates and at what precision
- Pagination model — `pageSize`/`totalCount`/`totalRecords` suggests
  page-index paging, but the index field is unnamed
- Auth flows the native app must support (OTP? passkeys? both?)
- Rate limits and error codes
- `seo/redirect` and `ApplicationStatus` semantics

## Planned shape

`AppStore.load()` stays the single entry point. It currently fills from
`SampleData`; the change is one injected dependency, not a rewrite.

```swift
protocol AQRClient: Sendable {
    func configuration() async throws -> AppConfiguration
    func listings(category: ListingCategory?, page: Int) async throws -> Page<Listing>
    func marketCategories() async throws -> [ListingCategory]
    func serviceCategories() async throws -> [ServiceOffering]
}

@MainActor @Observable final class AppStore {
    private let client: AQRClient

    func load() async {
        isLoading = true
        do {
            async let config = client.configuration()
            async let listings = client.listings(category: selectedCategory, page: 0)
            // … assign, set isDemoData = false, clear the demo banner
        } catch {
            loadError = error.localizedDescription   // already surfaced by the views
        }
        isLoading = false
    }
}
```

`AppStore` already exposes `loadError` and `isLoading`, and the views already
render `ProgressView` and `ContentUnavailableView`. No view needs to change.

## Open questions for the backend team

1. Is there an OpenAPI/Swagger document for `api.aqr360.com`?
2. Should the iOS app use Firebase Auth directly, or the AQR360 token pair
   (`accessToken` + `refreshToken`) issued by a first-party endpoint?
3. Does native iOS need to support OTP sign-in, passkeys, or both? Apple
   requires Sign in with Apple if third-party social login is offered.
4. What is `AssetProCheckout/exchange` for — is it the mobile handoff for a web
   checkout, and does it require a native deep link?
5. Are `seo/redirect` and `ApplicationStatus` endpoints we need, or web-only?
6. Per-endpoint request/response samples for listings and service categories.
7. Rate limits, and whether there is a sandbox base URL distinct from
   `api.aqr360.com`.

## Deliberately not done

- No endpoint called. The contract above came from static assets only.
- No speculative types written against guessed JSON shapes. Guessing `data`
  field names would produce code that compiles and silently decodes nothing.
- No production credentials touched.