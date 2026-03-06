"""
URL configuration for django-htmx-starter project.
"""

from django.conf import settings
from django.contrib import admin
from django.urls import include, path

urlpatterns = [
    path("admin/", admin.site.urls),
    path("", include("apps.core.urls")),
]

# Add allauth URLs if social auth is enabled
if getattr(settings, "SOCIAL_AUTH_ENABLED", False):
    urlpatterns.insert(1, path("accounts/", include("allauth.urls")))

# Add debug toolbar URLs in development
if settings.DEBUG:
    try:
        import debug_toolbar

        urlpatterns = [
            path("__debug__/", include(debug_toolbar.urls)),
        ] + urlpatterns
    except ImportError:
        pass
