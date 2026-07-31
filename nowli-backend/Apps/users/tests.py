"""Tests for Apps.users.

Focused on the access-control rules that are easy to regress silently — a permission
change never fails loudly, it just quietly opens or closes a door.
"""
from datetime import time

from django.conf import settings
from django.contrib.auth import get_user_model
from django.test import TestCase
from django.urls import reverse
from django.utils import timezone
from rest_framework.test import APIClient
from rest_framework_simplejwt.tokens import AccessToken, RefreshToken

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


class TokenRefreshTests(TestCase):
    """Staying signed in without ever re-entering a password.

    There was no refresh route at all: the app stored a refresh token it could never spend,
    so when the access token expired every request failed with no way to recover. These
    tests cover the contract the client depends on.
    """

    def setUp(self):
        self.client = APIClient()
        self.user = _make_user('regular2')
        self.url = reverse('auth-token-refresh')
        self.refresh = RefreshToken.for_user(self.user)

    def test_a_refresh_token_buys_a_new_access_token(self):
        response = self.client.post(
            self.url, {'refresh': str(self.refresh)}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)

    def test_the_new_access_token_actually_works(self):
        access = self.client.post(
            self.url, {'refresh': str(self.refresh)}, format='json',
        ).data['access']

        self.client.credentials(HTTP_AUTHORIZATION=f'Bearer {access}')
        # 404 = authenticated but no profile yet; 401 would mean the token was rejected.
        self.assertNotEqual(self.client.get(reverse('profile-detail')).status_code, 401)

    def test_a_rotated_refresh_token_comes_back(self):
        """ROTATE_REFRESH_TOKENS is on, so the client must store the new one."""
        response = self.client.post(
            self.url, {'refresh': str(self.refresh)}, format='json',
        )
        self.assertIn('refresh', response.data)
        self.assertNotEqual(response.data['refresh'], str(self.refresh))

    def test_the_old_refresh_token_stops_working(self):
        """BLACKLIST_AFTER_ROTATION — this is why the client must serialise refreshes.

        Two concurrent refreshes and the second presents this already-spent token, which
        signs the user out.
        """
        old = str(self.refresh)
        self.client.post(self.url, {'refresh': old}, format='json')

        second = self.client.post(self.url, {'refresh': old}, format='json')
        self.assertEqual(second.status_code, 401)

    def test_garbage_is_rejected_rather_than_accepted(self):
        response = self.client.post(self.url, {'refresh': 'not-a-token'}, format='json')
        self.assertEqual(response.status_code, 401)

    def test_the_refresh_token_outlives_the_access_token_by_a_wide_margin(self):
        """The configuration that makes the whole flow work — or quietly defeats it.

        Both lifetimes were once 31 days. Since both tokens are issued together at login,
        they also expired together: the client refreshes only when the access token is
        nearly up, by which point the refresh token is nearly up too. Open the app an hour
        late on day 31 and both are dead, so the user is signed out regardless — the refresh
        token was decorative.

        Asserted here rather than trusted to a comment, because nothing else would fail if
        someone narrowed the gap: everything keeps working perfectly until day 31.
        """
        access = settings.SIMPLE_JWT['ACCESS_TOKEN_LIFETIME']
        refresh = settings.SIMPLE_JWT['REFRESH_TOKEN_LIFETIME']
        self.assertGreaterEqual(
            refresh, access * 10,
            msg=f'refresh ({refresh}) must comfortably outlive access ({access})',
        )

    def test_a_stale_access_token_can_still_be_refreshed(self):
        """The real-world case: the app was closed long enough for the access token to die.

        The refresh token is what proves who they are, so an expired — even garbage — access
        token must not stand in the way.
        """
        self.client.credentials(HTTP_AUTHORIZATION='Bearer an.expired.token')
        response = self.client.post(
            self.url, {'refresh': str(self.refresh)}, format='json',
        )
        self.assertEqual(response.status_code, 200)
        self.assertIn('access', response.data)

    def test_refreshing_needs_no_prior_authentication(self):
        """The refresh token IS the credential — the caller has no valid access token left."""
        self.client.credentials()  # explicitly anonymous
        response = self.client.post(
            self.url, {'refresh': str(self.refresh)}, format='json',
        )
        self.assertEqual(response.status_code, 200)


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


class AppleWebRedirectTests(TestCase):
    """The Android leg of Sign in with Apple.

    Apple `form_post`s here and we must hand the credential back to the app through
    the plugin's custom-scheme intent. This used to be a bare 307, which Chrome
    silently refused to follow without a user gesture — the login simply never
    completed. So the page itself is the fix, and these tests pin the parts that
    make it work rather than just asserting a 200.
    """

    def setUp(self):
        self.url = reverse("auth-apple-callback")

    def test_apples_form_post_is_answered_with_a_page_not_a_redirect(self):
        response = self.client.post(self.url, {"code": "abc123", "state": "xyz"})
        self.assertEqual(response.status_code, 200)
        self.assertNotIn("Location", response)
        self.assertIn("text/html", response["Content-Type"])

    def test_the_intent_carries_apples_parameters_back_to_the_app(self):
        response = self.client.post(self.url, {"code": "abc123", "state": "xyz"})
        body = response.content.decode()
        self.assertIn("intent://callback?", body)
        self.assertIn("code=abc123", body)
        self.assertIn("state=xyz", body)
        self.assertIn("package=com.nowlii.app", body)
        self.assertIn("scheme=signinwithapple", body)

    def test_there_is_a_tappable_link_because_the_automatic_hop_may_be_blocked(self):
        """The whole point of the rewrite: a real user gesture as a fallback.

        Chrome blocks server-driven intent:// navigation, so an automatic hop alone
        reproduces the original bug.
        """
        body = self.client.post(self.url, {"code": "abc123"}).content.decode()
        self.assertIn('href="intent://callback?', body)
        self.assertIn("window.location.replace", body)

    def test_apples_error_response_is_passed_through_rather_than_swallowed(self):
        body = self.client.post(self.url, {"error": "user_cancelled"}).content.decode()
        self.assertIn("error=user_cancelled", body)

    def test_a_hostile_parameter_cannot_break_out_into_markup(self):
        """Values come from a POST body, so they are attacker-influenced input."""
        response = self.client.post(
            self.url, {"state": '"><script>alert(1)</script>'}
        )
        body = response.content.decode()
        self.assertNotIn("<script>alert(1)</script>", body)
        self.assertNotIn('"><script', body)

    def test_it_needs_no_csrf_token_because_the_caller_is_apple(self):
        from django.test import Client

        response = Client(enforce_csrf_checks=True).post(self.url, {"code": "abc"})
        self.assertEqual(response.status_code, 200)
