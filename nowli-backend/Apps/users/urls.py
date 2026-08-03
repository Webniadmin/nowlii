from django.urls import path, include
from rest_framework.routers import DefaultRouter
from rest_framework_simplejwt.views import TokenRefreshView

from .views import (
    ProfileViewSet,
    ClearAIMemoryView,
    RegisterAPI,
    VerifyOTPView,
    ResendOTPView, 
    LoginAPI,
    GoogleLoginAPI,
    AppleLoginAPI,
    apple_web_redirect,
    DeleteAccountAPIView,
    LogoutAPIView,
    ForgotPasswordAPI,
    VerifyForgotPasswordOTPView,
    SetNewPasswordAPI,
    ResetPasswordAPI,
    NowliiPredefinedOptionViewSet,
)

router = DefaultRouter()
router.register(r'nowlii-options', NowliiPredefinedOptionViewSet, basename='nowlii-options')

urlpatterns = [
    path('', include(router.urls)),
    path('profiles/', ProfileViewSet.as_view({
        'get': 'list',     
        'post': 'create',   
        'put': 'update',   
        'patch': 'partial_update',
        'delete': 'destroy'
    }), name='profile-detail'),
    # "Clear All AI Memory" in AI Personalization. Deletes what the AI concluded, not the
    # call ledger the daily limit is counted from.
    path('profiles/clear-ai-memory/', ClearAIMemoryView.as_view(), name='profile-clear-ai-memory'),
    path('auth/register/', RegisterAPI.as_view(), name='auth-register'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='auth-verify-otp'),
    path('auth/resend-otp/', ResendOTPView.as_view(), name='auth-resend-otp'), 
    path('auth/login/', LoginAPI.as_view(), name='auth-login'),
    path('auth/google/', GoogleLoginAPI.as_view(), name='auth-google-login'),
    path('auth/apple/', AppleLoginAPI.as_view(), name='auth-apple-login'),
    # Apple web-redirect Return URL (Android web-flow only; see apple_web_redirect).
    path('auth/apple/callback/', apple_web_redirect, name='auth-apple-callback'),
    path('auth/logout/', LogoutAPIView.as_view(), name='auth-logout'),
    # Exchange a refresh token for a fresh access token. Without this route the app had
    # no way to stay signed in: it stored a refresh token it could never spend, so once
    # the access token expired every request failed with nothing to recover from.
    # ROTATE_REFRESH_TOKENS is on, so the response carries a NEW refresh token too and
    # the client must store both.
    path('auth/token/refresh/', TokenRefreshView.as_view(), name='auth-token-refresh'),
    # Required by Google Play's data-deletion policy and Apple guideline 5.1.1(v).
    path('auth/delete-account/', DeleteAccountAPIView.as_view(), name='auth-delete-account'),
    path('auth/forgot-password/', ForgotPasswordAPI.as_view(), name='auth-forgot-password'),
    path('auth/verify-forgot-password-otp/', VerifyForgotPasswordOTPView.as_view(), name='auth-verify-forgot-password-otp'),
    path('auth/set-new-password/', SetNewPasswordAPI.as_view(), name='auth-set-new-password'),
    path('auth/reset-password/', ResetPasswordAPI.as_view(), name='auth-reset-password'),
]
