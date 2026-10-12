# Integration plan — Firebase Auth and the AQR API

**Nothing here is implemented.** No endpoint has been called and no credentials
exist in this repo. This is a plan to execute once
[BACKEND-QUESTIONS.md](BACKEND-QUESTIONS.md) is answered.

Gate: **do not begin until questions 1, 2, 3 and 7 are answered.** Those four
determine the auth model, the host and the sign-in surface. Starting earlier
means writing code against guesses.

---

## Phase 0 — Contracts (blocked on backend)

- Obtain the OpenAPI document, or annotated samples for `listings/`,
  `seo/market-categories/` and `seo/service-categories/`.
- Get a sandbox base URL and credentials for it.
- Confirm the auth token shape.

**Exit criteria:** every endpoint we intend to call has a known verb, path,
query shape and response schema, written down. No code yet.

## Phase 1 — Transport layer

`AQRClient`, a `Sendable` actor wrapping `URLSession`.

- `AQRAPIError` — a real enum mapping HTTP status and `isSuccess` to typed
  cases: `.unauthenticated`, `.forbidden`, `.notFound`, `.rateLimited(retryAfter)`,
  `.server(status)`, `.decoding(underlying)`, `.transport(underlying)`.
- `Endpoint<T>` — path, method, query, body, `Decodable` result type. One place
  that knows how a request is shaped.
- Auth injected as a closure the client calls per request, so the client never
  imports Firebase. Keeps it testable.
- Retry **only** idempotent verbs, only on 429/5xx, with jittered backoff.
  Never retry a POST that mutates — `AssetProCheckout/exchange` is not
  idempotent and a blind retry creates duplicate checkouts.
- Request logging redacts `Authorization`, and never logs a token to console.

## Phase 2 — Authentication

Blocked on question 2.

- `AuthStore` — `@MainActor @Observable`, holds `authState`:
  `.unknown`, `.signedOut`, `.signingIn`, `.signedIn(profile)`.
- Sign in and sign out flows behind a protocol, so the Firebase implementation
  is swappable and unit-testable with a stub.
- **Token handling is the part that gets apps rejected.** Tokens go in the
  Keychain, never `UserDefaults`, never in SwiftData. See the `swift-security`
  skill.
- Biometric gate (`LAContext`) before revealing vault documents, independent of
  app lock state.
- Session expiry: on 401, attempt one refresh, then sign out cleanly. Never
  loop.

## Phase 3 — Authorization and tenant isolation

The most important phase, and the easiest to get wrong.

- **Assume nothing is filtered server-side.** Until the backend confirms
  otherwise, treat every list response as potentially containing other users'
  rows, and filter locally as defence in depth — never as the control.
- Key every asset and document to an owner identifier and assert it in the
  view model before rendering. A row without a matching owner is dropped, not
  displayed.
- Pro capabilities gate on `asset.isProSubscribed`, and that flag must come
  from the server. Client-side gating is UX; the server must re-check on every
  Pro call.
- **Never ship the vault contents in logs, analytics, or crash reports.**
- Test: a signed-in user must not be able to reach another user's asset by any
  navigation path, including deep links.

## Phase 4 — Wiring the store

`AppStore.load()` is already shaped for this and no view should need to change.

- Replace the `SampleData` fill with `AQRClient` calls.
- Set `isDemoData = false` only when a client actually served the data. The
  Home banner then disappears on its own.
- `loadError` is already surfaced. Add per-section partial failure: if service
  categories fail but listings succeed, render what loaded and show an inline
  retry for the rest. Do not blank the whole screen.
- `AppConfiguration` should arrive from the server, not the compiled-in
  `AQR360` / `AED` default.
- Map server pagination onto the existing lists, and pull-to-refresh advances
  pages.

## Phase 5 — Testing

**Unit**
- `AQRAPIError` mapping: status code and `isSuccess` combinations.
- Decoding against fixture JSON captured from the sandbox. Golden files, so a
  schema change fails loudly.
- Token storage: written to Keychain, absent from `UserDefaults`.
- Redaction: no token appears in any log line.
- Retry policy: retries 429/5xx, does not retry POST, honours `Retry-After`.

**Integration** (against the sandbox only)
- Sign in, token refresh on expiry, sign out clears Keychain.
- Every endpoint returns and decodes.
- A 401 mid-session refreshes exactly once.

**Isolation — the tests that matter most**
- User A cannot see, fetch or reach user B's assets, tenants or documents.
- Expired or missing Pro subscription hides Pro tiles and the server rejects
  the call even if the client asks.

**UI**
- Launch argument driven screenshot capture, which already exists. Extend the
  existing CI job rather than adding a second harness.

---

## What stays unchanged

- SwiftUI, and every existing view. The client is a drop-in behind the store.
- `AppConfiguration` as the single source of currency and locale.
- `isDemoData` as the single flag distinguishing fixtures from live data.
- The router and launch-argument capture that CI already uses.

## Blockers, in order

1. No OpenAPI document or response samples — **blocks everything**
2. Auth model undecided (Firebase direct vs AQR360 tokens) — blocks Phase 2
3. Sign-in method surface unknown — affects whether Sign in with Apple is
   required, which changes the build
4. No sandbox host or credentials — blocks all integration testing
5. Server-side tenant scoping unconfirmed — Phase 3 cannot be proven correct
   until it is