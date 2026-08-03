# Subscriptions — store setup (Google Play + Apple)

_Written 2026-08-03. Companion to `Apps/subscriptions/config.py`, which is the single source
of truth for the schedule and the product ids._

## What is being sold

A monthly subscription whose price steps down four times over a year and then becomes free
forever.

| Stage | Months | Price | Play base plan | Apple product id |
|---|---|---|---|---|
| **Spark** | 1–3 | $19.99 | `spark` | `com.nowlii.pro.spark` |
| **Rhythm** | 4–6 | $14.99 | `rhythm` | `com.nowlii.pro.rhythm` |
| **Independence** | 7–9 | $9.99 | `independence` | `com.nowlii.pro.independence` |
| **Release** | 10–12 | $4.99 | `release` | `com.nowlii.pro.release` |
| **Graduated** | 13+ | free | — | — |

**This is Google Play Billing and Apple In-App Purchase — not Google Pay or Apple Pay.**
Those are for physical goods and services; digital content inside an app must go through the
stores' own billing, and using anything else gets the app removed.

## Why four products instead of one

Neither store can express this ladder in a single product:

- A **Google Play offer allows at most two pricing phases**.
- An **Apple introductory offer is a single phase**.

So each price is its own store product and the subscriber moves down the ladder by changing
plan. **Graduated is deliberately not a product** — neither store sells a $0 renewing
subscription, so reaching it means cancelling in the store and serving access from our own
records.

> ⚠️ **The consequence you are accepting.** Neither store offers a *server-side* API to move
> a subscriber to a cheaper plan. Only the device can do it. A user who stops opening the app
> keeps paying the older, higher price and is never told. The backend records the first day
> anyone falls behind (`step_down_pending_since`) and the Django admin has a **"paying more
> than the plan"** filter with a day count, so they can be found and refunded. That is
> visibility, not a fix — check it regularly.

---

## Google Play

Order matters: products cannot be tested until the app has been published to a track.

### 1. Create the app
Play Console → **Create app**. Package name **`com.nowlii.app`** (must match
`android/app/build.gradle.kts`). This cannot be changed later.

### 2. Complete the required declarations
Under **Policy → App content**: privacy policy URL, ads, data safety, content rating, target
audience, news declaration. Play will not let you publish to any track until these are done.

> The **privacy policy** is already live and linked in-app. **Terms of Service does not exist
> yet** and is a separate P0 — see `daily-checklist.md`.

### 3. Upload a signed build to internal testing
Needs the **upload keystore**, which does not exist yet (`android/key.properties` is absent
while the signing config in `build.gradle.kts` expects it). Build an AAB, upload it to
**Testing → Internal testing**, add yourself as a tester, and publish that track.

Also register the **release SHA-1** in Google Cloud project `274971792537`, or Google login
dies with `DEVELOPER_ERROR` on the signed build.

### 4. Create the subscription
**Monetize → Products → Subscriptions → Create subscription**.

- Product ID: **`nowlii_pro`** (matches `config.GOOGLE_SUBSCRIPTION_ID`)
- Name and benefits: whatever the listing should say

Then add **four base plans** to that one subscription, using the ids in the table above. All
four are **auto-renewing, monthly**. Set the price for each.

**They must all be base plans of the same subscription** — that is what makes moving between
them a plan change rather than a second subscription.

**Activate every base plan.** A draft base plan cannot be purchased, and this is the most
common reason a test purchase fails with "item unavailable".

### 5. License testers
**Setup → License testing** → add the Gmail accounts that will test. License testers are not
charged, renewals are accelerated, and they may sideload the APK rather than install from Play.

### 6. API access, for receipt verification
**Setup → API access** → link a Google Cloud project → create a **service account** → grant it
permission to **view financial data** and **manage orders and subscriptions**. Download the
JSON key.

That JSON is what the backend needs to verify a purchase. **Do not paste it into chat or
commit it** — it belongs on the box as a file, referenced from `.env`, exactly like the other
secrets.

Access can take a while to propagate after linking. Start this early.

### 7. Real-time developer notifications (recommended, not required for a first test)
A Pub/Sub topic so the backend hears about renewals, cancellations and refunds instead of
polling.

---

## Apple

> **iOS cannot be built on this machine.** Xcode requires macOS. Everything below can be
> *configured* now, but nothing can be tested until there is a Mac.

### 1. Identifier
Certificates, Identifiers & Profiles → the `com.nowlii.app` App ID must have the **In-App
Purchase** capability.

### 2. Subscription group
App Store Connect → your app → **Subscriptions** → create **one group** (e.g. `Nowlii Pro`),
then create the four auto-renewable subscriptions inside it with the product ids above, each
**monthly**.

**One group** is essential: a customer can hold only one subscription per group at a time, so
moving between them is a downgrade rather than a second charge.

### 3. The gate that catches people out
**Your first subscription and first subscription group must be submitted together with a new
app version.** You cannot create a subscription, test it, and ship the app later — the first
one rides along with an app submission. Subsequent subscriptions do not need a new version.

### 4. Agreements
**Business → Agreements, Tax, and Banking**: the **Paid Apps agreement** must be active, with
tax and banking complete. Until it is, products are simply not purchasable and the error does
not explain why.

### 5. Sandbox testers
**Users and Access → Sandbox → Testers**. Sandbox renewals are accelerated. In TestFlight a
subscription renews daily, up to 6 times.

### 6. Server verification key
**Users and Access → Integrations → In-App Purchase** → generate a key for the App Store
Server API, and set up **App Store Server Notifications V2**.

---

## What still has to happen in code

- **`POST /subscriptions/verify-receipt/`** is still a 501 stub. It needs the Play service
  account (and the Apple key) before it can do anything real.
- **The app has no `in_app_purchase` integration yet** — no purchase flow and no plan-change
  flow. `POST /subscriptions/activate/` remains a mock, so today **anyone can "subscribe" for
  free**.
- The backend side of the ladder is done: `GET /me/` carries a `step_down` block and
  `POST /confirm-switch/` records what the store actually did.

## Order to do it in

1. Upload keystore → signed AAB → internal testing track _(unblocks everything on Android)_
2. Play subscription + four base plans, all **activated**
3. License testers
4. Service account for the Developer API
5. App-side `in_app_purchase` + real `verify-receipt`
6. First test purchase on Android
7. Apple — configure now, test when there is a Mac
