#!/usr/bin/env bash
# ==============================================================================
# Django + HTMX Template - Project Setup Script
# ==============================================================================
# One-time setup script for configuring a new project from this template.
# Run this after cloning/copying the template to configure your project.
#
# Usage:
#   ./setup.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}INFO${NC}  $1"; }
log_warn() { echo -e "${YELLOW}WARN${NC}  $1"; }
log_error() { echo -e "${RED}ERROR${NC} $1"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }

is_interactive() { [[ -t 1 ]] && [[ -t 0 ]]; }

print_header() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║                    ${BOLD}Project Setup${NC}${MAGENTA}                      ║${NC}"
    echo -e "${MAGENTA}║              Django + HTMX Template                      ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

generate_secret_key() {
    if command -v python3 &>/dev/null; then
        python3 -c "import secrets; print(secrets.token_urlsafe(50))"
        return
    fi
    if command -v uv &>/dev/null && [[ -f "$SCRIPT_DIR/pyproject.toml" ]]; then
        uv run python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())" 2>/dev/null && return
    fi
    if command -v openssl &>/dev/null; then
        openssl rand -base64 50 | tr -d '\n'
        return
    fi
    log_error "Cannot generate secret key. Install Python 3 or OpenSSL."
    exit 1
}

setup_env() {
    local env_file="$SCRIPT_DIR/.env"

    if [[ ! -f "$env_file" ]]; then
        if [[ -f "$SCRIPT_DIR/.env.example" ]]; then
            cp "$SCRIPT_DIR/.env.example" "$env_file"
            log_info "Created .env from template"
        else
            touch "$env_file"
            log_info "Created empty .env file"
        fi
    fi

    local current_name
    current_name=$(grep -E "^PROJECT_NAME=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d "'" || echo "My Django Project")
    current_name="${current_name:-My Django Project}"

    local project_name
    read -rp "Project Name [$current_name]: " project_name
    project_name="${project_name:-$current_name}"

    if grep -q "^PROJECT_NAME=" "$env_file"; then
        sed -i.bak "s|^PROJECT_NAME=.*|PROJECT_NAME='$project_name'|" "$env_file"
    else
        echo "PROJECT_NAME='$project_name'" >> "$env_file"
    fi

    local current_secret
    current_secret=$(grep -E "^DJANGO_SECRET_KEY=" "$env_file" 2>/dev/null | cut -d'=' -f2- | tr -d "'" || echo "")

    if [[ -z "$current_secret" || "$current_secret" == "''" || "$current_secret" == '""' ]]; then
        log_info "Generating Django secret key..."
        local secret_key
        secret_key=$(generate_secret_key)
        if grep -q "^DJANGO_SECRET_KEY=" "$env_file"; then
            local escaped_key
            escaped_key=$(printf '%s' "$secret_key" | sed 's/[&/\]/\\&/g')
            sed -i.bak "s|^DJANGO_SECRET_KEY=.*|DJANGO_SECRET_KEY='$escaped_key'|" "$env_file"
        else
            echo "DJANGO_SECRET_KEY='$secret_key'" >> "$env_file"
        fi
        log_success "Secret key generated"
    else
        log_info "Secret key already configured"
    fi

    local enable_oauth
    read -rp "Enable Google OAuth? (y/N): " yn
    if [[ "$yn" =~ ^[Yy]$ ]]; then
        enable_oauth="true"
    else
        enable_oauth="false"
    fi

    if grep -q "^ENABLE_SOCIAL_AUTH=" "$env_file"; then
        sed -i.bak "s|^ENABLE_SOCIAL_AUTH=.*|ENABLE_SOCIAL_AUTH=$enable_oauth|" "$env_file"
    else
        echo "ENABLE_SOCIAL_AUTH=$enable_oauth" >> "$env_file"
    fi

    if [[ "$enable_oauth" == "true" ]]; then
        echo ""
        log_info "Google OAuth requires credentials from Google Cloud Console"
        log_info "Visit: https://console.developers.google.com/apis/credentials"
        echo ""
        local client_id client_secret
        read -rp "Google Client ID: " client_id
        read -rsp "Google Client Secret: " client_secret
        echo ""

        if grep -q "^GOOGLE_CLIENT_ID=" "$env_file"; then
            sed -i.bak "s|^GOOGLE_CLIENT_ID=.*|GOOGLE_CLIENT_ID=$client_id|" "$env_file"
        else
            echo "GOOGLE_CLIENT_ID=$client_id" >> "$env_file"
        fi
        if grep -q "^GOOGLE_CLIENT_SECRET=" "$env_file"; then
            sed -i.bak "s|^GOOGLE_CLIENT_SECRET=.*|GOOGLE_CLIENT_SECRET=$client_secret|" "$env_file"
        else
            echo "GOOGLE_CLIENT_SECRET=$client_secret" >> "$env_file"
        fi
    fi

    rm -f "$env_file.bak"
    echo ""
    log_success "Configuration saved to .env"
}

show_next_steps() {
    echo ""
    echo -e "${MAGENTA}Setup complete! Next steps:${NC}"
    echo ""
    echo "  Start the development server:"
    echo -e "     ${YELLOW}dade dev${NC}"
    echo ""
    echo -e "${CYAN}Tip: Run dade dev --open to also open in your browser${NC}"
    echo ""
}

main() {
    print_header

    if ! is_interactive; then
        log_error "Setup requires an interactive terminal."
        log_info "If running in CI, create .env manually from .env.example"
        exit 1
    fi

    echo ""
    echo -e "${MAGENTA}🔧 Project Configuration${NC}"
    echo ""

    setup_env
    show_next_steps
}

main "$@"
