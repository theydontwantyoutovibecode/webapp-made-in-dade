from datetime import datetime

from django.shortcuts import render
from django.views.decorators.vary import vary_on_headers


@vary_on_headers("HX-Request")
def home(request):
    """Home page view with HTMX support."""
    base_template = "_partial.html" if request.htmx else "base.html"
    return render(request, "core/home.html", {"base_template": base_template})


def htmx_demo(request):
    """Demo endpoint for testing HTMX functionality."""
    return render(
        request,
        "core/htmx_demo.html",
        {"timestamp": datetime.now().isoformat()},
    )
