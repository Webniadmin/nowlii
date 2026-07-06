from .models import CustomUserModel, Profile, NowliiPredefinedOption
from django.contrib.auth import get_user_model
from django.core.files.base import ContentFile
from django.core.files.storage import default_storage
from rest_framework import serializers


class GoogleLoginSerializer(serializers.Serializer):
    """Accepts the Google ``id_token`` (a JWT) returned by the client Sign-In SDK."""
    id_token = serializers.CharField()


class AppleLoginSerializer(serializers.Serializer):
    """Accepts the Apple ``identity_token`` (a JWT) from Sign in with Apple.
    ``full_name``/``email`` are optional — Apple only returns those on the FIRST sign-in,
    so the client passes them through then (the token itself usually carries the email)."""
    identity_token = serializers.CharField()
    full_name = serializers.CharField(required=False, allow_blank=True, allow_null=True)
    email = serializers.EmailField(required=False, allow_blank=True, allow_null=True)


class NormalizedChoiceField(serializers.ChoiceField):
    def to_internal_value(self, data):
        if isinstance(data, str):
            data = data.replace('’', "'").strip()
        return super().to_internal_value(data)


class URLOrUploadedFileField(serializers.Field):
    def to_internal_value(self, data):
        if data is None or data == "":
            return None

        if hasattr(data, 'read'):
            # Save to storage and return only the storage KEY (relative path),
            # NOT the full URL. The model's ImageField stores the key; the URL
            # is built on read via .url — avoiding double-URL encoding.
            storage_key = default_storage.save(
                f'profile_images/{data.name}',
                ContentFile(data.read())
            )
            return storage_key  # e.g. "profile_images/avatar.png"

        if isinstance(data, str):
            # Accept a plain URL / relative path sent by client (no re-upload)
            return data.strip() or None

        raise serializers.ValidationError('Invalid value for profile_image.')

    def to_representation(self, value):
        if not value:
            return None

        # ImageFieldFile — ask storage for the URL
        if hasattr(value, 'url'):
            try:
                return value.url   # S3Boto3Storage returns a full HTTPS URL
            except ValueError:
                return None

        value_str = str(value)

        # Already a full URL (e.g. previously stored URL string)
        if value_str.startswith(('http://', 'https://')):
            return value_str

        # Relative path — try to build via storage first, then fall back to request
        try:
            return default_storage.url(value_str)
        except Exception:
            pass

        request = self.context.get('request')
        if request:
            return request.build_absolute_uri(value_str)

        return value_str


# ------------------------------------------------------------------------------
# NOWLII PREDEFINED OPTIONS
# ------------------------------------------------------------------------------
class NowliiPredefinedOptionSerializer(serializers.ModelSerializer):
    class Meta:
        model = NowliiPredefinedOption
        fields = '__all__'
        extra_kwargs = {
            'name': {'help_text': "The unique name of the Nowlii character"},
            'avatar_logo': {'help_text': "The avatar image logo"}
        }


# ------------------------------------------------------------------------------
# PROFILE
# ------------------------------------------------------------------------------
class ProfileSerializer(serializers.ModelSerializer):
    profile_image = URLOrUploadedFileField(required=False, allow_null=True)
    gender = NormalizedChoiceField(choices=Profile.GENDER_CHOICES, required=False, allow_null=True, allow_blank=True)
    
    # Predefined option can be expanded or just ID
    predefined_option_detail = NowliiPredefinedOptionSerializer(source='predefined_option', read_only=True)

    class Meta:
        model = Profile
        fields = '__all__'
        read_only_fields = ['user', 'avatar_logo', 'nowlii_name']


# ------------------------------------------------------------------------------
# REGISTRATION
# ------------------------------------------------------------------------------
class RegisterSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="User's email address"
    )
    username = serializers.CharField(
        required=False,
        allow_blank=True,
        max_length=150,
        help_text="Optional username (if not provided, will be generated from email)"
    )
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="User's password"
    )

    def validate_email(self, value):
        """Validate that email is not already registered"""
        User = get_user_model()
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError("User with this email already exists.")
        return value


# ------------------------------------------------------------------------------
# VERIFY REGISTRATION OTP
# ------------------------------------------------------------------------------
class VerifyOTPSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="Email address used during registration"
    )
    otp = serializers.CharField(
        required=True,
        max_length=6,
        min_length=6,
        help_text="6-digit OTP code sent to your email"
    )


# ------------------------------------------------------------------------------
# RESEND REGISTRATION OTP
# ------------------------------------------------------------------------------
class ResendOTPSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="Email address used during registration"
    )


# ------------------------------------------------------------------------------
# LOGIN
# ------------------------------------------------------------------------------
class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="User's email address"
    )
    password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="User's password"
    )


# ------------------------------------------------------------------------------
# LOGOUT
# ------------------------------------------------------------------------------
class LogoutSerializer(serializers.Serializer):
    refresh_token = serializers.CharField(
        required=True,
        help_text="JWT refresh token to blacklist"
    )


# ------------------------------------------------------------------------------
# FORGOT PASSWORD
# ------------------------------------------------------------------------------
class ForgotPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="User's email address"
    )


# ------------------------------------------------------------------------------
# VERIFY FORGOT PASSWORD OTP
# ------------------------------------------------------------------------------
class VerifyForgotPasswordOTPSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="Email address used during forgot password request"
    )
    otp = serializers.CharField(
        required=True,
        max_length=6,
        min_length=6,
        help_text="6-digit OTP code sent to your email"
    )


# ------------------------------------------------------------------------------
# SET NEW PASSWORD (FORGOT PASSWORD)
# ------------------------------------------------------------------------------
class SetNewPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="User's email address"
    )
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="New password for your account"
    )
    confirm_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="Confirm your new password"
    )

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data


# ------------------------------------------------------------------------------
# RESET PASSWORD
# ------------------------------------------------------------------------------
class ResetPasswordSerializer(serializers.Serializer):
    email = serializers.EmailField(
        required=True,
        help_text="User's email address"
    )
    new_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="New password for your account"
    )
    confirm_password = serializers.CharField(
        required=True,
        write_only=True,
        style={'input_type': 'password'},
        help_text="Confirm your new password"
    )

    def validate(self, data):
        if data['new_password'] != data['confirm_password']:
            raise serializers.ValidationError({"confirm_password": "Passwords do not match."})
        return data


