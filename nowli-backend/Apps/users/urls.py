from django.urls import path, include
from rest_framework.routers import DefaultRouter

from .views import (
    ProfileViewSet,
    RegisterAPI,
    VerifyOTPView,
    ResendOTPView, 
    LoginAPI,
    GoogleLoginAPI,
    AppleLoginAPI,
    apple_web_redirect,
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
    path('auth/register/', RegisterAPI.as_view(), name='auth-register'),
    path('auth/verify-otp/', VerifyOTPView.as_view(), name='auth-verify-otp'),
    path('auth/resend-otp/', ResendOTPView.as_view(), name='auth-resend-otp'), 
    path('auth/login/', LoginAPI.as_view(), name='auth-login'),
    path('auth/google/', GoogleLoginAPI.as_view(), name='auth-google-login'),
    path('auth/apple/', AppleLoginAPI.as_view(), name='auth-apple-login'),
    # Apple web-redirect Return URL (Android web-flow only; see apple_web_redirect).
    path('auth/apple/callback/', apple_web_redirect, name='auth-apple-callback'),
    path('auth/logout/', LogoutAPIView.as_view(), name='auth-logout'),
    path('auth/forgot-password/', ForgotPasswordAPI.as_view(), name='auth-forgot-password'),
    path('auth/verify-forgot-password-otp/', VerifyForgotPasswordOTPView.as_view(), name='auth-verify-forgot-password-otp'),
    path('auth/set-new-password/', SetNewPasswordAPI.as_view(), name='auth-set-new-password'),
    path('auth/reset-password/', ResetPasswordAPI.as_view(), name='auth-reset-password'),
]
