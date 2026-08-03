"""
Config-driven subscription pricing — the SINGLE source of truth for the schedule.

NOWLII's plan is deliberately NOT a normal fixed-price subscription: the monthly price
steps DOWN over the first year, then the app becomes free forever for that user.

Billed monthly; prices are USD. Edit ``PHASES`` / ``FREE_AFTER_MONTH`` here to change the
schedule — no migration or code change elsewhere is required.
"""

CURRENCY = "USD"

# Free trial granted automatically the first time a logged-in user reaches the API (i.e. on
# install + first login). Full access, no card. When it runs out the user must subscribe to
# keep using the app. Set to 0 to disable trials entirely.
TRIAL_DAYS = 7

# Each phase covers an inclusive range of 1-based billing months from the subscription
# start (month 1 = the first billing month). ``price`` = the monthly price during it.
#
# ``google_base_plan`` / ``apple_product`` tie a phase to the product the store actually
# bills. Neither store can express this ladder in one product: a Google Play offer allows
# **at most two pricing phases**, and an Apple introductory offer is a single phase. So each
# step is its own store product and the subscriber is moved down the ladder by a plan change
# at renewal. See ``services.step_down_due`` and docs/subscriptions-iap.md.
# The five named stages of the plan: Spark → Rhythm → Independence → Release → Graduated.
# The first four are what the user pays; the fifth is free and is not a store product.
PHASES = [
    {"from_month": 1,  "to_month": 3,  "price": 19.99, "stage": "Spark",
     "google_base_plan": "spark", "apple_product": "com.nowlii.pro.spark"},
    {"from_month": 4,  "to_month": 6,  "price": 14.99, "stage": "Rhythm",
     "google_base_plan": "rhythm", "apple_product": "com.nowlii.pro.rhythm"},
    {"from_month": 7,  "to_month": 9,  "price": 9.99, "stage": "Independence",
     "google_base_plan": "independence", "apple_product": "com.nowlii.pro.independence"},
    {"from_month": 10, "to_month": 12, "price": 4.99, "stage": "Release",
     "google_base_plan": "release", "apple_product": "com.nowlii.pro.release"},
]

# The final, free-forever stage. Deliberately not a store product: neither store sells a $0
# renewing plan, so reaching it means the subscription is cancelled and access comes from
# our own records.
GRADUATED_STAGE = "Graduated"

# The Play subscription every base plan above belongs to. Play models one product with many
# base plans; Apple models a subscription *group* with one product per price.
GOOGLE_SUBSCRIPTION_ID = "nowlii_pro"

# After this many paid months the subscription becomes free ($0) forever (lifetime).
#
# Neither store sells a $0 auto-renewing plan, and neither offers a server-side API to move
# a subscriber to another plan. So "free forever" is not a store product at all: at month
# ``FREE_AFTER_MONTH + 1`` the backend stops expecting payment and grants access from its own
# records, and the app cancels the store subscription so nothing renews.
FREE_AFTER_MONTH = 12
