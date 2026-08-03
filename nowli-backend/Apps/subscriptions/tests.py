from datetime import date, timedelta

from django.contrib.auth import get_user_model
from django.test import override_settings
from rest_framework.test import APITestCase

from . import config, services
from .models import Subscription

User = get_user_model()


class PhaseLogicTests(APITestCase):
    def test_month_index(self):
        start = date(2026, 1, 15)
        self.assertEqual(services.current_month_index(start, date(2026, 1, 15)), 1)
        self.assertEqual(services.current_month_index(start, date(2026, 2, 14)), 1)  # not a full month yet
        self.assertEqual(services.current_month_index(start, date(2026, 2, 15)), 2)
        self.assertEqual(services.current_month_index(start, date(2027, 1, 15)), 13)

    def test_phase_prices(self):
        self.assertEqual(services.phase_for_month(1)["price"], 19.99)
        self.assertEqual(services.phase_for_month(3)["price"], 19.99)
        self.assertEqual(services.phase_for_month(4)["price"], 14.99)
        self.assertEqual(services.phase_for_month(6)["price"], 14.99)
        self.assertEqual(services.phase_for_month(7)["price"], 9.99)
        self.assertEqual(services.phase_for_month(10)["price"], 4.99)
        self.assertEqual(services.phase_for_month(12)["price"], 4.99)
        p13 = services.phase_for_month(13)
        self.assertTrue(p13["is_free"])
        self.assertEqual(p13["price"], 0.0)


class LifetimeTests(APITestCase):
    def test_lifetime_after_year(self):
        u = User.objects.create_user(username="life", password="x")
        sub = Subscription.objects.create(user=u, started_at=date.today() - timedelta(days=400))
        services.sync_lifetime(sub)
        sub.refresh_from_db()
        self.assertTrue(sub.lifetime_free)
        self.assertEqual(sub.status, Subscription.Status.LIFETIME_FREE)
        self.assertTrue(services.user_has_pro(u))

    def test_brand_new_user_gets_the_trial_and_is_pro(self):
        """Changed by the trial feature: a first-contact user used to have no access."""
        u = User.objects.create_user(username="free", password="x")
        self.assertTrue(services.user_has_pro(u))
        sub = Subscription.objects.get(user=u)
        self.assertEqual(sub.status, Subscription.Status.TRIAL)
        self.assertEqual(sub.trial_started_at, date.today())
        self.assertIsNone(sub.started_at)      # paid schedule hasn't begun

    def test_expired_trial_is_not_pro(self):
        u = User.objects.create_user(username="lapsed", password="x")
        Subscription.objects.create(
            user=u, started_at=None,
            trial_started_at=date.today() - timedelta(days=config.TRIAL_DAYS + 1),
            status=Subscription.Status.TRIAL,
        )
        self.assertFalse(services.user_has_pro(u))


class TrialTests(APITestCase):
    def _sub(self, user, days_ago):
        return Subscription.objects.create(
            user=user, started_at=None,
            trial_started_at=date.today() - timedelta(days=days_ago),
            status=Subscription.Status.TRIAL,
        )

    def test_trial_covers_exactly_TRIAL_DAYS(self):
        u = User.objects.create_user(username="t1", password="x")
        sub = self._sub(u, 0)
        st = services.trial_status(sub)
        self.assertTrue(st["in_trial"])
        self.assertEqual(st["trial_days_left"], config.TRIAL_DAYS)

        # Last day of the trial: still in, 1 day left.
        sub.trial_started_at = date.today() - timedelta(days=config.TRIAL_DAYS - 1)
        st = services.trial_status(sub)
        self.assertTrue(st["in_trial"])
        self.assertEqual(st["trial_days_left"], 1)

        # The day after it ends: out, 0 left (never negative).
        sub.trial_started_at = date.today() - timedelta(days=config.TRIAL_DAYS)
        st = services.trial_status(sub)
        self.assertFalse(st["in_trial"])
        self.assertEqual(st["trial_days_left"], 0)

    def test_trial_is_granted_once_and_never_extended(self):
        u = User.objects.create_user(username="t2", password="x")
        first = services.start_trial(u)
        started = first.trial_started_at

        # Simulate an old trial, then call again — it must NOT reset the clock.
        first.trial_started_at = date.today() - timedelta(days=30)
        first.save()
        again = services.start_trial(u)
        self.assertEqual(again.pk, first.pk)
        self.assertNotEqual(again.trial_started_at, started)
        self.assertEqual(again.trial_started_at, date.today() - timedelta(days=30))
        self.assertEqual(Subscription.objects.filter(user=u).count(), 1)

    def test_expiry_is_persisted_once(self):
        u = User.objects.create_user(username="t3", password="x")
        sub = self._sub(u, config.TRIAL_DAYS + 3)
        services.sync_trial_expiry(sub)
        sub.refresh_from_db()
        self.assertEqual(sub.status, Subscription.Status.EXPIRED)

    def test_expiry_does_not_knock_back_someone_who_subscribed(self):
        u = User.objects.create_user(username="t4", password="x")
        sub = self._sub(u, config.TRIAL_DAYS + 3)
        sub.status = Subscription.Status.ACTIVE
        sub.started_at = date.today()
        sub.save()
        services.sync_trial_expiry(sub)
        sub.refresh_from_db()
        self.assertEqual(sub.status, Subscription.Status.ACTIVE)
        self.assertTrue(services.user_has_pro(u))


class EndpointTests(APITestCase):
    def setUp(self):
        self.u = User.objects.create_user(username="ep", password="x")
        self.client.force_authenticate(self.u)

    def _age_trial(self, days):
        """Backdate the trial start. Mutates the instance the view will read.

        A queryset `.update()` would NOT work here: `force_authenticate` reuses one user
        object across requests, and Django caches the reverse one-to-one on it, so the view
        would keep seeing the pre-update row.
        """
        sub = self.u.subscription
        sub.trial_started_at = date.today() - timedelta(days=days)
        sub.save(update_fields=["trial_started_at", "updated_at"])

    def test_plan(self):
        r = self.client.get("/api/subscriptions/plan/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["currency"], "USD")
        self.assertEqual(len(r.data["phases"]), 4)
        self.assertEqual(r.data["free_after_month"], 12)

    def test_activate_and_status_flow(self):
        # Changed by the trial feature: /me/ now GRANTS the trial on first call, so a fresh
        # user already has access instead of being locked out.
        r = self.client.get("/api/subscriptions/me/")
        self.assertTrue(r.data["has_access"])
        self.assertTrue(r.data["in_trial"])
        self.assertEqual(r.data["trial_days_left"], config.TRIAL_DAYS)
        self.assertEqual(r.data["status"], Subscription.Status.TRIAL)
        self.assertEqual(r.data["month_index"], 0)          # paid schedule not started
        self.assertEqual(r.data["current_price"], 19.99)    # what they'd pay if they bought now

        r = self.client.post("/api/subscriptions/activate/")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["subscribed"])
        self.assertFalse(r.data["in_trial"])                # paying now, not trialling
        self.assertEqual(r.data["month_index"], 1)
        self.assertEqual(r.data["current_price"], 19.99)
        self.assertEqual(r.data["next_price"], 19.99)
        self.assertTrue(r.data["has_access"])

    def test_me_starts_the_clock_only_once(self):
        first = self.client.get("/api/subscriptions/me/")
        self.assertEqual(first.data["trial_days_left"], config.TRIAL_DAYS)
        self._age_trial(3)
        second = self.client.get("/api/subscriptions/me/")
        self.assertEqual(second.data["trial_days_left"], config.TRIAL_DAYS - 3)
        self.assertEqual(Subscription.objects.filter(user=self.u).count(), 1)

    def test_start_trial_endpoint_is_idempotent(self):
        r = self.client.post("/api/subscriptions/start-trial/")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["in_trial"])
        self.assertEqual(r.data["trial_days_total"], config.TRIAL_DAYS)

        self._age_trial(5)
        again = self.client.post("/api/subscriptions/start-trial/")
        self.assertEqual(again.data["trial_days_left"], config.TRIAL_DAYS - 5)  # not reset

    def test_activating_from_a_trial_starts_the_paid_year_today(self):
        self.client.get("/api/subscriptions/me/")          # grant trial
        self._age_trial(6)
        r = self.client.post("/api/subscriptions/activate/")
        sub = Subscription.objects.get(user=self.u)
        self.assertEqual(sub.started_at, date.today())      # NOT the trial start date
        self.assertEqual(sub.status, Subscription.Status.ACTIVE)
        self.assertEqual(r.data["month_index"], 1)

    def test_activate_does_not_downgrade_a_lifetime_free_user(self):
        Subscription.objects.create(
            user=self.u, started_at=date.today() - timedelta(days=400),
            status=Subscription.Status.LIFETIME_FREE, lifetime_free=True,
        )
        r = self.client.post("/api/subscriptions/activate/")
        self.assertEqual(r.data["status"], Subscription.Status.LIFETIME_FREE)
        self.assertTrue(r.data["lifetime_free"])

    def test_cancel_flow(self):
        self.client.post("/api/subscriptions/activate/")
        r = self.client.post("/api/subscriptions/cancel/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["status"], Subscription.Status.CANCELLED)

    def test_verify_receipt_stub(self):
        r = self.client.post("/api/subscriptions/verify-receipt/")
        self.assertEqual(r.status_code, 501)


@override_settings(SUBSCRIPTION_ENFORCED=True, SUBSCRIPTION_UNLIMITED_USERS=[])
class AccessGateTests(APITestCase):
    """The paywall itself: trial → full app, expired trial → 402, purchase → back in."""

    # One protected endpoint per gated app.
    GATED = ["/api/quests/", "/api/insights/", "/api/voice-calls/quota/", "/api/subtasks/"]

    def setUp(self):
        self.u = User.objects.create_user(username="gate", password="x")
        self.client.force_authenticate(self.u)

    def _next_request(self):
        """Re-authenticate with a freshly-loaded user.

        `force_authenticate` reuses ONE user object for every request, so Django's cached
        reverse one-to-one (`user.subscription`) survives across calls — something that never
        happens in production, where auth middleware builds a new user per request. Call this
        between a write and the read that must observe it.
        """
        self.u = User.objects.get(pk=self.u.pk)
        self.client.force_authenticate(self.u)

    def _expire_trial(self):
        """Age the trial past its end. Mutates the cached instance the view will read —
        a queryset `.update()` is invisible to the reused, force-authenticated user."""
        sub = self.u.subscription
        sub.trial_started_at = date.today() - timedelta(days=config.TRIAL_DAYS + 1)
        sub.status = Subscription.Status.TRIAL
        sub.save(update_fields=["trial_started_at", "status", "updated_at"])

    def test_new_user_can_use_the_app_during_the_trial(self):
        for url in self.GATED:
            with self.subTest(url=url):
                self.assertNotEqual(self.client.get(url).status_code, 402)

    def test_expired_trial_blocks_every_gated_endpoint_with_402(self):
        self.client.get("/api/subscriptions/me/")   # grant the trial, then age it out
        self._expire_trial()
        for url in self.GATED:
            with self.subTest(url=url):
                r = self.client.get(url)
                self.assertEqual(r.status_code, 402)
                self.assertEqual(r.data["detail"].code, "subscription_required")

    def test_blocked_user_can_still_reach_login_profile_subscribe_and_support(self):
        """A paywalled user must not be locked out of the screens that let them pay."""
        self.client.get("/api/subscriptions/me/")
        self._expire_trial()
        for url in ["/api/subscriptions/me/", "/api/subscriptions/plan/",
                    "/api/profiles/", "/api/support/messages/"]:
            with self.subTest(url=url):
                self.assertNotEqual(self.client.get(url).status_code, 402)

    def test_subscribing_restores_access(self):
        self.client.get("/api/subscriptions/me/")
        self._expire_trial()
        self.assertEqual(self.client.get("/api/quests/").status_code, 402)

        self.client.post("/api/subscriptions/activate/")
        self._next_request()
        self.assertNotEqual(self.client.get("/api/quests/").status_code, 402)

    def test_unauthenticated_gets_401_not_402(self):
        """Not-logged-in must read as 'log in', never as 'pay us'."""
        self.client.force_authenticate(None)
        self.assertEqual(self.client.get("/api/quests/").status_code, 401)

    @override_settings(SUBSCRIPTION_ENFORCED=False)
    def test_kill_switch_opens_the_app(self):
        self.client.get("/api/subscriptions/me/")
        self._expire_trial()
        self.assertNotEqual(self.client.get("/api/quests/").status_code, 402)

    @override_settings(SUBSCRIPTION_UNLIMITED_USERS=["gate"])
    def test_allowlisted_test_account_bypasses_the_gate(self):
        self.client.get("/api/subscriptions/me/")
        self._expire_trial()
        self.assertNotEqual(self.client.get("/api/quests/").status_code, 402)

    def test_staff_bypasses_the_gate(self):
        self.u.is_staff = True
        self.u.save()
        self.client.get("/api/subscriptions/me/")
        self._expire_trial()
        self.assertNotEqual(self.client.get("/api/quests/").status_code, 402)


class StepDownTests(APITestCase):
    """The price ladder is four separate store products and neither store lets a server
    move a subscriber between them. Everything here is about that gap: noticing it, not
    inventing it, and not nagging people it does not apply to.
    """

    def _sub(self, months_ago, product, platform="google"):
        u = User.objects.create_user(username=f"step{months_ago}{product}", password="x")
        return Subscription.objects.create(
            user=u,
            started_at=date(2026, 1, 10),
            status=Subscription.Status.ACTIVE,
            platform=platform,
            store_product_id=product,
        )

    def test_product_matches_the_schedule(self):
        self.assertEqual(services.store_product_for_month(1, "google"), "spark")
        self.assertEqual(services.store_product_for_month(4, "google"), "rhythm")
        self.assertEqual(services.store_product_for_month(7, "google"), "independence")
        self.assertEqual(services.store_product_for_month(12, "google"), "release")
        self.assertEqual(services.store_product_for_month(4, "apple"), "com.nowlii.pro.rhythm")
        # Nothing to sell past the ladder.
        self.assertEqual(services.store_product_for_month(13, "google"), "")

    def test_no_step_while_on_the_right_rung(self):
        sub = self._sub(0, "spark")
        due = services.step_down_due(sub, date(2026, 2, 1))   # still month 1
        self.assertFalse(due["due"])

    def test_a_step_is_due_once_the_month_moves_on(self):
        sub = self._sub(0, "spark")
        due = services.step_down_due(sub, date(2026, 4, 10))  # month 4 → tier2
        self.assertTrue(due["due"])
        self.assertEqual(due["from_product"], "spark")
        self.assertEqual(due["to_product"], "rhythm")
        self.assertEqual(due["to_price"], 14.99)

    def test_a_skipped_rung_goes_straight_to_the_right_one(self):
        """Someone who did not open the app for six months should not be walked down one
        rung at a time — they should land on what they should be paying now."""
        sub = self._sub(0, "spark")
        due = services.step_down_due(sub, date(2026, 10, 10))  # month 10 → tier4
        self.assertEqual(due["to_product"], "release")

    def test_past_the_ladder_the_answer_is_cancel_not_switch(self):
        sub = self._sub(0, "release")
        due = services.step_down_due(sub, date(2027, 2, 10))   # month 14
        self.assertFalse(due["due"])
        self.assertTrue(due["cancel"])
        self.assertEqual(due["to_product"], "")

    def test_nothing_left_to_cancel_is_not_a_pending_action(self):
        sub = self._sub(0, "")
        sub.store_product_id = ""
        due = services.step_down_due(sub, date(2027, 2, 10))
        self.assertFalse(due["cancel"])

    def test_a_trial_user_is_never_asked_to_switch(self):
        u = User.objects.create_user(username="steptrial", password="x")
        sub = Subscription.objects.create(
            user=u, started_at=None, trial_started_at=date(2026, 1, 10),
            status=Subscription.Status.TRIAL, platform=Subscription.Platform.GOOGLE,
        )
        self.assertFalse(services.step_down_due(sub, date(2026, 6, 1))["due"])

    def test_mock_subscriptions_are_left_alone(self):
        """Mock is the test-only platform; there is no store product to move."""
        sub = self._sub(0, "spark", platform="mock")
        self.assertFalse(services.step_down_due(sub, date(2026, 6, 1))["due"])

    def test_the_gap_is_recorded_and_then_cleared(self):
        sub = self._sub(0, "spark")
        services.sync_step_down_state(sub, date(2026, 4, 10))
        sub.refresh_from_db()
        self.assertEqual(sub.step_down_pending_since, date(2026, 4, 10))

        # Seen again later: the date must stay the FIRST day it was noticed, because that
        # is what says how long they have been overpaying.
        services.sync_step_down_state(sub, date(2026, 5, 10))
        sub.refresh_from_db()
        self.assertEqual(sub.step_down_pending_since, date(2026, 4, 10))

        # The app finally switched them.
        sub.store_product_id = "rhythm"
        sub.save(update_fields=["store_product_id"])
        services.sync_step_down_state(sub, date(2026, 5, 11))
        sub.refresh_from_db()
        self.assertIsNone(sub.step_down_pending_since)


class ConfirmSwitchEndpointTests(APITestCase):
    """The device is the only thing that can move a subscriber down the ladder, so this is
    how the truth gets back to the backend afterwards."""

    def setUp(self):
        self.u = User.objects.create_user(username="switcher", password="x")
        self.client.force_authenticate(user=self.u)
        self.sub = Subscription.objects.create(
            user=self.u,
            started_at=date.today() - timedelta(days=100),   # ~month 4 → tier2 is due
            status=Subscription.Status.ACTIVE,
            platform=Subscription.Platform.GOOGLE,
            store_product_id="spark",
        )

    def test_me_reports_the_step_as_due(self):
        body = self.client.get("/api/subscriptions/me/").data
        self.assertTrue(body["step_down"]["due"])
        self.assertEqual(body["step_down"]["to_product"], "rhythm")

    def test_confirming_the_switch_closes_the_gap(self):
        response = self.client.post(
            "/api/subscriptions/confirm-switch/", {"store_product_id": "rhythm"}, format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["step_down"]["due"])

        self.sub.refresh_from_db()
        self.assertEqual(self.sub.store_product_id, "rhythm")
        self.assertIsNone(self.sub.step_down_pending_since)

    def test_reading_the_status_records_that_they_are_overpaying(self):
        self.client.get("/api/subscriptions/me/")
        self.sub.refresh_from_db()
        self.assertIsNotNone(self.sub.step_down_pending_since)

    def test_an_unknown_product_is_rejected(self):
        response = self.client.post(
            "/api/subscriptions/confirm-switch/", {"store_product_id": "platinum"}, format="json",
        )
        self.assertEqual(response.status_code, 400)
        self.sub.refresh_from_db()
        self.assertEqual(self.sub.store_product_id, "spark")

    def test_a_missing_product_is_rejected(self):
        self.assertEqual(
            self.client.post("/api/subscriptions/confirm-switch/", {}, format="json").status_code,
            400,
        )

    def test_apple_products_are_accepted_too(self):
        self.sub.platform = Subscription.Platform.APPLE
        self.sub.store_product_id = "com.nowlii.pro.spark"
        self.sub.save()
        response = self.client.post(
            "/api/subscriptions/confirm-switch/",
            {"store_product_id": "com.nowlii.pro.rhythm"}, format="json",
        )
        self.assertEqual(response.status_code, 200)
        self.assertFalse(response.data["step_down"]["due"])


class StageNameTests(APITestCase):
    """The paywall labels each step. The names live in the backend so the app cannot end up
    holding a copy that drifts from the schedule it describes."""

    def setUp(self):
        self.u = User.objects.create_user(username="stages", password="x")
        self.client.force_authenticate(user=self.u)

    def test_the_plan_carries_the_design_names(self):
        body = self.client.get("/api/subscriptions/plan/").data
        self.assertEqual([p["stage"] for p in body["phases"]],
                         ["Spark", "Rhythm", "Independence", "Release"])
        self.assertEqual(body["graduated_stage"], "Graduate")

    def test_the_free_stage_is_graduate(self):
        self.assertEqual(services.phase_for_month(13)["stage"], "Graduate")

    def test_every_paid_phase_has_a_product_on_both_stores(self):
        """A phase with no product is a phase nobody can be billed for."""
        for phase in config.PHASES:
            self.assertTrue(phase["google_base_plan"], phase)
            self.assertTrue(phase["apple_product"], phase)

    def test_product_ids_are_unique(self):
        google = [p["google_base_plan"] for p in config.PHASES]
        apple = [p["apple_product"] for p in config.PHASES]
        self.assertEqual(len(set(google)), len(google))
        self.assertEqual(len(set(apple)), len(apple))
