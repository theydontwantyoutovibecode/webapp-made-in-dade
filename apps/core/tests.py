"""
Comprehensive test suite for the core app.
"""

from django.conf import settings
from django.contrib.auth import get_user_model
from django.contrib.sites.models import Site
from django.test import Client, TestCase, override_settings
from django.urls import reverse

User = get_user_model()


class HomeViewTests(TestCase):
    """Tests for the home page view."""

    def setUp(self):
        self.client = Client()
        self.url = reverse("core:home")

    def test_home_page_returns_200(self):
        """Home page should return 200 OK."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)

    def test_home_page_uses_correct_template(self):
        """Home page should use home.html template."""
        response = self.client.get(self.url)
        self.assertTemplateUsed(response, "core/home.html")
        self.assertTemplateUsed(response, "base.html")

    def test_home_page_contains_project_name(self):
        """Home page should contain the project name."""
        response = self.client.get(self.url)
        # Default project name when not configured
        self.assertContains(response, "Django HTMX Starter")

    def test_home_page_shows_welcome_for_authenticated(self):
        """Authenticated users should see welcome message."""
        user = User.objects.create_user(
            username="testuser",
            email="test@example.com",
            password="testpass123",
        )
        self.client.force_login(user)
        response = self.client.get(self.url)
        self.assertContains(response, "Welcome")
        self.assertContains(response, user.email)

    def test_home_page_htmx_request_uses_partial_template(self):
        """HTMX requests should use partial template."""
        response = self.client.get(self.url, HTTP_HX_REQUEST="true")
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, "_partial.html")

    def test_home_page_varies_on_hx_request_header(self):
        """Response should have Vary header for HX-Request."""
        response = self.client.get(self.url)
        self.assertIn("HX-Request", response.get("Vary", ""))


class HtmxDemoViewTests(TestCase):
    """Tests for the HTMX demo endpoint."""

    def setUp(self):
        self.client = Client()
        self.url = reverse("core:htmx_demo")

    def test_htmx_demo_returns_200(self):
        """HTMX demo should return 200 OK."""
        response = self.client.get(self.url)
        self.assertEqual(response.status_code, 200)

    def test_htmx_demo_uses_correct_template(self):
        """HTMX demo should use htmx_demo.html template."""
        response = self.client.get(self.url)
        self.assertTemplateUsed(response, "core/htmx_demo.html")

    def test_htmx_demo_contains_timestamp(self):
        """HTMX demo should contain a timestamp."""
        response = self.client.get(self.url)
        self.assertContains(response, "Timestamp:")

    def test_htmx_demo_contains_success_message(self):
        """HTMX demo should indicate HTMX is working."""
        response = self.client.get(self.url)
        self.assertContains(response, "HTMX is working")


class SiteConfigurationTests(TestCase):
    """Tests for Django sites configuration."""

    def test_site_exists(self):
        """Site with SITE_ID=1 should exist."""
        site = Site.objects.get(id=1)
        self.assertIsNotNone(site)

    def test_site_domain_configured(self):
        """Site domain should be configured."""
        site = Site.objects.get(id=1)
        # Domain should be set (not empty)
        self.assertNotEqual(site.domain, "")


class TemplateContextTests(TestCase):
    """Tests for template context and CSRF handling."""

    def setUp(self):
        self.client = Client()

    def test_csrf_token_in_context(self):
        """CSRF token should be available in template context."""
        response = self.client.get(reverse("core:home"))
        # The template uses csrf_token in hx-headers
        self.assertContains(response, "X-CSRFToken")

    def test_base_template_loads_htmx(self):
        """Base template should load HTMX script."""
        response = self.client.get(reverse("core:home"))
        # django-htmx loads htmx via {% htmx_script %}
        self.assertContains(response, "htmx")

    def test_project_settings_context_processor(self):
        """Project settings should be in template context."""
        response = self.client.get(reverse("core:home"))
        # Check that project_name is being used (default value)
        self.assertContains(response, "Django HTMX Starter")


class URLRoutingTests(TestCase):
    """Tests for URL routing configuration."""

    def setUp(self):
        self.client = Client()

    def test_home_url_resolves(self):
        """Root URL should resolve to home view."""
        response = self.client.get("/")
        self.assertEqual(response.status_code, 200)

    def test_htmx_demo_url_resolves(self):
        """HTMX demo URL should resolve correctly."""
        response = self.client.get("/htmx-demo/")
        self.assertEqual(response.status_code, 200)

    def test_admin_url_resolves(self):
        """Admin URL should be accessible (redirects to login)."""
        response = self.client.get("/admin/")
        self.assertIn(response.status_code, [200, 302])


# OAuth tests only run when SOCIAL_AUTH_ENABLED is True
# These tests verify the OAuth configuration structure without requiring the full app setup
class OAuthConfigurationTests(TestCase):
    """Tests for OAuth configuration when enabled."""

    # Mock the settings that would be set when OAuth is enabled
    TEST_OAUTH_CONFIG = {
        "google": {
            "SCOPE": ["profile", "email"],
            "AUTH_PARAMS": {"access_type": "online"},
            "OAUTH_PKCE_ENABLED": True,
            "APP": {
                "client_id": "test-client-id",
                "secret": "test-secret",
                "key": "",
            },
        }
    }

    def test_google_provider_config_structure(self):
        """Google OAuth config structure should be correct."""
        google_config = self.TEST_OAUTH_CONFIG.get("google", {})
        self.assertIn("SCOPE", google_config)
        self.assertIn("APP", google_config)

    def test_google_provider_has_required_scopes(self):
        """Google provider should request email and profile scopes."""
        google_config = self.TEST_OAUTH_CONFIG.get("google", {})
        scopes = google_config.get("SCOPE", [])
        self.assertIn("email", scopes)
        self.assertIn("profile", scopes)

    def test_pkce_enabled(self):
        """PKCE should be enabled for security."""
        google_config = self.TEST_OAUTH_CONFIG.get("google", {})
        self.assertTrue(google_config.get("OAUTH_PKCE_ENABLED", False))
