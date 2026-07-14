from datetime import timedelta
from pathlib import Path
import dotenv
import os


# ------------------------------------------------------------------------------
# ENV
# ------------------------------------------------------------------------------
BASE_DIR = Path(__file__).resolve().parent.parent

dotenv.load_dotenv(BASE_DIR / ".env")

DEBUG = os.getenv("DEBUG", "False").lower() == "true"

SECRET_KEY = os.getenv(
    "SECRET_KEY",
    "django-insecure-change-this-in-production"
)

# Comma-separated list of allowed hosts, e.g.
# ALLOWED_HOSTS=api.example.com,16.170.191.239
ALLOWED_HOSTS = [h.strip() for h in os.getenv("ALLOWED_HOSTS", "").split(",") if h.strip()]
if DEBUG and not ALLOWED_HOSTS:
    ALLOWED_HOSTS = ["localhost", "127.0.0.1"]

SECURE_PROXY_SSL_HEADER = ("HTTP_X_FORWARDED_PROTO", "https")

# ------------------------------------------------------------------------------
# Environment Variables
# ------------------------------------------------------------------------------


# ------------------------------------------------------------------------------
# APPLICATIONS
# ------------------------------------------------------------------------------
DJANGO_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
]
THIRD_PARTY_APPS = [
    "rest_framework",
    "rest_framework.authtoken",
    "rest_framework_simplejwt",
    "rest_framework_simplejwt.token_blacklist",
    "drf_yasg",
    "corsheaders",

    "allauth",
    "allauth.account",
    "allauth.socialaccount",
    "allauth.socialaccount.providers.google",
    "allauth.socialaccount.providers.apple",

]

LOCAL_APPS = [
    "Apps.users",
    "Apps.quests",
    "Apps.subtask_generator",
    "Apps.insights",
    "Apps.support",
    "Apps.voice_calls",
    "Apps.subscriptions",
]

INSTALLED_APPS = DJANGO_APPS + THIRD_PARTY_APPS + LOCAL_APPS

SITE_ID = 1

# ------------------------------------------------------------------------------
# MIDDLEWARE
# ------------------------------------------------------------------------------
MIDDLEWARE = [
    'django.middleware.security.SecurityMiddleware',
    'whitenoise.middleware.WhiteNoiseMiddleware',
    "corsheaders.middleware.CorsMiddleware",
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
    "allauth.account.middleware.AccountMiddleware",
    "django_otp.middleware.OTPMiddleware",
]

# Set CORS_ALLOW_ALL_ORIGINS=True only for local development. In production leave it
# unset (defaults to False) and list explicit origins in CORS_ALLOWED_ORIGINS.
CORS_ALLOW_ALL_ORIGINS = os.getenv("CORS_ALLOW_ALL_ORIGINS", "False").lower() == "true"
CORS_ALLOW_CREDENTIALS = True
CORS_EXPOSE_HEADERS = [
    'Content-Type',
    'X-CSRFToken',
    'Authorization',
]

# Comma-separated list of allowed origins, e.g.
# CORS_ALLOWED_ORIGINS=http://localhost:3000,https://app.example.com
CORS_ALLOWED_ORIGINS = [
    o.strip() for o in os.getenv("CORS_ALLOWED_ORIGINS", "").split(",") if o.strip()
]

# CSRF Configuration for API — comma-separated list of trusted origins, e.g.
# CSRF_TRUSTED_ORIGINS=https://*.ngrok-free.dev,http://16.170.191.239:8000
CSRF_TRUSTED_ORIGINS = [
    o.strip() for o in os.getenv("CSRF_TRUSTED_ORIGINS", "").split(",") if o.strip()
]



# ------------------------------------------------------------------------------
# URL / ASGI / WSGI
# ------------------------------------------------------------------------------
ROOT_URLCONF = 'core.urls'

WSGI_APPLICATION = 'core.wsgi.application'

# ------------------------------------------------------------------------------
# TEMPLATES
# ------------------------------------------------------------------------------
TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]


# ------------------------------------------------------------------------------
# DATABASE (PostgreSQL Ready)
# ------------------------------------------------------------------------------

# Use SQLite by default or if specified, otherwise use the provided engine
DB_ENGINE = os.getenv('DB_ENGINE', 'django.db.backends.sqlite3')

DATABASES = {
    'default': {
        'ENGINE': DB_ENGINE,
        'NAME': os.getenv('DB_NAME', BASE_DIR / 'db.sqlite3'),
    }
}

# Add additional configuration for non-SQLite databases
if DB_ENGINE != 'django.db.backends.sqlite3':
    DATABASES['default'].update({
        'USER': os.getenv('DB_USER'),
        'PASSWORD': os.getenv('DB_PASSWORD'),
        'HOST': os.getenv('DB_HOST'),
        'PORT': os.getenv('DB_PORT'),
    })



# ------------------------------------------------------------------------------
# PASSWORD VALIDATION
# ------------------------------------------------------------------------------
AUTH_PASSWORD_VALIDATORS = [
    {
        'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator',
    },
    {
        'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator',
    },
]


# ------------------------------------------------------------------------------
# INTERNATIONALIZATION
# ------------------------------------------------------------------------------
LANGUAGE_CODE = 'en-us'

TIME_ZONE = 'UTC'

USE_I18N = True

USE_TZ = True


# ------------------------------------------------------------------------------
# STATIC & MEDIA (S3 READY)
# ------------------------------------------------------------------------------
STATIC_URL = 'static/'
STATIC_ROOT = BASE_DIR / 'staticfiles'

STORAGES = {
    "staticfiles": {
        "BACKEND": "whitenoise.storage.CompressedManifestStaticFilesStorage",
    },
}

# AWS S3 Media Configuration
MEDIA_ROOT = BASE_DIR / 'media'
AWS_ACCESS_KEY_ID = os.getenv('AWS_ACCESS_KEY_ID')

if AWS_ACCESS_KEY_ID:
    AWS_SECRET_ACCESS_KEY = os.getenv('AWS_SECRET_ACCESS_KEY')
    AWS_STORAGE_BUCKET_NAME = os.getenv('AWS_STORAGE_BUCKET_NAME')
    AWS_S3_SIGNATURE_NAME = os.getenv('AWS_S3_SIGNATURE_NAME', 's3v4')
    AWS_S3_REGION_NAME = os.getenv('AWS_S3_REGION_NAME', 'eu-north-1')
    AWS_S3_FILE_OVERWRITE = os.getenv('AWS_S3_FILE_OVERWRITE', 'False') == 'True'
    AWS_DEFAULT_ACL = None  # Bucket has ACLs disabled (BucketOwnerEnforced)
    AWS_S3_VERIFY = os.getenv('AWS_S3_VERITY', 'True') == 'True'
    
    # Ensure URLs are clean (no ?X-Amz-Signature) and use the exact region domain
    AWS_QUERYSTRING_AUTH = False
    AWS_S3_CUSTOM_DOMAIN = f"{AWS_STORAGE_BUCKET_NAME}.s3.{AWS_S3_REGION_NAME}.amazonaws.com"
    
    # Use S3 for media storage (Django 4.2+ format)
    STORAGES["default"] = {
        "BACKEND": "storages.backends.s3boto3.S3Boto3Storage",
    }
    
    # For generated media URLs
    MEDIA_URL = f"https://{AWS_S3_CUSTOM_DOMAIN}/"
else:
    # Local fallback
    STORAGES["default"] = {
        "BACKEND": "django.core.files.storage.FileSystemStorage",
    }
    MEDIA_URL = '/media/'



# ------------------------------------------------------------------------------
# DJANGO REST FRAMEWORK & JWT
# ------------------------------------------------------------------------------
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': (
        'rest_framework_simplejwt.authentication.JWTAuthentication',
        'rest_framework.authentication.TokenAuthentication',
    ),
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.AllowAny',
    ],
    'DATETIME_FORMAT': "%d-%m-%Y %H:%M:%S",
    'EXCEPTION_HANDLER': 'core.exceptions.custom_exception_handler',
}

SIMPLE_JWT = {
    "ACCESS_TOKEN_LIFETIME": timedelta(days=31),
    "REFRESH_TOKEN_LIFETIME": timedelta(days=31),
    "ROTATE_REFRESH_TOKENS": True,
    "BLACKLIST_AFTER_ROTATION": True,
    "AUTH_HEADER_TYPES": ("Bearer",),
}

ACCOUNT_UNIQUE_EMAIL = True
ACCOUNT_USERNAME_VALIDATORS = None
ACCOUNT_USER_MODEL_USERNAME_FIELD = None
REST_USE_JWT = True


# ------------------------------------------------------------------------------
# AUTH / ALLAUTH
# ------------------------------------------------------------------------------
AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
    "allauth.account.auth_backends.AuthenticationBackend",
]

ACCOUNT_LOGIN_METHODS = {'email'}
ACCOUNT_SIGNUP_FIELDS = ['email*', 'password1*', 'password2*']
ACCOUNT_EMAIL_VERIFICATION = "mandatory"


# ------------------------------------------------------------------------------
# Email
# ------------------------------------------------------------------------------
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = os.getenv("EMAIL_HOST", "smtp.gmail.com")
EMAIL_PORT = int(os.getenv("EMAIL_PORT", "587"))
EMAIL_USE_TLS = os.getenv("EMAIL_USE_TLS", "True").lower() == "true"
EMAIL_USE_SSL = os.getenv("EMAIL_USE_SSL", "False").lower() == "true"
EMAIL_HOST_USER = os.getenv("EMAIL_HOST_USER")
EMAIL_HOST_PASSWORD = os.getenv("EMAIL_HOST_PASSWORD", "").replace(" ", "")
# Sender shown to users (defaults to the SMTP login). Set a friendly form via env, e.g.
# DEFAULT_FROM_EMAIL="NOWLII <noreply@yourdomain.com>"
DEFAULT_FROM_EMAIL = os.getenv("DEFAULT_FROM_EMAIL") or EMAIL_HOST_USER
# Address users write to for help (support). Defaults to the sender if unset.
SUPPORT_EMAIL = os.getenv("SUPPORT_EMAIL") or DEFAULT_FROM_EMAIL


# ------------------------------------------------------------------------------
# AI voice calls
# ------------------------------------------------------------------------------
# Max AI voice calls a single user may start per day. Per-user (never global) and
# env-overridable so it is not a hardcoded magic number. Enforced server-side in
# Apps.voice_calls — the frontend is never the authority for this limit.
VOICE_CALL_DAILY_LIMIT = int(os.getenv("VOICE_CALL_DAILY_LIMIT", "2"))


# ------------------------------------------------------------------------------
# Google OAuth credentials 
# ------------------------------------------------------------------------------
SOCIALACCOUNT_PROVIDERS = {
    "google": {
        "APP": {
            "client_id": os.getenv("SOCIAL_AUTH_GOOGLE_CLIENT_ID"),  
            "secret": os.getenv("SOCIAL_AUTH_GOOGLE_SECRET"), 
        },
    },
}

SOCIALACCOUNT_LOGIN_ON_GET = True

LOGIN_REDIRECT_URL = "/"
SOCIAL_AUTH_GOOGLE_OAUTH2_CALLBACK_URL = os.getenv(
    "SOCIAL_AUTH_GOOGLE_OAUTH2_CALLBACK_URL",
    "http://127.0.0.1:8000/accounts/google/login/callback/",
)

SOCIAL_AUTH_GOOGLE_OAUTH2_SCOPE = ["openid", "profile", "email"]

# Client ID the custom /api/auth/google/ endpoint uses to verify Google `id_token`s.
# For a mobile/web client, this must be the SAME client id the app passes as
# `serverClientId` to the Google Sign-In SDK (so the id_token `aud` matches).
GOOGLE_OAUTH_CLIENT_ID = os.getenv("SOCIAL_AUTH_GOOGLE_CLIENT_ID")


# ------------------------------------------------------------------------------
# Apple Sign-In  (fill these in later to enable /api/auth/apple/)
# ------------------------------------------------------------------------------
# Allowed audiences for the Apple identity token — the iOS **bundle id** (e.g.
# com.nowlii.app) and/or the web/Android **Service ID**. Comma-separated.
# Empty = Apple login is disabled (the endpoint returns 503 "not configured").
APPLE_CLIENT_IDS = [c.strip() for c in os.getenv("APPLE_CLIENT_IDS", "").split(",") if c.strip()]
# Only needed later for the server-side auth-code exchange / token revoke — NOT for
# basic sign-in (the identity token is verified with Apple's PUBLIC keys, no secret).
APPLE_TEAM_ID = os.getenv("APPLE_TEAM_ID", "")
APPLE_KEY_ID = os.getenv("APPLE_KEY_ID", "")
APPLE_PRIVATE_KEY = os.getenv("APPLE_PRIVATE_KEY", "")



# ------------------------------------------------------------------------------
# Swagger API Documentation
# ------------------------------------------------------------------------------
SWAGGER_SETTINGS = {
    'SECURITY_DEFINITIONS': {
        'Bearer': {
            'type': 'apiKey',
            'name': 'Authorization',
            'in': 'header',
            'description': 'JWT Authorization header using the Bearer scheme. Example: Bearer <token>',
        }
    },
    'USE_SESSION_AUTH': False,
}


# ------------------------------------------------------------------------------
# Anthropic API Key
# ------------------------------------------------------------------------------
ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", default=None)
OPENAI_API_KEY    = os.getenv("OPENAI_API_KEY", default=None)
GOOGLE_AI_API_KEY = os.getenv("GOOGLE_AI_API_KEY", default=None)