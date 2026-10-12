# AQR360 API — investigated findings

Everything below was obtained by reading public assets and issuing **read-only
`GET` requests only**. No writes, no account creation, no checkout, no auth
bypass, no credential guessing. Timestamps: 2026-10-12.

Use `OBSERVED` for things with direct evidence and `INFERRED` for conclusions
drawn from those facts. Anything marked UNKNOWN could not be established from
public material and needs credentials we do not have.

---

## 1. Base URL — OBSERVED

```
https://api.aqr360.com/api/client/v1
```

`https://api.aqr360.com/client/v1/...` returns **404**. The `/api` segment is
part of the path, not implied by `apiBase`. `https://www.aqr360.com/api/...`
also works as a same-origin proxy.

`GET /api/client/v1/ApplicationStatus` → `200`
```json
{ "mode": "Live", "serverTimeUtc": "2026-10-12T18:29:27.8170627Z" }
```
Note: this endpoint has **no envelope**.

## 2. Response envelope — OBSERVED

```json
{ "data": ..., "isSuccess": true, "errors": [], "responseTime": "...", "responseStatus": 200 }
```

`errors` is an array (empty on success). Observed on every 200 JSON response
tested.

## 3. Pagination — OBSERVED

From `GET /client/v1/Listing/search?pageNumber=1&pageSize=2`:

```json
{ "page": 1, "pageSize": 2, "totalCount": 0, "items": [] }
```

So `page`/`pageSize` in, `page`/`pageSize`/`totalCount`/`items` out. The web
bundles independently reference `pageNumber`/`pageSize` on other services and a
`pagedInfo.totalCount`/`totalRecords` wrapper, so **pagination is not uniform
across endpoints** — it must be verified per endpoint.

## 4. Auth — OBSERVED

`GET /Auth/me`, `/Wallet/balance`, `/announcements`,
`/ServiceTicket/service-definitions`, `/Aqr360Pro/tenant-invitations/pending`,
`/Subscriptions/aqr360-pro/trial-eligibility` → all **401**.

401 response shape: **empty body**, header `WWW-Authenticate: Bearer`.

Error handling must tolerate an empty 401 body — there is no JSON envelope to
decode.

The web client stores a Firebase ID token in `localStorage.firebaseToken` and
sends it as `Authorization: Bearer <token>`. `POST /client/v1/Auth/login`,
`/Auth/refresh` and `/Auth/revoke` exist, alongside OTP flows
(`/Auth/verify-email-otp`, `/Auth/resend-verification-otp`).

**INFERRED:** the API accepts a Firebase ID token directly as its bearer token.
**Not yet proven** — no token was obtained, so no authenticated call was made.

## 5. Currency — OBSERVED

`GET /client/v1/MetaLookup/countries` → 241 entries:

```json
{ "countryId": "AE", "name": "United Arab Emirates", "currencyISO3": "AED",
  "isActive": true, "isBillingEnabled": true, "isStoreEnabled": true }
```

Currency is **derived from the country lookup**. The web app's
`currency: "AED"` / `defaultCountryCode: "AE"` almost certainly comes from this.
Our `AppConfiguration` should be populated from this endpoint rather than
hardcoded.

## 6. Endpoint inventory — OBSERVED

**67 distinct `/client/v1` paths** recovered from 101 shipped JS chunks. No
source maps are published (`.map` → 404).

Public, no auth, `200`:

```
GET /MetaListingCategories              12 items
GET /MetaLookup/countries               241
GET /MetaLookup/service-categories      6
GET /MetaLookup/amenities               38
GET /MetaLookup/menus                   4
GET /MetaLookup/nearby-services         21
GET /MetaLookup/sidebar-navigation-settings
GET /MetaLookup/frontend-home-page-appearance
GET /MetaLookup/social-media-pages
GET /MetaLookup/user-asset-settings     { userManagedAssetLimit }
GET /Listing/search
GET /ApplicationStatus
```

Require auth (`401`): `announcements`, `ServiceTicket/*`, `Auth/me`,
`AssetProCheckout/*`, `Subscriptions/*`, `Wallet/*`, `Aqr360Pro/*`,
`LeadManagement/*`, `Listing/me`, `Aqr360Enterprise`.

**Payments run through Telr** — `AssetProCheckout/telr-link`,
`Payments/telr/link`. **Do not call these.**

## 7. Listing taxonomy — OBSERVED

```
1  RealEstate            (root)
2  For Sale              (root)
3  For Rent (Yearly)     (root)
4  Apartment   5 Studio  6 Villa  7 Townhouse      (under For Sale)
9  Apartment  10 Studio 11 Villa 12 Townhouse     (under For Rent)
8  Land
```

**`For Rent (Yearly)` — rent is quoted yearly, not monthly.** Our fixtures use
`/mo`. This is a factual mismatch to correct.

## 8. BLOCKER — no listing sample exists — OBSERVED

`countOfListing` is **0 on all 12 categories**, and `Listing/search` returns
`totalCount: 0` under every filter tried:

```
?pageNumber=1&pageSize=3                              total=0
?…&listingCategoryId=1                                total=0
?…&categoryId=1                                       total=0
?…&categoryIds=1                                      total=0
?…&countryId=AE                                       total=0
?…&searchTerm=villa                                   total=0
?…&status=1                                           total=0
?…&listingStatusId=1                                  total=0
```

The public market is empty. **We therefore have no real listing item schema**,
and per instruction we will not write a speculative one.

## 9. What we could NOT establish — UNKNOWN

- Field names inside a listing item (no samples — §8)
- Every authenticated response shape
- Whether asset/tenant isolation is enforced server-side
- Rate limits (no 429 observed, but no load was generated)
- Whether a non-production environment exists
- Whether `Firebase project id` ⇒ the API accepts Firebase ID tokens (§4)

## 10. Access we need, and why

| Need | Why |
|---|---|
| **One Firebase test account** (email + password) | Proves §4 and unlocks every authenticated endpoint. Without it no asset, contract, vault, ticket or tenant data can be read. |
| **A seeded asset with ≥1 listing** | Solves §8. The only way to obtain a real listing item schema. |
| **Confirmation of server-side tenant scoping** | Determines whether client-side filtering is defence-in-depth or the only control. |
| **Sandbox base URL, if one exists** | Would let us test authenticated calls without touching production. |

All four are access, not code. Nothing here is blocked by missing knowledge we
could research ourselves.