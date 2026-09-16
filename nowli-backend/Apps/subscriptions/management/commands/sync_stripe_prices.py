"""Create the four Stripe prices from ``config.PHASES`` and print the ids for ``.env``.

The price ladder is written down once, in ``Apps/subscriptions/config.py``. This command is
what stops that from becoming two copies: instead of typing $19.99 into the Stripe dashboard
and hoping it still matches the number the app quotes, the prices are created *from* the
config, and anything already in Stripe that disagrees is reported rather than silently left.

Run it once per Stripe environment — once with a test key, once with the live key. Prices in
Stripe are immutable, so changing a number in ``config.PHASES`` later means new prices and a
new pair of ids in ``.env``; existing subscribers keep the price they signed up at, which is
how it should be.

    uv run python manage.py sync_stripe_prices           # show what would happen
    uv run python manage.py sync_stripe_prices --create  # actually create them
"""

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from Apps.subscriptions import config, stripe_gateway


class Command(BaseCommand):
    help = "Create/verify the Stripe prices for the subscription ladder."

    def add_arguments(self, parser):
        parser.add_argument(
            "--create", action="store_true",
            help="Actually create the product and any missing prices (default: dry run).",
        )

    def handle(self, *args, **options):
        if not stripe_gateway.is_configured():
            raise CommandError("STRIPE_SECRET_KEY is not set — nothing to talk to.")

        import stripe
        stripe.api_key = settings.STRIPE_SECRET_KEY
        create = options["create"]

        mode = "LIVE" if not settings.STRIPE_SECRET_KEY.startswith("sk_test") else "TEST"
        self.stdout.write(self.style.WARNING(f"Stripe mode: {mode}"))
        if not create:
            self.stdout.write("Dry run — pass --create to make anything.\n")

        product = self._product(stripe, create)
        if product is None:
            self.stdout.write("Would create product "
                              f"{stripe_gateway.PRODUCT_NAME!r} and four prices.")
            return

        self.stdout.write(f"Product: {product.id} ({product.name})\n")

        lines = []
        for phase in config.PHASES:
            env_name = phase["stripe_price_env"]
            existing = getattr(settings, env_name, "")
            cents = int(round(float(phase["price"]) * 100))
            label = f'{phase["stage"]} ${phase["price"]:.2f}/mo'

            if existing:
                ok = self._verify(stripe, existing, cents, product.id)
                mark = self.style.SUCCESS("OK") if ok else self.style.ERROR("MISMATCH")
                self.stdout.write(f"  {label:<34} {existing}  [{mark}]")
                if not ok:
                    self.stdout.write(self.style.ERROR(
                        f"    {env_name} points at a price that is not "
                        f"${phase['price']:.2f}/month on this product. "
                        "The app would quote one number and Stripe would charge another."
                    ))
                continue

            if not create:
                self.stdout.write(f"  {label:<34} would create → {env_name}")
                continue

            price = stripe.Price.create(
                product=product.id,
                unit_amount=cents,
                currency=config.CURRENCY.lower(),
                recurring={"interval": "month"},
                nickname=f'NOWLII {phase["stage"]}',
                metadata={"stage": phase["stage"],
                          "from_month": str(phase["from_month"]),
                          "to_month": str(phase["to_month"])},
            )
            self.stdout.write(f"  {label:<34} {self.style.SUCCESS('created')} {price.id}")
            lines.append(f"{env_name}={price.id}")

        if lines:
            self.stdout.write("\nPut these in .env:\n")
            for line in lines:
                self.stdout.write(f"  {line}")

        missing = stripe_gateway.missing_price_settings()
        if missing and not lines:
            self.stdout.write(self.style.WARNING(
                "\nStill unset: " + ", ".join(missing)
            ))

    def _product(self, stripe, create):
        """The NOWLII Pro product, found by lookup key or created."""
        found = stripe.Product.search(
            query=f'metadata["lookup_key"]:"{stripe_gateway.PRODUCT_LOOKUP_KEY}"'
        )
        if found.data:
            return found.data[0]
        if not create:
            return None
        return stripe.Product.create(
            name=stripe_gateway.PRODUCT_NAME,
            description="Full access to NOWLII — quests, insights and voice calls with "
                        "your companion.",
            metadata={"lookup_key": stripe_gateway.PRODUCT_LOOKUP_KEY},
        )

    def _verify(self, stripe, price_id, cents, product_id) -> bool:
        """Does the configured price id really charge what config.PHASES says it does?"""
        try:
            price = stripe.Price.retrieve(price_id)
        except Exception:
            return False
        return (
            price.unit_amount == cents
            and price.currency == config.CURRENCY.lower()
            and (price.recurring or {}).get("interval") == "month"
            and price.product == product_id
        )
