"""
Django base settings for django-htmx-starter project.

Settings common to all environments.
"""

import os
from pathlib import Path

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent.parent


# ==============================================================================
# Social Authentication Configuration
# ==============================================================================

# Check if social auth is enabled via environment variable
SOCIAL_AUTH_ENABLED = os.environ.get("ENABLE_SOCIAL_AUTH", "false").lower() == "true"


# ==============================================================================
# Application definition
# ==============================================================================

INSTALLED_APPS = [
    # Django core
    "django.contrib.admin",
    "django.contrib.auth",
    "django.contrib.contenttypes",
    "django.contrib.sessions",
    "django.contrib.messages",
    "django.contrib.staticfiles",
    "django.contrib.sites",
    # Third-party
    "django_htmx",
    # Local apps
    "apps.core",
]

# Add allauth apps if social auth is enabled
if SOCIAL_AUTH_ENABLED:
    INSTALLED_APPS += [
        "allauth",
        "allauth.account",
        "allauth.socialaccount",
        "allauth.socialaccount.providers.google",
    ]

MIDDLEWARE = [
    "django.middleware.security.SecurityMiddleware",
    "django.contrib.sessions.middleware.SessionMiddleware",
    "django.middleware.common.CommonMiddleware",
    "django.middleware.csrf.CsrfViewMiddleware",
    "django.contrib.auth.middleware.AuthenticationMiddleware",
    "django.contrib.messages.middleware.MessageMiddleware",
    "django.middleware.clickjacking.XFrameOptionsMiddleware",
    "django_htmx.middleware.HtmxMiddleware",
]

# Add allauth middleware if social auth is enabled
if SOCIAL_AUTH_ENABLED:
    MIDDLEWARE.insert(-1, "allauth.account.middleware.AccountMiddleware")

ROOT_URLCONF = "config.urls"

TEMPLATES = [
    {
        "BACKEND": "django.template.backends.django.DjangoTemplates",
        "DIRS": [BASE_DIR / "templates"],
        "APP_DIRS": True,
        "OPTIONS": {
            "context_processors": [
                "django.template.context_processors.request",
                "django.contrib.auth.context_processors.auth",
                "django.contrib.messages.context_processors.messages",
                "apps.core.context_processors.project_settings",
            ],
        },
    },
]

WSGI_APPLICATION = "config.wsgi.application"


# ==============================================================================
# Database
# https://docs.djangoproject.com/en/5.x/ref/settings/#databases
# ==============================================================================

DATABASES = {
    "default": {
        "ENGINE": "django.db.backends.sqlite3",
        "NAME": BASE_DIR / "db.sqlite3",
    }
}


# ==============================================================================
# Password validation
# https://docs.djangoproject.com/en/5.x/ref/settings/#auth-password-validators
# ==============================================================================

AUTH_PASSWORD_VALIDATORS = [
    {
        "NAME": "django.contrib.auth.password_validation.UserAttributeSimilarityValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.MinimumLengthValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.CommonPasswordValidator",
    },
    {
        "NAME": "django.contrib.auth.password_validation.NumericPasswordValidator",
    },
]


# ==============================================================================
# Internationalization
# https://docs.djangoproject.com/en/5.x/topics/i18n/
# ==============================================================================

LANGUAGE_CODE = "en-us"

TIME_ZONE = "UTC"

USE_I18N = True

USE_TZ = True


# ==============================================================================
# Static files (CSS, JavaScript, Images)
# https://docs.djangoproject.com/en/5.x/howto/static-files/
# ==============================================================================

STATIC_URL = "static/"

STATICFILES_DIRS = [
    BASE_DIR / "static",
]

STATIC_ROOT = BASE_DIR / "staticfiles"


# ==============================================================================
# Default primary key field type
# https://docs.djangoproject.com/en/5.x/ref/settings/#default-auto-field
# ==============================================================================

DEFAULT_AUTO_FIELD = "django.db.models.BigAutoField"


# ==============================================================================
# Authentication
# ==============================================================================

AUTHENTICATION_BACKENDS = [
    "django.contrib.auth.backends.ModelBackend",
]

# Add allauth backend if social auth is enabled
if SOCIAL_AUTH_ENABLED:
    AUTHENTICATION_BACKENDS.append("allauth.account.auth_backends.AuthenticationBackend")


# ==============================================================================
# django-allauth settings (only used if SOCIAL_AUTH_ENABLED)
# ==============================================================================

SITE_ID = 1

# Redirect URLs
LOGIN_REDIRECT_URL = "/"
LOGOUT_REDIRECT_URL = "/"

if SOCIAL_AUTH_ENABLED:
    # Use email as the primary identifier (allauth 65.x)
    ACCOUNT_LOGIN_METHODS = {"email"}
    ACCOUNT_SIGNUP_FIELDS = ["email*", "password1*", "password2*"]
    ACCOUNT_EMAIL_VERIFICATION = "none"

    # Social account settings
    SOCIALACCOUNT_PROVIDERS = {
        "google": {
            "SCOPE": ["profile", "email"],
            "AUTH_PARAMS": {"access_type": "online"},
            "OAUTH_PKCE_ENABLED": True,
            "APP": {
                "client_id": os.environ.get("GOOGLE_CLIENT_ID", ""),
                "secret": os.environ.get("GOOGLE_CLIENT_SECRET", ""),
                "key": "",
            },
        }
    }

    # Only allow login via social accounts (Google)
    SOCIALACCOUNT_ONLY = True

    # Skip the intermediate "Continue with Google?" page
    SOCIALACCOUNT_LOGIN_ON_GET = True
