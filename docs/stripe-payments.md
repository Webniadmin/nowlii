# Payments — Stripe Checkout

_Written 2026-09-16. The live payment path. The store-IAP alternative is in
`subscriptions-iap.md`, which is now **parked**, not deleted — see the end of this file._

## What is sold, and why Stripe

A monthly subscription whose price steps down four times over a year and then becomes free
forever.

| Stage | Months | Price | Stripe phase |
|---|---|---|---|
| **Spark** | 1–3 | $19.99 | `duration: 3 months` |
| **Rhythm** | 4–6 | $14.99 | `duration: 3 months` |
| **Independence** | 7–9 | $9.99 | `duration: 3 months` |
| **Release** | 10–12 | $4.99 | `duration: 3 months` |
| **Graduated** | 13+ | free | *(not a phase — the schedule ends)* |

**A Stripe subscription schedule is exactly this shape**: an ordered list of phases, each
with its own price and a duration in months. Stripe walks the subscriber down the
ladder itself, server-side, with nothing required from the app.

Neither store can do that. A Google Play offer carries **at most two pricing phases** and an
Apple introductory offer **one**, so the ladder would need four products per store; and
neither store has a *server-side* plan change, so every step down would depend on the user
opening the app. Someone who stopped opening it would keep paying $19.99 forever and never be
told. That entire class of problem does not exist here.

**Graduated falls out of the same mechanism.** The schedule's `end_behavior` is `cancel`, so
when month 12 finishes Stripe cancels the subscription, `customer.subscription.deleted`
arrives, and the handler sees a user past `FREE_AFTER_MONTH` and grants `lifetime_free`.
Stripe never has to sell a $0 renewing plan, which it cannot do.

---

## The pieces

| File | What it is |
|---|---|
| `Apps/subscriptions/config.py` | **The schedule. The only place prices are written down.** |
| `Apps/subscriptions/stripe_gateway.py` | Every Stripe SDK call. Nothing else imports `stripe`. |
| `Apps/subscriptions/webhooks.py` | The five events, each idempotent. |
| `Apps/subscriptions/views.py` | `checkout/`, `portal/`, `cancel/`, `resume/`, `webhook/` |
| `management/commands/sync_stripe_prices.py` | Creates the Stripe prices **from** `config.PHASES`. |
| `lib/services/subscription_service.dart` | `startCheckout()`, `openBillingPortal()`, `resume()` |
| `lib/screen/settings/subscription/nowli_pro_subscription.dart` | The paywall and the buttons. |

### The flow

1. App `POST /api/subscriptions/checkout/` → backend creates a Stripe Checkout Session and
   returns its URL.
2. App opens that URL **in the device's browser** — `LaunchMode.externalApplication`.
3. User pays on Stripe's page. No card detail touches this app or this backend.
4. `checkout.session.completed` → backend records the ids, sets `started_at`, marks the row
   ACTIVE, and attaches the rest of the ladder as a schedule.
5. App returns to the foreground → re-reads `/subscriptions/me/` → paywall opens.

There is **no deep link**, on purpose. The app refreshes whenever it resumes, which also
works if the user closes the tab, switches apps, or finishes checkout on another device.

---

## Rules that are deliberate — do not "simplify" these

**The webhook is the only thing that grants access.** A checkout URL is an invitation to pay.
The app never marks itself subscribed on return; it asks the backend, which knows.

**The webhook is signature-verified, always.** It is the one public route in the app. With
`STRIPE_WEBHOOK_SECRET` unset it refuses everything — an unverified webhook is an endpoint
that hands a paid subscription to anyone who can POST JSON.

**Every event id is recorded before a handler runs** (`StripeEvent`). Stripe retries until it
gets a 2xx and is explicit that an event can arrive twice; every handler writes something, so
a replay is not harmless.

**Cancelling stops the plan at `current_period_end`, not immediately.** They paid for the
month. Keeping the money and removing what it bought is unfair and the shortest path to a
chargeback. `POST /resume/` calls it off while it is still pending.

**A failed charge does not end access on the spot.** Stripe retries declines for days and
most recover. The status goes `past_due` and access runs **to the end of the period already
paid for** — that date is the line, enforced in `services.compute_status`, not the first
failed charge and not indefinitely.

**A returning subscriber resumes where they left off.** Someone who paid five months, lapsed
and came back is on Rhythm. Selling them Spark again would charge $19.99 while every screen
says $14.99 and re-sell months they already bought. `start_month_for` is what prevents it, in
both the Checkout price and the schedule.

**The app never decides whether a payment link may be shown.** `checkout_available` comes
from the server (`CHECKOUT_ALLOWED_COUNTRIES` + whether Stripe keys exist at all).

**Mock activation is off in production.** `SUBSCRIPTION_ALLOW_MOCK_ACTIVATE` defaults to
False. Left reachable, `POST /activate/` is a button that gives the paid product away.

---

## Setting it up

### 1. Keys

```
STRIPE_SECRET_KEY=sk_test_…        # sk_live_… in production
STRIPE_WEBHOOK_SECRET=whsec_…
```

With both blank, checkout answers 503, the app hides the button, and nothing else about the
backend changes. That is the intended state for a box that never takes payment.

### 2. Prices

```bash
uv run python manage.py sync_stripe_prices           # dry run — shows what it would make
uv run python manage.py sync_stripe_prices --create  # creates the product + four prices
```

It builds them from `config.PHASES` and prints the four `STRIPE_PRICE_*` lines for `.env`. Run
it once per Stripe environment; **test-mode and live-mode ids are different**, so swap all
four when you swap the secret key.

Run it again any time to verify: it re-reads each configured price and reports a **MISMATCH**
if what Stripe would charge is not what `config.PHASES` says. Stripe prices are immutable, so
changing a number in the config means new prices and new ids — existing subscribers keep the
price they signed up at, which is correct.

### 3. Webhook

Local:

```bash
stripe listen --forward-to localhost:8000/api/subscriptions/webhook/
```

It prints a `whsec_…` for `STRIPE_WEBHOOK_SECRET`. Production: Stripe Dashboard → Developers
→ Webhooks → `https://api.nowlii.com/api/subscriptions/webhook/`, subscribed to:

```
checkout.session.completed
invoice.paid
invoice.payment_failed
customer.subscription.updated
customer.subscription.deleted
```

### 4. Verifying the whole year in minutes

Stripe **Test Clocks** are how the ladder gets proved without waiting twelve months: create a
test clock, attach a customer to it, subscribe, then advance the clock a month at a time and
watch the invoices. The ladder is correct when the invoices read 19.99 ×3 → 14.99 ×3 → 9.99
×3 → 4.99 ×3 → subscription cancelled, and `/subscriptions/me/` then reports
`lifetime_free: true` with `has_access: true`.

This is a check the store path could not have given us before taking real money from a real
person.

---

## What is still needed before live

- **A Stripe account that can be activated.** Stripe does not operate in every country; the
  account's registered country decides whether this path is available at all.
- **Terms of Service.** Does not exist yet. Stripe wants it on the business profile and both
  stores require it for subscriptions. Tracked as P0 in `future-checklist.md`.
- **Refund policy**, matching what the code does (cancellation runs to the end of the paid
  period).
- **Branding** in the Stripe dashboard, so Checkout does not look like a different company.
- **A decision on US sales tax.** Digital subscriptions are taxable in roughly twenty US
  states. Stripe Tax handles it for 0.5% per transaction but needs registration past the
  thresholds. Fine to launch without and enable later — as a decision, not an oversight.
- **Google Play: enrolment in the External content links program**, before an Android build
  carrying the button ships. Fees and transaction reporting from 2026-10-01.
- **The upload keystore**, which is unrelated to payments but still blocks any Play build.

### Where linking out is allowed

US only, for now (`CHECKOUT_ALLOWED_COUNTRIES=US`). Apple has permitted it in the US since
2025-05 (0% commission, following the Epic injunction) and Google Play since 2025-12-09
(enrolment required; 9–20% service fee). The EU, South Korea and Japan have their own
regimes. **Everywhere else anti-steering still stands and the button must not appear.**

Note that Google still takes its fee even though Stripe processes the money — the commission
saving is real on iOS and not on Android. These rules have changed twice in the last two
years; re-read the current policy text before shipping, rather than trusting this paragraph.

---

## The store path is parked, not gone

`subscriptions-iap.md` documents the four-products-per-store design, and the machinery for it
is still in the codebase: `step_down_due`, `/confirm-switch/`, `step_down_pending_since`, the
admin "paying more than the plan" filter, and the `google_base_plan` / `apple_product` ids in
`config.PHASES`.

All of it is **dormant** — `step_down_due` returns `due: False` for anything that is not an
`apple` or `google` platform row, so Stripe subscribers never touch it. It is kept because
the one scenario that revives it is real: if the US link-out permission is withdrawn on
appeal, IAP becomes the only way to sell on iOS, and that mapping is already written down.

---

## Verified against the real test API — 2026-09-21

A real Checkout (card 4242) on a Test Clock customer, events pulled from the Events API and
replayed signed to the local webhook, the clock advanced month by month:

- Invoices: **19.99 ×3 → 14.99 ×3 → 9.99 ×3 → 4.99 ×3**, then the schedule `completed` and the
  subscription cancelled; the backend granted `lifetime_free`.
- Cancel → access kept to the paid period end, ladder released; resume → ladder re-attached.
- Declined card (`pm_card_chargeCustomerFail`) → six `payment_failed`, `past_due` with access to
  the **paid** date only, then Stripe cancels and the user lapses (not lifetime).
- Forged/missing signature → 400. Region gate: US 200, RS/DE 403. Portal URL 200.

Found only this way — the unit tests mock Stripe and passed throughout:

1. `iterations` is rejected by API `2026-08-26.dahlia` → phases use `duration`. Without it **no
   ladder ever attached**: everyone billed $19.99 forever.
2. A failed attach left a one-phase schedule that every retry refused → `attach_schedule` is
   idempotent (reuses/finishes an existing schedule; `nowlii_ladder` metadata marks a done one),
   and every `invoice.paid` re-checks it, so a broken ladder heals at the next renewal.
3. `.get()` on SDK objects raises since stripe-python 13 (gateway, sync command, webhook log).
4. The event record was committed before the handler → a failed handler's retry was dropped as
   a duplicate. Now one transaction.
5. `resume()` never re-attached the ladder `cancel` released.
6. `subscription.updated` rolls the period forward even on a declined renewal → a free month of
   "grace". Paid-through now comes from `invoice.paid` only.
7. A late `invoice.paid` for last month cleared this month's `past_due` → ACTIVE with no end.
8. **Pay one month, wait a year → free forever**: `is_free`/`sync_lifetime` counted calendar
   months regardless of status. Lifetime now = Stripe reports our ladder schedule `completed`
   (date rule kept only for non-lapsed legacy rows).
9. `started_at` was the processing day, not Stripe's → could shift the anniversary by a day.

**Resolved 2026-09-21 — the ladder counts months PAID, not months elapsed.** `PaidMonth` holds
one row per paid `subscription_create`/`subscription_cycle` invoice (unique invoice id, so
`invoice.paid` + `invoice.payment_succeeded`, replays and late deliveries count once). From it:
the price shown (`services.ladder_month`), the rung a returning subscriber is sold
(`start_month_for` = paid + 1, carried to the webhook as `nowlii_start_month` metadata),
the ladder re-attached on resume/renewal, and lifetime free (12 paid months, or Stripe's
completed ladder). Verified on the test account: 12 real invoices → 12 rows → lifetime; a
one-month customer who lapsed is sold month 2 at $19.99 on return.
