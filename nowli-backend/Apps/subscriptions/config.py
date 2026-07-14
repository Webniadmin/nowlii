"""
Config-driven subscription pricing — the SINGLE source of truth for the schedule.

NOWLII's plan is deliberately NOT a normal fixed-price subscription: the monthly price
steps DOWN over the first year, then the app becomes free forever for that user.

Billed monthly; prices are USD. Edit ``PHASES`` / ``FREE_AFTER_MONTH`` here to change the
schedule — no migration or code change elsewhere is required.
"""

CURRENCY = "USD"

# Each phase covers an inclusive range of 1-based billing months from the subscription
# start (month 1 = the first billing month). ``price`` = the monthly price during it.
PHASES = [
    {"from_month": 1,  "to_month": 3,  "price": 19.99},
    {"from_month": 4,  "to_month": 6,  "price": 14.99},
    {"from_month": 7,  "to_month": 9,  "price": 9.99},
    {"from_month": 10, "to_month": 12, "price": 4.99},
]

# After this many paid months the subscription becomes free ($0) forever (lifetime).
FREE_AFTER_MONTH = 12
