"""The Stripe path — the ladder, the grace rules, and the webhook.

None of these talk to Stripe. Everything that matters here is our own logic: what shape the
ladder is handed to Stripe in, who still has access and until when, and whether an event
applied twice does damage. The parts that genuinely need Stripe (that a schedule really bills
19.99 three times and then 14.99) are proved with a Test Clock instead — see
docs/stripe-payments.md.
"""

from datetime import date, datetime, timedelta, timezone as dt_timezone
from unittest import mock

from django.contrib.auth import get_user_model
from django.test import override_settings
from django.utils import timezone
from rest_framework.test import APITestCase

from . import config, services, stripe_gateway, webhooks
from .models import StripeEvent, Subscription

User = get_user_model()

# Fake ids, so the ladder can be built without a Stripe account. The real ones come from
# `manage.py sync_stripe_prices`.
FAKE_PRICES = {
    "STRIPE_PRICE_SPARK": "price_spark",
    "STRIPE_PRICE_RHYTHM": "price_rhythm",
    "STRIPE_PRICE_INDEPENDENCE": "price_independence",
    "STRIPE_PRICE_RELEASE": "price_release",
}


def _months_ago(n: int) -> date:
    """A date n whole months back, with the day clamped so the 31st does not overshoot."""
    today = timezone.localdate()
    month = today.month - n
    year = today.year
    while month <= 0:
        month += 12
        year -= 1
    day = min(today.day, 28)
    return date(year, month, day)


@override_settings(**FAKE_PRICES)
class LadderShapeTests(APITestCase):
    """What gets handed to Stripe as the price ladder."""

    def test_a_new_subscriber_gets_the_whole_ladder(self):
        phases = stripe_gateway.schedule_phases()
        self.assertEqual(len(phases), len(config.PHASES))
        self.assertEqual([p["duration"]["interval_count"] for p in phases], [3, 3, 3, 3])
        self.assertEqual(
            [p["items"][0]["price"] for p in phases],
            ["price_spark", "price_rhythm", "price_independence", "price_release"],
        )

    def test_twelve_billed_months_then_it_ends(self):
        """The whole point of end_behavior=cancel: the ladder is finite."""
        self.assertEqual(
            sum(p["duration"]["interval_count"] for p in stripe_gateway.schedule_phases()),
            config.FREE_AFTER_MONTH,
        )

    def test_a_returning_subscriber_resumes_where_they_left_off(self):
        """Month 5 is the middle of Rhythm — two of its three months are already paid for.

        Restarting them at Spark would charge $19.99 while every screen in the app says
        $14.99, and would re-sell months they already bought.
        """
        phases = stripe_gateway.schedule_phases(start_month=5)
        self.assertEqual(phases[0]["items"][0]["price"], "price_rhythm")
        self.assertEqual(phases[0]["duration"]["interval_count"], 2)
        self.assertEqual(len(phases), 3)          # Rhythm (part), Independence, Release
        self.assertEqual(sum(p["duration"]["interval_count"] for p in phases), 8)

    def test_the_last_rung_alone(self):
        phases = stripe_gateway.schedule_phases(start_month=12)
        self.assertEqual(len(phases), 1)
        self.assertEqual(phases[0]["items"][0]["price"], "price_release")
        self.assertEqual(phases[0]["duration"]["interval_count"], 1)

    def test_start_month_for(self):
        user = User.objects.create_user(username="ladder", email="l@x.com", password="p")
        sub = Subscription.objects.create(user=user)

        self.assertEqual(stripe_gateway.start_month_for(None), 1)
        self.assertEqual(stripe_gateway.start_month_for(sub), 1)   # never paid

        sub.started_at = _months_ago(4)
        self.assertEqual(stripe_gateway.start_month_for(sub), 5)

        # Past the paid year there is nothing left to sell, so it clamps rather than
        # walking off the end of the ladder.
        sub.started_at = _months_ago(20)
        self.assertEqual(stripe_gateway.start_month_for(sub), config.FREE_AFTER_MONTH)

    def test_rung_for_month_carries_the_price_id(self):
        """services.phase_for_month is a derived view for the API and has no price id;
        pricing a checkout must use the raw config entry."""
        self.assertNotIn("stripe_price_env", services.phase_for_month(1))
        self.assertEqual(
            stripe_gateway.price_id_for_phase(stripe_gateway.rung_for_month(7)),
            "price_independence",
        )


class PastDueGraceTests(APITestCase):
    """A failed charge does not end access on the spot — it ends it on the paid-through day."""

    def setUp(self):
        self.user = User.objects.create_user(username="dunning", email="d@x.com",
                                             password="p")
        self.sub = Subscription.objects.create(
            user=self.user,
            started_at=_months_ago(1),
            status=Subscription.Status.PAST_DUE,
            platform=Subscription.Platform.STRIPE,
        )

    def test_access_survives_while_the_paid_period_is_still_running(self):
        self.sub.current_period_end = timezone.localdate() + timedelta(days=9)
        self.assertTrue(services.compute_status(self.sub)["has_access"])

    def test_access_ends_the_day_after_the_paid_period(self):
        self.sub.current_period_end = timezone.localdate() - timedelta(days=1)
        self.assertFalse(services.compute_status(self.sub)["has_access"])

    def test_no_paid_through_date_means_no_grace(self):
        """Nothing on file to honour — inventing one would be giving the app away."""
        self.sub.current_period_end = None
        self.assertFalse(services.compute_status(self.sub)["has_access"])

    def test_a_past_due_subscriber_is_not_shown_a_trial_countdown(self):
        """They are a paying customer whose card is failing, not someone on a free trial."""
        self.sub.trial_started_at = timezone.localdate()
        self.sub.current_period_end = timezone.localdate() + timedelta(days=5)
        self.assertFalse(services.compute_status(self.sub)["in_trial"])


class WebhookTests(APITestCase):
    """Events are applied once, and mean what we think they mean."""

    def setUp(self):
        self.user = User.objects.create_user(username="hook", email="h@x.com", password="p")
        self.sub = Subscription.objects.create(user=self.user)

    def _event(self, type_, obj, id_="evt_1"):
        return {"id": id_, "type": type_, "data": {"object": obj}}

    def test_an_event_is_never_applied_twice(self):
        """Stripe retries until it gets a 2xx and can deliver the same event more than once.
        Every handler writes, so a replay is not harmless."""
        event = self._event("customer.subscription.updated", {
            "id": "sub_x", "customer": "cus_x", "cancel_at_period_end": True,
        })
        self.sub.stripe_subscription_id = "sub_x"
        self.sub.save()

        self.assertEqual(webhooks.dispatch(event), "applied")
        self.assertEqual(webhooks.dispatch(event), "duplicate")
        self.assertEqual(StripeEvent.objects.filter(event_id="evt_1").count(), 1)

    def test_a_real_stripe_event_object_is_handled(self):
        """The webhook receives a `stripe.Event`, not a dict.

        Every other test here builds a dict by hand, and that is exactly how this was missed:
        since stripe-python 15 a StripeObject is not a mapping, so `.get()` on one raises
        AttributeError. Hand-built dicts passed while every real delivery returned 500.
        """
        import stripe as stripe_sdk

        self.sub.stripe_subscription_id = "sub_obj"
        self.sub.save()
        event = stripe_sdk.Event.construct_from({
            "id": "evt_obj",
            "type": "customer.subscription.updated",
            "data": {"object": {
                "id": "sub_obj",
                "customer": "cus_obj",
                "cancel_at_period_end": True,
            }},
        }, "sk_test_x")

        self.assertEqual(webhooks.dispatch(event), "applied")
        self.sub.refresh_from_db()
        self.assertTrue(self.sub.cancel_at_period_end)

    def test_an_unhandled_event_is_acknowledged_not_retried(self):
        result = webhooks.dispatch(self._event("payment_intent.created", {}, "evt_2"))
        self.assertEqual(result, "ignored")

    def test_checkout_makes_a_trial_user_a_paying_subscriber(self):
        self.sub.trial_started_at = timezone.localdate()
        self.sub.status = Subscription.Status.TRIAL
        self.sub.save()

        with mock.patch.object(stripe_gateway, "attach_schedule",
                               return_value="sched_1") as attach:
            webhooks.dispatch(self._event("checkout.session.completed", {
                "id": "cs_1",
                "client_reference_id": str(self.user.pk),
                "customer": "cus_1",
                "subscription": "sub_1",
            }, "evt_3"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.status, Subscription.Status.ACTIVE)
        self.assertEqual(self.sub.platform, Subscription.Platform.STRIPE)
        self.assertEqual(self.sub.stripe_customer_id, "cus_1")
        self.assertEqual(self.sub.stripe_schedule_id, "sched_1")
        # The paid year starts the day they pay, not the day the trial began.
        self.assertEqual(self.sub.started_at, timezone.localdate())
        attach.assert_called_once_with("sub_1", 1)

    def test_checkout_does_not_reset_a_returning_subscribers_ladder(self):
        """They earned their way down to Rhythm; month 1 would re-sell what they bought."""
        self.sub.started_at = _months_ago(4)
        self.sub.status = Subscription.Status.EXPIRED
        self.sub.save()
        original_start = self.sub.started_at

        with mock.patch.object(stripe_gateway, "attach_schedule",
                               return_value="sched_2") as attach:
            webhooks.dispatch(self._event("checkout.session.completed", {
                "id": "cs_2",
                "client_reference_id": str(self.user.pk),
                "customer": "cus_2",
                "subscription": "sub_2",
            }, "evt_4"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.started_at, original_start)
        attach.assert_called_once_with("sub_2", 5)

    def test_a_purchase_survives_a_failure_to_attach_the_ladder(self):
        """They have been charged. Losing the automatic step down is recoverable by hand;
        refusing the event would make Stripe retry something already paid for."""
        with mock.patch.object(stripe_gateway, "attach_schedule",
                               side_effect=RuntimeError("stripe is down")):
            webhooks.dispatch(self._event("checkout.session.completed", {
                "id": "cs_3",
                "client_reference_id": str(self.user.pk),
                "customer": "cus_3",
                "subscription": "sub_3",
            }, "evt_5"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.status, Subscription.Status.ACTIVE)
        self.assertEqual(self.sub.stripe_schedule_id, "")

    def test_finishing_the_year_grants_lifetime_free(self):
        """The schedule ends with end_behavior=cancel, so completing the ladder arrives as
        the same event as giving up. Stripe's completed schedule is what tells them apart —
        deliberately on the anniversary day minus one, where the month index still says 12."""
        self.sub.started_at = _months_ago(12) + timedelta(days=1)
        self.sub.stripe_subscription_id = "sub_done"
        self.sub.status = Subscription.Status.ACTIVE
        self.sub.save()

        with mock.patch.object(stripe_gateway, "ladder_completed", return_value=True) as done:
            webhooks.dispatch(self._event("customer.subscription.deleted", {
                "id": "sub_done", "customer": "cus_done", "schedule": "sub_sched_done",
            }, "evt_6"))

        done.assert_called_once_with("sub_sched_done")
        self.sub.refresh_from_db()
        self.assertTrue(self.sub.lifetime_free)
        self.assertEqual(self.sub.status, Subscription.Status.LIFETIME_FREE)
        self.assertTrue(services.compute_status(self.sub)["has_access"])

    def test_a_cancel_after_a_year_of_calendar_time_is_not_a_finished_ladder(self):
        """A released (cancelled) schedule is not a completed one, however old the start."""
        self.sub.started_at = _months_ago(13)
        self.sub.stripe_subscription_id = "sub_quit"
        self.sub.status = Subscription.Status.ACTIVE
        self.sub.save()

        with mock.patch.object(stripe_gateway, "ladder_completed", return_value=False):
            webhooks.dispatch(self._event("customer.subscription.deleted", {
                "id": "sub_quit", "customer": "cus_quit", "schedule": "sub_sched_quit",
            }, "evt_6b"))

        self.sub.refresh_from_db()
        self.assertFalse(self.sub.lifetime_free)
        self.assertEqual(self.sub.status, Subscription.Status.CANCELLED)

    def test_paying_once_and_waiting_a_year_is_not_free_forever(self):
        """Calendar time is not months paid. Before the fix, one $19.99 month and a year's
        wait read as a finished ladder in both compute_status and sync_lifetime."""
        self.sub.started_at = _months_ago(13)
        self.sub.status = Subscription.Status.CANCELLED
        self.sub.current_period_end = self.sub.started_at + timedelta(days=30)
        self.sub.save()

        self.assertFalse(services.compute_status(self.sub)["has_access"])
        services.sync_lifetime(self.sub)
        self.sub.refresh_from_db()
        self.assertFalse(self.sub.lifetime_free)

    def test_a_declined_renewal_does_not_extend_the_paid_through_date(self):
        """Stripe rolls the period forward at renewal even when the charge fails. Reading that
        as paid-through gave a declined card a free month — seen against the real test API."""
        paid_to = timezone.localdate() + timedelta(days=2)
        self.sub.stripe_subscription_id = "sub_decl"
        self.sub.status = Subscription.Status.ACTIVE
        self.sub.current_period_end = paid_to
        self.sub.save()
        rolled = int(datetime(paid_to.year, paid_to.month, paid_to.day,
                              tzinfo=dt_timezone.utc).timestamp()) + 30 * 86400

        webhooks.dispatch(self._event("customer.subscription.updated", {
            "id": "sub_decl", "customer": "cus_decl", "status": "past_due",
            "items": {"data": [{"current_period_end": rolled}]},
        }, "evt_decl"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.status, Subscription.Status.PAST_DUE)
        self.assertEqual(self.sub.current_period_end, paid_to)

    def test_a_failed_handler_leaves_the_event_retryable(self):
        """The record and the handler commit together, so Stripe's retry is processed rather
        than dropped as a replay of an event that never took effect."""
        self.sub.stripe_subscription_id = "sub_retry"
        self.sub.save()
        event = self._event("customer.subscription.updated", {
            "id": "sub_retry", "customer": "cus_retry", "cancel_at_period_end": True,
        }, "evt_retry")

        with mock.patch.object(webhooks, "_period_end", side_effect=RuntimeError("blip")):
            with self.assertRaises(RuntimeError):
                webhooks.dispatch(event)
        self.assertFalse(StripeEvent.objects.filter(event_id="evt_retry").exists())

        self.assertEqual(webhooks.dispatch(event), "applied")
        self.sub.refresh_from_db()
        self.assertTrue(self.sub.cancel_at_period_end)

    def test_the_paid_year_starts_on_stripes_date_not_the_processing_date(self):
        """A delivery processed after midnight UTC must not shift the anniversary."""
        paid_on = timezone.localdate() - timedelta(days=1)
        created = int(datetime(paid_on.year, paid_on.month, paid_on.day, 23, 59,
                               tzinfo=dt_timezone.utc).timestamp())
        with mock.patch.object(stripe_gateway, "attach_schedule", return_value="sub_sched_y"):
            webhooks.dispatch(self._event("checkout.session.completed", {
                "client_reference_id": str(self.user.pk), "customer": "cus_y",
                "subscription": "sub_y", "created": created,
            }, "evt_y"))
        self.sub.refresh_from_db()
        self.assertEqual(self.sub.started_at, paid_on)

    def test_stopping_early_lapses_instead(self):
        self.sub.started_at = _months_ago(2)
        self.sub.stripe_subscription_id = "sub_gone"
        self.sub.status = Subscription.Status.ACTIVE
        self.sub.save()

        webhooks.dispatch(self._event("customer.subscription.deleted", {
            "id": "sub_gone", "customer": "cus_gone",
        }, "evt_7"))

        self.sub.refresh_from_db()
        self.assertFalse(self.sub.lifetime_free)
        self.assertEqual(self.sub.status, Subscription.Status.CANCELLED)

    def test_a_paid_renewal_lifts_past_due(self):
        self.sub.stripe_subscription_id = "sub_ok"
        self.sub.status = Subscription.Status.PAST_DUE
        self.sub.save()

        webhooks.dispatch(self._event("invoice.paid", {
            "customer": "cus_ok",
            "subscription": "sub_ok",
            "lines": {"data": [{"period": {"end": 1800000000}}]},
        }, "evt_8"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.status, Subscription.Status.ACTIVE)
        self.assertIsNotNone(self.sub.current_period_end)

    def test_a_late_invoice_for_last_month_does_not_forgive_this_months_decline(self):
        """Stripe does not order events. Replaying last month's invoice.paid after this
        month's payment_failed flipped past_due to ACTIVE — access with no end date."""
        paid_to = timezone.localdate() + timedelta(days=3)
        self.sub.stripe_subscription_id = "sub_late"
        self.sub.status = Subscription.Status.PAST_DUE
        self.sub.current_period_end = paid_to
        self.sub.save()
        old_end = int(datetime(paid_to.year, paid_to.month, paid_to.day,
                               tzinfo=dt_timezone.utc).timestamp())

        webhooks.dispatch(self._event("invoice.paid", {
            "customer": "cus_late", "subscription": "sub_late",
            "lines": {"data": [{"period": {"end": old_end}}]},
        }, "evt_late"))

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.status, Subscription.Status.PAST_DUE)
        self.assertEqual(self.sub.current_period_end, paid_to)

    def test_an_event_for_a_stranger_is_ignored_quietly(self):
        """A shared Stripe account will carry events about customers we have never seen."""
        result = webhooks.dispatch(self._event("customer.subscription.updated", {
            "id": "sub_elsewhere", "customer": "cus_elsewhere",
        }, "evt_9"))
        self.assertEqual(result, "applied")     # handled, changed nothing


class CheckoutEndpointTests(APITestCase):
    """Who is allowed to be shown a payment link, and what happens when they are not."""

    def setUp(self):
        self.user = User.objects.create_user(username="buyer", email="b@x.com",
                                             password="p")
        self.client.force_authenticate(self.user)

    @override_settings(CHECKOUT_ALLOWED_COUNTRIES=["US"])
    def test_a_forbidden_storefront_is_refused(self):
        """Anti-steering still stands almost everywhere; the button must not work there."""
        res = self.client.post("/api/subscriptions/checkout/", HTTP_X_NOWLII_REGION="RS")
        self.assertEqual(res.status_code, 403)

    @override_settings(CHECKOUT_ALLOWED_COUNTRIES=["US"], STRIPE_SECRET_KEY="")
    def test_the_us_gets_past_the_region_gate(self):
        """503 (no keys on this server), not 403 — the region was fine."""
        res = self.client.post("/api/subscriptions/checkout/", HTTP_X_NOWLII_REGION="US")
        self.assertEqual(res.status_code, 503)

    @override_settings(CHECKOUT_ALLOWED_COUNTRIES=["US"], STRIPE_SECRET_KEY="")
    def test_status_says_checkout_is_unavailable_without_keys(self):
        """The app reads one flag, so it never offers a button that cannot work."""
        res = self.client.get("/api/subscriptions/me/", HTTP_X_NOWLII_REGION="US")
        self.assertEqual(res.status_code, 200)
        self.assertFalse(res.data["checkout_available"])

    @override_settings(CHECKOUT_ALLOWED_COUNTRIES=["US"], STRIPE_SECRET_KEY="sk_test_x")
    def test_status_hides_checkout_outside_the_allowed_storefronts(self):
        res = self.client.get("/api/subscriptions/me/", HTTP_X_NOWLII_REGION="DE")
        self.assertFalse(res.data["checkout_available"])

    @override_settings(SUBSCRIPTION_ALLOW_MOCK_ACTIVATE=False)
    def test_mock_activation_is_refused_in_production(self):
        """It grants the paid product for free. Reachable, it is a giveaway button."""
        res = self.client.post("/api/subscriptions/activate/")
        self.assertEqual(res.status_code, 403)

    def test_a_lifetime_free_user_is_not_sold_anything(self):
        Subscription.objects.create(
            user=self.user,
            started_at=_months_ago(14),
            lifetime_free=True,
            status=Subscription.Status.LIFETIME_FREE,
        )
        res = self.client.post("/api/subscriptions/checkout/", HTTP_X_NOWLII_REGION="US")
        self.assertEqual(res.status_code, 409)


@override_settings(STRIPE_SECRET_KEY="sk_test_x", **FAKE_PRICES)
class AttachScheduleTests(APITestCase):
    """attach_schedule must be safe to call again — found against the real test API, where a
    failed second call left a one-phase schedule that every retry then refused to replace."""

    def _stripe(self, sub_schedule=None, schedule=None):
        fake = mock.MagicMock()
        fake.Subscription.retrieve.return_value = {"schedule": sub_schedule}
        fake.SubscriptionSchedule.retrieve.return_value = mock.MagicMock(
            id=sub_schedule, **{"__str__.return_value": __import__("json").dumps(schedule or {})})
        created = mock.MagicMock(id="sub_sched_new",
                                 **{"__str__.return_value": '{"phases": [{"start_date": 100}]}'})
        fake.SubscriptionSchedule.create.return_value = created
        fake.SubscriptionSchedule.modify.return_value = mock.MagicMock(id="sub_sched_new")
        return fake

    def test_a_fresh_subscription_gets_a_new_ladder(self):
        fake = self._stripe()
        with mock.patch.object(stripe_gateway, "_client", return_value=fake):
            stripe_gateway.attach_schedule("sub_1")
        fake.SubscriptionSchedule.create.assert_called_once_with(from_subscription="sub_1")
        kwargs = fake.SubscriptionSchedule.modify.call_args.kwargs
        self.assertEqual(kwargs["end_behavior"], "cancel")
        self.assertEqual(kwargs["metadata"], {stripe_gateway.LADDER_MARKER: "1"})
        self.assertEqual(len(kwargs["phases"]), 4)
        self.assertEqual(kwargs["phases"][0]["start_date"], 100)

    def test_a_half_built_schedule_is_finished_not_recreated(self):
        fake = self._stripe("sub_sched_half", {"end_behavior": "release", "metadata": {},
                                               "phases": [{"start_date": 200}]})
        with mock.patch.object(stripe_gateway, "_client", return_value=fake):
            self.assertEqual(stripe_gateway.attach_schedule("sub_1"), "sub_sched_new")
        fake.SubscriptionSchedule.create.assert_not_called()
        self.assertEqual(fake.SubscriptionSchedule.modify.call_args.args[0], "sub_sched_half")

    def test_a_finished_ladder_is_left_alone(self):
        fake = self._stripe("sub_sched_done", {"end_behavior": "cancel",
                                               "metadata": {stripe_gateway.LADDER_MARKER: "1"}})
        with mock.patch.object(stripe_gateway, "_client", return_value=fake):
            self.assertEqual(stripe_gateway.attach_schedule("sub_1"), "sub_sched_done")
        fake.SubscriptionSchedule.create.assert_not_called()
        fake.SubscriptionSchedule.modify.assert_not_called()
