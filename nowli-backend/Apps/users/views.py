from django.conf import settings
from django.contrib.auth import get_user_model
from django.core.mail import send_mail
from django.http import HttpResponse
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from urllib.parse import urlencode

from rest_framework import status, viewsets
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.parsers import JSONParser, MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.exceptions import ValidationError

from rest_framework_simplejwt.tokens import RefreshToken
from rest_framework_simplejwt.views import TokenObtainPairView

from google.oauth2 import id_token as google_id_token
from google.auth.transport import requests as google_requests

import jwt
from jwt import PyJWKClient

from drf_yasg import openapi
from drf_yasg.utils import swagger_auto_schema

from allauth.socialaccount.providers.google.views import GoogleOAuth2Adapter
from allauth.socialaccount.providers.oauth2.client import OAuth2Client

from allauth.socialaccount.providers.apple.views import AppleOAuth2Adapter
from allauth.socialaccount.providers.apple.client import AppleOAuth2Client

from dj_rest_auth.registration.views import SocialLoginView

from .models import (
    Profile,
    PendingUser,
    ForgotPasswordRequest,
    NowliiPredefinedOption,
)

from .serializers import (
    RegisterSerializer,
    VerifyOTPSerializer,
    LoginSerializer,
    GoogleLoginSerializer,
    AppleLoginSerializer,
    LogoutSerializer,
    ForgotPasswordSerializer,
    VerifyForgotPasswordOTPSerializer,
    ResetPasswordSerializer,
    SetNewPasswordSerializer,
    ProfileSerializer,
    ResendOTPSerializer,
    NowliiPredefinedOptionSerializer,
)


# ------------------------------------------------------------------------------
# NOWLII PREDEFINED OPTIONS
# ------------------------------------------------------------------------------
@method_decorator(name='list', decorator=swagger_auto_schema(
    operation_summary="List available Nowlii names and avatars",
    operation_description="Fetch the list of predefined Nowlii options. These options include default names and avatar URLs that users can choose for their profiles.",
    tags=['Nowlii Options'],
    responses={
        200: openapi.Response(
            description="Success",
            schema=NowliiPredefinedOptionSerializer(many=True),
            examples={
                "application/json": [
                    {
                        "id": 1,
                        "name": "Nowlii Bot",
                        "avatar_logo": "/media/nowlii_logos/sparky.png"
                    }
                ]
            }
        )
    }
))
@method_decorator(name='create', decorator=swagger_auto_schema(
    operation_summary="Create a new Nowlii option",
    operation_description="Add a new predefined Nowlii name and avatar logo URL to the system. Typically used by admins to expand the available selection.",
    tags=['Nowlii Options'],
    request_body=NowliiPredefinedOptionSerializer,
    responses={
        201: openapi.Response(
            description="Created successfully",
            schema=NowliiPredefinedOptionSerializer()
        ),
        400: "Bad Request - Invalid data"
    }
))
@method_decorator(name='retrieve', decorator=swagger_auto_schema(
    operation_summary="Retrieve a Nowlii option",
    operation_description="Fetch details of a specific predefined Nowlii option by its unique ID.",
    tags=['Nowlii Options'],
    responses={
        200: openapi.Response(
            description="Success",
            schema=NowliiPredefinedOptionSerializer()
        ),
        404: "Not Found"
    }
))
@method_decorator(name='update', decorator=swagger_auto_schema(
    operation_summary="Update a Nowlii option",
    operation_description="Update all fields of an existing predefined Nowlii option by its ID.",
    tags=['Nowlii Options'],
    request_body=NowliiPredefinedOptionSerializer,
    responses={
        200: openapi.Response(
            description="Updated successfully",
            schema=NowliiPredefinedOptionSerializer()
        ),
        400: "Bad Request",
        404: "Not Found"
    }
))
@method_decorator(name='partial_update', decorator=swagger_auto_schema(
    operation_summary="Partially update a Nowlii option",
    operation_description="Update specific fields of an existing predefined Nowlii option.",
    tags=['Nowlii Options'],
    request_body=NowliiPredefinedOptionSerializer,
    responses={
        200: openapi.Response(
            description="Updated successfully",
            schema=NowliiPredefinedOptionSerializer()
        ),
        404: "Not Found"
    }
))
@method_decorator(name='destroy', decorator=swagger_auto_schema(
    operation_summary="Delete a Nowlii option",
    operation_description="Remove a predefined Nowlii option from the system by its ID.",
    tags=['Nowlii Options'],
    responses={
        204: "Deleted successfully",
        404: "Not Found"
    }
))
class NowliiPredefinedOptionViewSet(viewsets.ModelViewSet):
    queryset = NowliiPredefinedOption.objects.all()
    serializer_class = NowliiPredefinedOptionSerializer
    permission_classes = [AllowAny]


# ------------------------------------------------------------------------------
# PROFILE
# ------------------------------------------------------------------------------
@method_decorator(name='list', decorator=swagger_auto_schema(
    operation_summary="List all profiles",
    operation_description="Get a list of all profile entries.",
    tags=['Profile']
))
@method_decorator(name='create', decorator=swagger_auto_schema(
    operation_summary="Create profile",
    operation_description="Create a new profile entry.",
    tags=['Profile']
))
@method_decorator(name='retrieve', decorator=swagger_auto_schema(
    operation_summary="Get profile details",
    operation_description="Get details of a specific profile entry by ID.",
    tags=['Profile']
))
@method_decorator(name='update', decorator=swagger_auto_schema(
    operation_summary="Update profile",
    operation_description="Update a specific profile entry by ID.",
    tags=['Profile']
))
@method_decorator(name='partial_update', decorator=swagger_auto_schema(
    operation_summary="Partially update profile",
    operation_description="Partially update a specific profile entry by ID.",
    tags=['Profile']
))
@method_decorator(name='destroy', decorator=swagger_auto_schema(
    operation_summary="Delete profile",
    operation_description="Delete a specific profile entry by ID.",
    tags=['Profile']
))
class ProfileViewSet(viewsets.ModelViewSet):
    serializer_class = ProfileSerializer
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    def get_queryset(self):
        return Profile.objects.filter(user=self.request.user)

    def list(self, request, *args, **kwargs):
        obj = self.get_queryset().first()
        if not obj:
            return Response({"detail": "No profile found."}, status=status.HTTP_404_NOT_FOUND)
        serializer = self.get_serializer(obj)
        return Response(serializer.data)

    def get_object(self):
        obj = self.get_queryset().first()
        if not obj:
            from django.http import Http404
            raise Http404("No profile found.")
        self.check_object_permissions(self.request, obj)
        return obj

    def update(self, request, *args, **kwargs):
        kwargs['pk'] = self.get_object().pk
        return super().update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        kwargs['pk'] = self.get_object().pk
        return super().destroy(request, *args, **kwargs)

    def perform_create(self, serializer):
        if Profile.objects.filter(user=self.request.user).exists():
            raise ValidationError({"detail": "You already have a profile. You can only update or delete it."})
        serializer.save(user=self.request.user)


# ------------------------------------------------------------------------------
# REGISTRATION
# ------------------------------------------------------------------------------
class RegisterAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Register new user",
        operation_description="Register a new user account. An OTP will be sent to the provided email for verification. The OTP expires in 15 minutes.",
        tags=['Authentication'],
        request_body=RegisterSerializer,
        responses={
            201: openapi.Response(
                description="OTP sent successfully",
                examples={
                    "application/json": {
                        "message": "OTP sent to your email. Verify to complete registration."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request",
                examples={
                    "application/json": {
                        "error": "User already exists."
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = RegisterSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        password = serializer.validated_data["password"]
        username = serializer.validated_data.get("username", "")

        User = get_user_model()
        if User.objects.filter(email=email).exists():
            return Response({"error": "User already exists."}, status=status.HTTP_400_BAD_REQUEST)

        pending_user, created = PendingUser.objects.get_or_create(email=email)
        pending_user.password = password
        pending_user.username = username if username else ""
        otp = pending_user.generate_otp()  
        pending_user.save()

        send_mail(
            subject="Your Nowlii verification code",
            message=f"Your OTP code is {otp}. It expires in 15 minutes.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
        )
        return Response({"message": "OTP sent to your email. Verify to complete registration."}, status=status.HTTP_201_CREATED)


# ------------------------------------------------------------------------------
# VERIFY REGISTRATION OTP
# ------------------------------------------------------------------------------
class VerifyOTPView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Verify Register OTP",
        operation_description="Verify the 6-digit OTP code sent to your email to complete user registration. OTP codes expire after 15 minutes.",
        tags=['Authentication'],
        request_body=VerifyOTPSerializer,
        responses={
            200: openapi.Response(
                description="Registration completed",
                examples={
                    "application/json": {
                        "message": "Registration complete. You can now log in."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request - Invalid or expired OTP",
                examples={
                    "application/json": {
                        "error": "Invalid or expired OTP."
                    }
                }
            ),
            404: openapi.Response(
                description="Pending registration not found",
                examples={
                    "application/json": {
                        "error": "Pending registration not found."
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = VerifyOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        otp = serializer.validated_data["otp"]

        pending = PendingUser.objects.filter(email=email).first()
        if not pending:
            return Response({"error": "Pending registration not found."}, status=status.HTTP_404_NOT_FOUND)

        ok, msg = pending.verify_otp(otp)
        if not ok:
            return Response({"error": msg}, status=status.HTTP_400_BAD_REQUEST)

        raw_password = pending.password

        User = get_user_model()
        
        if pending.username:
            username = pending.username
        else:
            username = email.split("@")[0].lower()

        user = User.objects.create_user(username=username, email=email, password=raw_password)
        user.is_active = True
        user.save()
        pending.delete()

        return Response({"message": "Registration complete. You can now log in."}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# RESEND REGISTRATION OTP
# ------------------------------------------------------------------------------
class ResendOTPView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Resend Registration OTP",
        operation_description="Resend OTP to email if the previous one was missed or expired. A new 6-digit OTP will be generated and sent to the provided email.",
        tags=['Authentication'],
        request_body=ResendOTPSerializer,
        responses={
            200: openapi.Response(
                description="OTP resent successfully",
                examples={
                    "application/json": {
                        "message": "OTP has been resent to your email."
                    }
                }
            ),
            404: openapi.Response(
                description="Pending registration not found",
                examples={
                    "application/json": {
                        "error": "No pending registration found for this email."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request",
                examples={
                    "application/json": {
                        "email": ["This field is required."]
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = ResendOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        
        pending_user = PendingUser.objects.filter(email=email).first()
        if not pending_user:
            return Response({"error": "No pending registration found for this email."}, status=status.HTTP_404_NOT_FOUND)
        
        # Generate new OTP
        otp = pending_user.generate_otp()
        
        # Send email with new OTP
        send_mail(
            subject="Your Nowlii verification code (Resent)",
            message=f"Your new OTP code is {otp}. It expires in 15 minutes.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
        )
        
        return Response({"message": "OTP has been resent to your email."}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# LOGIN
# ------------------------------------------------------------------------------
class LoginAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="User login",
        operation_description="Authenticate with email and password to receive JWT access and refresh tokens. Use the access token for authenticated API requests.",
        tags=['Authentication'],
        request_body=LoginSerializer,
        responses={
            200: openapi.Response(
                description="Login successful",
                examples={
                    "application/json": {
                        "refresh": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0b2tlbl90eXBlIjoicmVmcmVzaCIsImV4cCI6MTY0...",
                        "access": "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ0b2tlbl90eXBlIjoiYWNjZXNzIiwiZXhwIjoxNjQ...",
                        "user": {
                            "user_id": 1,
                            "email": "admin@gmail.com",
                            "username": "admin",
                            "is_superuser": False
                        }
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request - Missing credentials",
                examples={
                    "application/json": {
                        "email": ["This field is required."],
                        "password": ["This field is required."]
                    }
                }
            ),
            401: openapi.Response(
                description="Unauthorized - Invalid credentials",
                examples={
                    "application/json": {
                        "error": "Invalid credentials."
                    }
                }
            )
        }
    )
    def post(self, request, *args, **kwargs):
        # Normalize the email before validation: mobile autofill/keyboards often append a
        # trailing space or newline, which makes EmailField reject the login with a 400
        # before credentials are ever checked. Trimming is always safe for an email.
        data = request.data.copy() if hasattr(request.data, 'copy') else dict(request.data)
        if data.get('email'):
            data['email'] = str(data['email']).strip()
        serializer = LoginSerializer(data=data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        email = serializer.validated_data['email']
        password = serializer.validated_data['password']

        # Case-insensitive lookup so an auto-capitalized first letter (common on phone
        # keyboards) doesn't turn a correct login into "Invalid credentials".
        user = get_user_model().objects.filter(email__iexact=email).first()
        if user is None or not user.check_password(password):
            return Response({'error': 'Invalid credentials.'}, status=status.HTTP_401_UNAUTHORIZED)

        refresh = RefreshToken.for_user(user)
        access_token = refresh.access_token

        return Response({
            'refresh': str(refresh),
            'access': str(access_token),
            'user': {
                'user_id': user.id,
                'email': user.email,
#                'username': user.username,
                'is_superuser': user.is_superuser
            }
        })


# ------------------------------------------------------------------------------
# GOOGLE LOGIN  (token exchange: Google id_token -> NOWLII JWT)
# ------------------------------------------------------------------------------
class GoogleLoginAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    @swagger_auto_schema(
        operation_summary="Login / sign up with Google",
        operation_description=(
            "Exchange a Google `id_token` (obtained by the mobile/web Google Sign-In SDK) "
            "for NOWLII JWT access & refresh tokens. The account is created on first use. "
            "Returns the same shape as `/auth/login/`, plus `is_new_user`."
        ),
        tags=['Authentication'],
        request_body=GoogleLoginSerializer,
        responses={
            200: openapi.Response(description="Login successful (tokens + user)"),
            401: openapi.Response(description="Invalid Google token / unverified email"),
            503: openapi.Response(description="Google login not configured on the server"),
        },
    )
    def post(self, request):
        serializer = GoogleLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        client_id = settings.GOOGLE_OAUTH_CLIENT_ID
        if not client_id:
            return Response(
                {'error': 'Google login is not configured on the server.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        # Verify signature, expiry and issuer against Google, and that the token was
        # minted for OUR client id (the `aud` claim).
        try:
            idinfo = google_id_token.verify_oauth2_token(
                serializer.validated_data['id_token'],
                google_requests.Request(),
                client_id,
            )
        except ValueError:
            return Response({'error': 'Invalid Google token.'}, status=status.HTTP_401_UNAUTHORIZED)

        email = idinfo.get('email')
        if not email or not idinfo.get('email_verified', False):
            return Response(
                {'error': 'Google account has no verified email.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        User = get_user_model()
        user, created = User.objects.get_or_create(
            email=User.objects.normalize_email(email),
            defaults={'is_active': True},
        )
        if created:
            # OAuth user has no local password.
            user.set_unusable_password()
            user.save(update_fields=['password'])
        elif not user.is_active:
            # A Google-verified email is trusted, so activate a previously-pending account.
            user.is_active = True
            user.save(update_fields=['is_active'])

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': {
                'user_id': user.id,
                'email': user.email,
                'is_superuser': user.is_superuser,
            },
            'is_new_user': created,
        })


# ------------------------------------------------------------------------------
# APPLE LOGIN  (token exchange: Apple identity_token -> NOWLII JWT)
# ------------------------------------------------------------------------------
APPLE_JWKS_URL = "https://appleid.apple.com/auth/keys"
APPLE_ISSUER = "https://appleid.apple.com"


class AppleLoginAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]

    @swagger_auto_schema(
        operation_summary="Login / sign up with Apple",
        operation_description=(
            "Exchange an Apple `identity_token` (from Sign in with Apple) for NOWLII JWT "
            "access & refresh tokens. Account is created on first use. Same response shape "
            "as `/auth/login/`, plus `is_new_user`."
        ),
        tags=['Authentication'],
        request_body=AppleLoginSerializer,
        responses={
            200: openapi.Response(description="Login successful (tokens + user)"),
            401: openapi.Response(description="Invalid Apple token / no email"),
            503: openapi.Response(description="Apple login not configured on the server"),
        },
    )
    def post(self, request):
        serializer = AppleLoginSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        audiences = settings.APPLE_CLIENT_IDS
        if not audiences:
            return Response(
                {'error': 'Apple login is not configured on the server.'},
                status=status.HTTP_503_SERVICE_UNAVAILABLE,
            )

        # Verify the identity token against Apple's public keys: signature, expiry, issuer,
        # and that `aud` is one of our client ids (bundle id / Service ID).
        try:
            signing_key = PyJWKClient(APPLE_JWKS_URL).get_signing_key_from_jwt(
                serializer.validated_data['identity_token']
            )
            claims = jwt.decode(
                serializer.validated_data['identity_token'],
                signing_key.key,
                algorithms=['RS256'],
                audience=audiences,
                issuer=APPLE_ISSUER,
            )
        except Exception:
            return Response({'error': 'Invalid Apple token.'}, status=status.HTTP_401_UNAUTHORIZED)

        # Apple carries the email in the token when the user shared it; on later logins the
        # client may pass it through explicitly.
        email = (claims.get('email') or serializer.validated_data.get('email') or '').strip()
        if not email:
            return Response(
                {'error': 'Apple did not provide an email for this account.'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        User = get_user_model()
        email = User.objects.normalize_email(email)
        user = User.objects.filter(email=email).first()
        created = False
        if user is None:
            # Build a unique username (the default User model requires one).
            base = (email.split('@')[0] or 'apple')[:140]
            username = base
            n = 0
            while User.objects.filter(username=username).exists():
                n += 1
                username = f"{base}{n}"[:150]
            user = User.objects.create_user(username=username, email=email)  # unusable password
            user.is_active = True
            user.save()
            created = True
        elif not user.is_active:
            user.is_active = True
            user.save(update_fields=['is_active'])

        refresh = RefreshToken.for_user(user)
        return Response({
            'refresh': str(refresh),
            'access': str(refresh.access_token),
            'user': {
                'user_id': user.id,
                'email': user.email,
                'is_superuser': user.is_superuser,
            },
            'is_new_user': created,
        })


# ------------------------------------------------------------------------------
# APPLE WEB REDIRECT (Android web-flow only)
# ------------------------------------------------------------------------------
# The `sign_in_with_apple` Android flow opens Apple's auth page in a Chrome Custom
# Tab; on success Apple does an HTML `form_post` to this Return URL. We must bounce
# that POST back into the app via the plugin's custom-scheme intent so it can pick
# up the identity token. This endpoint is registered as the Services ID "Return URL"
# (e.g. https://<public-host>/api/auth/apple/callback/) and set as APPLE_REDIRECT_URI
# on the client. iOS native does NOT use this (it has no redirect). No auth / CSRF:
# the caller is Apple, not our client.
@csrf_exempt
def apple_web_redirect(request):
    params = request.POST.dict() or request.GET.dict()
    intent = (
        "intent://callback?" + urlencode(params) +
        "#Intent;package=com.nowlii.app;scheme=signinwithapple;end"
    )
    # 307 keeps the method/semantics while the Custom Tab hands the intent:// URL to
    # Android, which routes it to the plugin's SignInWithAppleCallback activity.
    resp = HttpResponse(status=307)
    resp['Location'] = intent
    return resp


# ------------------------------------------------------------------------------
# LOGOUT
# ------------------------------------------------------------------------------
class LogoutAPIView(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="User logout",
        operation_description="Logout by blacklisting the JWT refresh token. After logout, the refresh token cannot be used to obtain new access tokens.",
        tags=['Authentication'],
        request_body=LogoutSerializer,
        responses={
            200: openapi.Response(
                description="Logout successful",
                examples={
                    "application/json": {
                        "message": "Logged out successfully"
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request - Invalid token",
                examples={
                    "application/json": {
                        "error": "Token is invalid or expired"
                    }
                }
            ),
            401: "Unauthorized - Authentication required"
        }
    )
    def post(self, request):
        serializer = LogoutSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        try:
            refresh_token = serializer.validated_data["refresh_token"]
            token = RefreshToken(refresh_token)
            token.blacklist()  
            return Response({"message": "Logged out successfully"}, status=status.HTTP_200_OK)
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_400_BAD_REQUEST)


# ------------------------------------------------------------------------------
# FORGOT PASSWORD
# ------------------------------------------------------------------------------
class ForgotPasswordAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Forgot password",
        operation_description="Request password reset. An OTP will be sent to the provided email. OTP expires in 15 minutes.",
        tags=['Authentication'],
        request_body=ForgotPasswordSerializer,
        responses={
            200: openapi.Response(
                description="OTP sent successfully",
                examples={
                    "application/json": {
                        "message": "OTP sent to your email."
                    }
                }
            ),
            404: openapi.Response(
                description="User not found",
                examples={
                    "application/json": {
                        "error": "User with this email does not exist."
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = ForgotPasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        
        User = get_user_model()
        if not User.objects.filter(email=email).exists():
            return Response({"error": "User with this email does not exist."}, status=status.HTTP_404_NOT_FOUND)
        
        forgot_request, created = ForgotPasswordRequest.objects.get_or_create(email=email)
        otp = forgot_request.generate_otp()
        
        send_mail(
            subject="Your Nowlii password reset code",
            message=f"Your OTP code is {otp}. It expires in 15 minutes.",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
        )
        return Response({"message": "OTP sent to your email."}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# VERIFY FORGOT PASSWORD OTP
# ------------------------------------------------------------------------------
class VerifyForgotPasswordOTPView(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    @swagger_auto_schema(
        operation_summary="Verify Forgot Password OTP",
        operation_description="Verify the OTP sent to your email for Forgot password.",
        tags=['Authentication'],
        request_body=VerifyForgotPasswordOTPSerializer,
        responses={
            200: openapi.Response(
                description="OTP verified successfully",
                examples={
                    "application/json": {
                        "message": "OTP verified successfully. You can now reset your password."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request - Invalid or expired OTP",
                examples={
                    "application/json": {
                        "error": "Invalid OTP"
                    }
                }
            ),
            404: openapi.Response(
                description="Password reset request not found",
                examples={
                    "application/json": {
                        "error": "Password reset request not found."
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = VerifyForgotPasswordOTPSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        otp = serializer.validated_data["otp"]
        
        forgot_request = ForgotPasswordRequest.objects.filter(email=email).first()
        if not forgot_request:
            return Response({"error": "Password reset request not found."}, status=status.HTTP_404_NOT_FOUND)
        
        ok, msg = forgot_request.verify_otp(otp)
        if not ok:
            return Response({"error": msg}, status=status.HTTP_400_BAD_REQUEST)
        
        return Response({"message": "OTP verified successfully. You can now reset your password."}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# SET NEW PASSWORD (FORGOT PASSWORD)
# ------------------------------------------------------------------------------
class SetNewPasswordAPI(APIView):
    permission_classes = [AllowAny]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Set new password (Forgot Password)",
        operation_description="Set a new password after verifying the OTP sent to your email. This endpoint is specifically for the forgot password flow.",
        tags=['Authentication'],
        request_body=SetNewPasswordSerializer,
        responses={
            200: openapi.Response(
                description="Password set successfully",
                examples={
                    "application/json": {
                        "message": "Password has been reset successfully."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request",
                examples={
                    "application/json": {
                        "error": "No password reset request found. Please request a new OTP."
                    }
                }
            ),
            404: openapi.Response(
                description="User not found",
                examples={
                    "application/json": {
                        "error": "User with this email does not exist."
                    }
                }
            )
        }
    )
    def post(self, request):
        serializer = SetNewPasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        new_password = serializer.validated_data["new_password"]
        
        forgot_request = ForgotPasswordRequest.objects.filter(email=email).first()
        if not forgot_request:
            return Response({"error": "No password reset request found. Please request a new OTP."}, status=status.HTTP_400_BAD_REQUEST)

        if not forgot_request.otp:
            return Response({"error": "Please verify your OTP first."}, status=status.HTTP_400_BAD_REQUEST)
        
        User = get_user_model()
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({"error": "User with this email does not exist."}, status=status.HTTP_404_NOT_FOUND)
        
        user.set_password(new_password)
        user.save()
        
        forgot_request.delete()
        
        return Response({"message": "Password has been reset successfully."}, status=status.HTTP_200_OK)


# ------------------------------------------------------------------------------
# RESET PASSWORD
# ------------------------------------------------------------------------------
class ResetPasswordAPI(APIView):
    permission_classes = [IsAuthenticated]
    parser_classes = [JSONParser, MultiPartParser, FormParser]
    
    @swagger_auto_schema(
        operation_summary="Reset password",
        operation_description="Reset your password after logging in. Requires new_password and confirm_password fields.",
        tags=['Authentication'],
        request_body=ResetPasswordSerializer,
        responses={
            200: openapi.Response(
                description="Password changed successfully",
                examples={
                    "application/json": {
                        "message": "Password changed successfully."
                    }
                }
            ),
            400: openapi.Response(
                description="Bad Request",
                examples={
                    "application/json": {
                        "error": "Passwords do not match."
                    }
                }
            ),
            401: "Unauthorized - Authentication required"
        }
    )
    def post(self, request):
        serializer = ResetPasswordSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
        
        email = serializer.validated_data["email"]
        new_password = serializer.validated_data["new_password"]
        
        User = get_user_model()
        user = User.objects.filter(email=email).first()
        if not user:
            return Response({"error": "User with this email does not exist."}, status=status.HTTP_404_NOT_FOUND)
        
        user.set_password(new_password)
        user.save()
        
        return Response({"message": "Password changed successfully."}, status=status.HTTP_200_OK)



# ------------------------------------------------------------------------------
# SOCIAL AUTHENTICATION GOOGLE
# ------------------------------------------------------------------------------
class GoogleLogin(SocialLoginView):
    adapter_class = GoogleOAuth2Adapter
    client_class = OAuth2Client


# ------------------------------------------------------------------------------
# SOCIAL AUTHENTICATION APPLE
# ------------------------------------------------------------------------------
class AppleLogin(SocialLoginView):
    adapter_class = AppleOAuth2Adapter
    client_class = AppleOAuth2Client
