from datetime import date, timedelta

from django.contrib.auth import get_user_model
from rest_framework.test import APITestCase

from . import services
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

    def test_no_subscription_is_not_pro(self):
        u = User.objects.create_user(username="free", password="x")
        self.assertFalse(services.user_has_pro(u))


class EndpointTests(APITestCase):
    def setUp(self):
        self.u = User.objects.create_user(username="ep", password="x")
        self.client.force_authenticate(self.u)

    def test_plan(self):
        r = self.client.get("/api/subscriptions/plan/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["currency"], "USD")
        self.assertEqual(len(r.data["phases"]), 4)
        self.assertEqual(r.data["free_after_month"], 12)

    def test_activate_and_status_flow(self):
        r = self.client.get("/api/subscriptions/me/")
        self.assertFalse(r.data["subscribed"])
        self.assertFalse(r.data["has_access"])

        r = self.client.post("/api/subscriptions/activate/")
        self.assertEqual(r.status_code, 200)
        self.assertTrue(r.data["subscribed"])
        self.assertEqual(r.data["month_index"], 1)
        self.assertEqual(r.data["current_price"], 19.99)
        self.assertEqual(r.data["next_price"], 19.99)
        self.assertTrue(r.data["has_access"])

    def test_cancel_flow(self):
        self.client.post("/api/subscriptions/activate/")
        r = self.client.post("/api/subscriptions/cancel/")
        self.assertEqual(r.status_code, 200)
        self.assertEqual(r.data["status"], Subscription.Status.CANCELLED)

    def test_verify_receipt_stub(self):
        r = self.client.post("/api/subscriptions/verify-receipt/")
        self.assertEqual(r.status_code, 501)
