"""
Context processors for the core app.
"""

import os

from django.conf import settings


def project_settings(request):
    """
    Add project-wide settings to template context.
    """
    return {
        "project_name": os.environ.get("PROJECT_NAME", "Django HTMX Starter"),
        "social_auth_enabled": getattr(settings, "SOCIAL_AUTH_ENABLED", False),
    }
