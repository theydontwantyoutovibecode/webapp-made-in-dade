"""
Django production settings for django-htmx-starter project.
"""

import os

from .base import *  # noqa: F401, F403

# Secret key from environment (required in production)
SECRET_KEY = os.environ.get("DJANGO_SECRET_KEY")

# Debug mode off in production
DEBUG = False

ALLOWED_HOSTS = os.environ.get("DJANGO_ALLOWED_HOSTS", "").split(",")

# Security settings
SECURE_BROWSER_XSS_FILTER = True
SECURE_CONTENT_TYPE_NOSNIFF = True
X_FRAME_OPTIONS = "DENY"
SECURE_SSL_REDIRECT = True
SESSION_COOKIE_SECURE = True
CSRF_COOKIE_SECURE = True
SECURE_HSTS_SECONDS = 31536000
SECURE_HSTS_INCLUDE_SUBDOMAINS = True
SECURE_HSTS_PRELOAD = True

# For django-allauth in production, require HTTPS (if enabled)
if SOCIAL_AUTH_ENABLED:  # noqa: F405
    ACCOUNT_DEFAULT_HTTP_PROTOCOL = "https"
