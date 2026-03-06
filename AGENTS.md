# AGENTS.md — Web App Template

## Stack

- **Python 3.12+** with **uv** for dependency management
- **Django 5.x** — full-stack web framework
- **HTMX** — declarative AJAX for interactive UIs
- **SQLite** — default database (PostgreSQL for production)
- **Caddy** — HTTPS reverse proxy via dade

## Project Structure

```
.
├── config/                 # Django settings (development.py, production.py)
├── apps/                   # Django applications
│   └── <app>/
│       ├── models.py
│       ├── views.py
│       ├── urls.py
│       └── templates/<app>/
├── templates/              # Global templates (base.html, partials/)
├── static/                 # Static assets
├── start.sh                # Dev server launcher
├── .read-only/             # Reference libraries (auto-synced, do not edit)
│   └── manifest.txt
└── .tickets/               # Ticket tracking (tk CLI)
```

## Development Workflow

All work is **ticket-driven**. Never start implementation without a ticket.

### Planning Phase

1. Receive a request → analyze fully before acting
2. Create granular tickets with `tk`:
   ```
   tk create "Add user profile page with avatar upload" -t task -p 1 --tags "feature" -d "Definition of done: profile view with form, avatar stored in media/, HTMX partial updates, tests for view and model"
   ```
3. Each ticket must have: definition of done, caveats, test coverage plan
4. Surface open questions before implementation

### Execution Phase

- **One ticket = one commit.** Never work on multiple tickets simultaneously.
- `tk start <id>` → implement → verify → `tk close <id>` → commit
- Run tests after every change: `uv run python manage.py test`
- Run migrations when models change: `uv run python manage.py makemigrations && uv run python manage.py migrate`

### Reference Libraries

The `.read-only/` directory contains reference implementations. Use for context — never modify.

## Stack Notes

- Django views return HTML fragments for HTMX requests (check `request.headers.get('HX-Request')`)
- Use `{% include "partials/..." %}` for reusable HTMX fragments
- Vanilla CSS with native layers, custom properties, and container queries — no build step
- Settings split: `config/settings/development.py` (DEBUG=True, SQLite) and `config/settings/production.py` (DEBUG=False, PostgreSQL)
- URL patterns use `path()` with named URLs; use `{% url 'name' %}` in templates
- Static files: `{% load static %}` → `{% static 'path' %}`
- `uv sync --dev` installs all dev dependencies; `uv run` executes within the venv
