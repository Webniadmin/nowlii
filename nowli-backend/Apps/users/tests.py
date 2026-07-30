"""Tests for Apps.users.

Focused on the access-control rules that are easy to regress silently — a permission
change never fails loudly, it just quietly opens or closes a door.
"""
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from rest_framework.test import APIClient

from .models import NowliiPredefinedOption

User = get_user_model()


class NowliiPredefinedOptionPermissionTests(TestCase):
    """The companion catalogue: public to read, admin-only to write.

    It used to be `AllowAny` on a full ModelViewSet, so any anonymous caller could
    create, rename or DELETE every companion. Reads must stay open because the avatar
    picker runs during onboarding, before the user has a token.
    """

    def setUp(self):
        self.client = APIClient()
        self.option = NowliiPredefinedOption.objects.create(name="Bloop", voice="Female")
        self.list_url = reverse("nowlii-options-list")
        self.detail_url = reverse("nowlii-options-detail", args=[self.option.pk])

        self.user = User.objects.create_user(
            username="regular", email="regular@example.com", password="pw-for-tests-123"
        )
        self.admin = User.objects.create_superuser(
            username="boss", email="boss@example.com", password="pw-for-tests-123"
        )

    # ── reads stay public ────────────────────────────────────────────────────
    def test_anonymous_can_list(self):
        response = self.client.get(self.list_url)
        self.assertEqual(response.status_code, 200)

    def test_anonymous_can_retrieve(self):
        response = self.client.get(self.detail_url)
        self.assertEqual(response.status_code, 200)

    # ── writes are admin-only ────────────────────────────────────────────────
    def test_anonymous_cannot_create(self):
        response = self.client.post(self.list_url, {"name": "Intruder"}, format="json")
        self.assertIn(response.status_code, (401, 403))
        self.assertFalse(NowliiPredefinedOption.objects.filter(name="Intruder").exists())

    def test_anonymous_cannot_delete(self):
        response = self.client.delete(self.detail_url)
        self.assertIn(response.status_code, (401, 403))
        self.assertTrue(NowliiPredefinedOption.objects.filter(pk=self.option.pk).exists())

    def test_regular_user_cannot_delete(self):
        """Being logged in is not enough — the catalogue is shared across all users."""
        self.client.force_authenticate(user=self.user)
        response = self.client.delete(self.detail_url)
        self.assertEqual(response.status_code, 403)
        self.assertTrue(NowliiPredefinedOption.objects.filter(pk=self.option.pk).exists())

    def test_regular_user_cannot_rename(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.patch(self.detail_url, {"name": "Hijacked"}, format="json")
        self.assertEqual(response.status_code, 403)
        self.option.refresh_from_db()
        self.assertEqual(self.option.name, "Bloop")

    def test_admin_can_create(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.post(self.list_url, {"name": "Zee"}, format="json")
        self.assertEqual(response.status_code, 201)
        self.assertTrue(NowliiPredefinedOption.objects.filter(name="Zee").exists())

    def test_admin_can_delete(self):
        self.client.force_authenticate(user=self.admin)
        response = self.client.delete(self.detail_url)
        self.assertEqual(response.status_code, 204)
        self.assertFalse(NowliiPredefinedOption.objects.filter(pk=self.option.pk).exists())


class DefaultPermissionTests(TestCase):
    """DRF's default permission is now IsAuthenticated (fail closed).

    Every existing view declares its own `permission_classes`, so this only matters for
    views added later that forget to. The public auth endpoints must keep working.
    """

    def setUp(self):
        self.client = APIClient()

    def test_login_endpoint_remains_public(self):
        """Login must reject the *credentials*, not the *request*.

        It legitimately answers 401 for a bad password, so the status alone proves
        nothing — what matters is that DRF never short-circuits with its
        "credentials were not provided" permission error before the view runs.
        """
        response = self.client.post(
            reverse("auth-login"),
            {"email": "nobody@example.com", "password": "wrong"},
            format="json",
        )
        self.assertNotIn(
            "Authentication credentials were not provided",
            response.content.decode(),
        )

    def test_protected_endpoint_rejects_anonymous(self):
        response = self.client.get(reverse("profile-detail"))
        self.assertIn(response.status_code, (401, 403))
