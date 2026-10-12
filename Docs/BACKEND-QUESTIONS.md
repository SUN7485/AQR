# Questions for the backend team

Send this list as-is. Everything in **Confirmed** came from the running
production product; everything in **Unconfirmed** is an assumption we have
deliberately not coded against.

---

## Confirmed — we read these off the live product

Source: `window.__NUXT__.config.public` in the served HTML of `/`, `/market`,
`/services`, `/assets`, `/assets/pro` and `/register`, plus 101 compiled route
chunks. **No endpoint was called.**

**Runtime config**

```
siteUrl             https://www.aqr360.com
apiBase             https://api.aqr360.com
assetUrl            https://api.aqr360.com
appEnvironment      production
defaultCountryCode  AE
currency            AED
```

**API paths recovered from the bundles**

```
/api/client/v1/listings/
/api/client/v1/seo/market-categories/
/api/client/v1/seo/service-categories/
/api/client/v1/seo/redirect
/api/client/v1/vendors/agents/
/api/client/v1/vendors/service-providers/
/api/client/v1/ApplicationStatus
/api/client/v1/AssetProCheckout/exchange     (POST, body: flowId, exchangeCode)
```

**Response envelope — token-level only:** `isSuccess`, `data`, `message`,
`pageSize`, `totalCount`, `totalRecords`.

**Infrastructure in use**

| Concern | Provider |
| --- | --- |
| Auth | Firebase Auth (`firebaseProjectId: aqr360-86afe`) |
| Push | Firebase Cloud Messaging |
| File storage | Firebase Storage |
| Maps | Mapbox |
| Payments | Telr (`TelrIframeCheckout`) |
| Bot defence | reCAPTCHA |

---

## The seven questions

**1. Is there an OpenAPI/Swagger document for `api.aqr360.com`?**
Everything below would fall out of it. If one exists we would rather read it
than reverse-engineer shapes.

**2. Should native iOS use Firebase Auth directly, or AQR360's own token pair?**
The web client holds `token` / `refreshToken` / `tokenExpiresAt` in its auth
store. Do you want the native app to talk to Firebase directly, or exchange a
Firebase session for AQR360 tokens?

**3. What sign-in methods must native support — OTP, passkeys, or both?**
The web product uses OTP. Apple requires Sign in with Apple if third-party
social login is offered, which would change the iOS build.

**4. What is `AssetProCheckout/exchange` for?**
It is wired to `/native-checkout/asset-pro` with an `exchangeCode` fragment
pattern. Is it a handoff for completing a web checkout, and does it require a
native deep link that does not exist yet?

**5. Are `seo/redirect` and `ApplicationStatus` needed on native?**
We cannot tell from the bundles whether they are web-only plumbing.

**6. Can you provide request/response samples for `listings/` and
`seo/service-categories/`?**
Specifically the field names inside `data`, plus the HTTP verb, query parameters
and pagination index field for each. `pageSize` / `totalCount` /
`totalRecords` suggests page-index paging, but the index field is unnamed.

**7. Is there a sandbox base URL, and what are the rate limits?**
`api.aqr360.com` is production. We would want a non-production host for
integration work, plus limits so we can size retry and cache behaviour.

---

## Also worth confirming

- The `Authorization` header shape. We assume `Bearer <accessToken>`, unverified.
- Whether `listings/` returns geo coordinates, and at what precision — this
  determines whether the native map view is possible or pointless.
- Whether asset/tenant data is scoped server-side per user, or whether the
  client is expected to filter. This drives tenant isolation on our side.
- Currency: is `AED` ever per-user or per-market, or always global? We have
  hardcoded `AppConfiguration.verified` but wired it to be server-assignable.
- Document storage: are vault documents behind signed URLs from Firebase
  Storage, or proxied through the API?