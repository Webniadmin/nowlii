"""Tests for Apps.users.

Focused on the access-control rules that are easy to regress silently — a permission
change never fails loudly, it just quietly opens or closes a door.
"""
from datetime import time

from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken

from Apps.quests.models import Quests, SubTasks
from Apps.voice_calls.models import VoiceCall

from .models import NowliiPredefinedOption, Profile

User = get_user_model()


def _make_user(username):
    return User.objects.create_user(
        username=username, email=f'{username}@example.com', password='pw-for-tests-123',
    )


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


class DeleteAccountTests(TestCase):
    """Deleting an account must actually delete it — everywhere.

    This used to be a dialog that showed "Account deletion initiated" and did nothing at
    all, which is a hard rejection under Google Play's data-deletion policy and Apple
    guideline 5.1.1(v), and a false statement to the user under the GDPR. So the tests here
    check the data is really gone, not that the endpoint returned 200.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = _make_user('leaver')
        self.bystander = _make_user('stayer')
        self.url = reverse('auth-delete-account')

    def _seed_data_for(self, user):
        """Give the user one row in every table that hangs off them."""
        Profile.objects.create(user=user, name='Test Person')
        quest = Quests.objects.create(
            user=user, task='A quest', zone='Soft steps',
            select_a_date=timezone.localdate(), select_a_time=time(10, 0),
        )
        SubTasks.objects.create(task=quest, title='A subtask')
        VoiceCall.objects.create(user=user)
        return quest

    def test_deleting_removes_the_user_and_everything_they_own(self):
        self._seed_data_for(self.user)
        self.client.force_authenticate(user=self.user)

        response = self.client.post(self.url, {'confirm': True}, format='json')
        self.assertEqual(response.status_code, 200)

        self.assertFalse(User.objects.filter(pk=self.user.pk).exists())
        self.assertFalse(Profile.objects.filter(user_id=self.user.pk).exists())
        self.assertFalse(Quests.objects.filter(user_id=self.user.pk).exists())
        self.assertFalse(VoiceCall.objects.filter(user_id=self.user.pk).exists())
        # Subtasks hang off the quest, not the user — they must go with it.
        self.assertFalse(SubTasks.objects.exists())

    def test_other_users_are_untouched(self):
        self._seed_data_for(self.bystander)
        self.client.force_authenticate(user=self.user)

        self.client.post(self.url, {'confirm': True}, format='json')

        self.assertTrue(User.objects.filter(pk=self.bystander.pk).exists())
        self.assertTrue(Quests.objects.filter(user_id=self.bystander.pk).exists())

    def test_confirmation_is_required(self):
        """A stray POST must not be able to destroy an account."""
        self.client.force_authenticate(user=self.user)
        response = self.client.post(self.url, {}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())

    def test_confirm_false_is_refused(self):
        self.client.force_authenticate(user=self.user)
        response = self.client.post(self.url, {'confirm': False}, format='json')
        self.assertEqual(response.status_code, 400)
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())

    def test_anonymous_callers_are_rejected(self):
        response = self.client.post(self.url, {'confirm': True}, format='json')
        self.assertIn(response.status_code, (401, 403))
        self.assertTrue(User.objects.filter(pk=self.user.pk).exists())

    def test_the_token_stops_working_afterwards(self):
        """Whatever the client still holds must not keep opening doors.

        Uses a real JWT rather than force_authenticate: the point is that the token is
        resolved against the database on every request, and after deletion there is no user
        for it to resolve to.
        """
        token = str(AccessToken.for_user(self.user))
        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {token}')

        self.assertEqual(
            self.client.post(self.url, {'confirm': True}, format='json').status_code, 200,
        )

        # Same token, same client — the account behind it is gone.
        follow_up = self.client.get(reverse('profile-detail'))
        self.assertIn(follow_up.status_code, (401, 403))

    def test_the_email_is_freed_for_a_fresh_signup(self):
        """Deletion must not leave the address permanently unusable."""
        email = self.user.email
        self.client.force_authenticate(user=self.user)
        self.client.post(self.url, {'confirm': True}, format='json')

        self.assertFalse(User.objects.filter(email=email).exists())
        User.objects.create_user(username='reborn', email=email, password='pw-for-tests-123')


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
