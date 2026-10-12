# Questions for the AQR360 backend team

> **Forward this as-is.** Everything below is plain-language and needs no
> knowledge of the iOS app. The "why it matters" lines are here so whoever
> answers can judge priority.

Context: we are building a native iPhone app for AQR360. Before it can talk to
your API we need four things settled. Without them we would be coding against
guesses, and guesses become expensive to undo.

---

## Q1. Is there an API document we can read?

**What we need**

Either a machine-readable API document (OpenAPI / Swagger, or a link to one), or
written examples of the actual request and response for each endpoint we use:

- `GET /api/client/v1/listings/`
- `GET /api/client/v1/seo/market-categories/`
- `GET /api/client/v1/seo/service-categories/`
- `GET /api/client/v1/vendors/agents/`

For each one, we need:

1. The HTTP method and the full query parameters, including defaults.
2. The exact field names returned, with an example response body.
3. How a large result set is paged. We can see `pageSize`, `totalCount` and
   `totalRecords` in your web client's responses, but not how you ask for the
   second page.
4. How errors are returned — the HTTP status, and the shape of the error body.

**Who should answer** — whoever owns the `api.aqr360.com` service.

**What depends on it**

Everything. Until we know the real field names we cannot write the screen that
displays listings. A guessed field name compiles fine and then silently shows an
empty list on a user's phone, which is worse than a crash because it looks like
"no results" rather than an error.

---

## Q2. How should the iPhone app authenticate?

**What we need**

A decision on which of these the iOS app should do:

- **(a)** Sign in with Firebase directly on the device, using your existing
  Firebase project (`aqr360-86afe`), and send the resulting token to your API.
- **(b)** Sign in against your own authentication endpoint, which then issues
  the `accessToken` / `refreshToken` pair your web app already uses.

If (b), we need the endpoint, the request body, and the token lifetime.

If (a), we need confirmation that Firebase is the right choice for native, and
whether your API accepts a Firebase ID token.

We also need to know how a long-lived session is kept alive: how the app
refreshes an expired token, and what it should do when the refresh fails.

**Who should answer** — whoever owns authentication and the mobile token flow.

**What depends on it**

The entire sign-in screen, and where credentials are stored on the device.
Getting this wrong means reworking sign-in, session handling and logout after
the app has shipped. It is also the part most likely to be rejected in App
Store review if handled improperly.

---

## Q3. Which sign-in methods must the iPhone app offer?

**What we need**

A clear list. At minimum we need to know:

- Is one-time passcode (OTP) by SMS required? The web product appears to use it.
- Must the app also support passkeys or Sign in with Apple?
- Is Google or Apple social sign-in offered on the web today?

**Who should answer** — product owner, with whoever handles auth compliance.

**What depends on it**

Apple requires any app offering third-party social login to also offer **Sign
in with Apple**, or to explain why it does not. Finding this out after building
sign-in means rebuilding the screen and resubmitting. If the answer is "social
login only", the cost of building Sign in with Apple from the start is far lower
than adding it later.

---

## Q7. Is there a test environment, and what are the limits?

**What we need**

1. **A non-production API address.** `api.aqr360.com` is the live system. We need
   a separate host — staging or sandbox — that we may point the app at. If one
   does not exist, we need to know, because it changes our testing plan.
2. **Test credentials** for that environment.
3. **Rate limits** — how many requests per minute/second, per endpoint, and
   per authenticated user.
4. **Whether there is a maintenance or freeze window** we must avoid, for
   example an App Store release period.

**Who should answer** — whoever operates the API environment, plus whoever
handles release scheduling.

**What depends on it**

All integration testing. We will not point a real app at production data
without an explicit go-ahead. Rate limits decide how we cache and how often we
refresh, and whether we need to debounce actions such as search. A freeze
window decides whether an app release can be tested end to end at all.

---

## Also worth answering, lower priority

- Are assets, tenants and documents already separated per user on the server,
  or should the app filter as well? We will not treat client-side filtering as
  a security control, but it changes what we verify.
- Does `GET /listings/` return latitude and longitude, and at what precision?
  This decides whether an in-app map is useful.
- Is the currency always AED, or can it vary per user or per market? We have
  currently built assuming AED.
- Are documents in the vault delivered as time-limited signed links, or proxied
  through the API?

---

## Already confirmed — no action needed

We verified these from the live website, so you do not need to check them:

- Currency is **AED**; default country is **AE**; locale **en_AE**
- API base is **`https://api.aqr360.com`**
- Route prefix is **`/api/client/v1/`**
- Authentication is Firebase-based; push is Firebase Cloud Messaging; storage is
  Firebase Storage; payments run through Telr; maps through Mapbox
- Response envelope carries `isSuccess`, `data`, `message`, `pageSize`,
  `totalCount`, `totalRecords`