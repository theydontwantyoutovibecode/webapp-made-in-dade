#!/usr/bin/env bash
# ==============================================================================
# Django HTMX Starter - Application Startup Script
# ==============================================================================
# Usage:
#   ./start.sh              # Start in production mode
#   ./start.sh --dev        # Start in development mode with hot-reload
#   ./start.sh --port 8001  # Start on specific port
#   ./start.sh --help       # Show help message
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_NAME="${PROJECT_NAME:-Django HTMX Starter}"
DEV_MODE=false
HOST="${HOST:-0.0.0.0}"
PORT_FLAG=""
WORKERS="${WORKERS:-4}"
PORT_SEARCH_RANGE=100

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

get_default_port() {
    if [[ -n "${PORT:-}" ]]; then
        echo "$PORT"
        return
    fi
    if [[ -f "$SCRIPT_DIR/.dade" ]]; then
        local marker_port
        marker_port=$(grep -o '"port":[[:space:]]*[0-9]*' "$SCRIPT_DIR/.dade" 2>/dev/null | grep -o '[0-9]*' || echo "")
        if [[ -n "$marker_port" ]]; then
            echo "$marker_port"
            return
        fi
    fi
    echo "8000"
}

PORT="$(get_default_port)"

log_info() { echo -e "${BLUE}INFO${NC}  $1"; }
log_warn() { echo -e "${YELLOW}WARN${NC}  $1"; }
log_error() { echo -e "${RED}ERROR${NC} $1"; }
log_success() { echo -e "${GREEN}✓ $1${NC}"; }
log_debug() { echo -e "${CYAN}DEBUG${NC} $1"; }

is_interactive() { [[ -t 1 ]] && [[ -t 0 ]]; }

print_header() {
    echo ""
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║              ${PROJECT_NAME}${NC}"
    echo -e "${MAGENTA}║            Django + HTMX Application                     ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

is_port_available() {
    local port="$1"
    if [[ ! "$port" =~ ^[0-9]+$ ]] || [[ "$port" -lt 1 ]] || [[ "$port" -gt 65535 ]]; then
        return 1
    fi
    if command -v python3 &>/dev/null; then
        python3 -c "
import socket
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
try:
    s.bind(('127.0.0.1', $port))
    s.close()
    exit(0)
except OSError:
    exit(1)
" 2>/dev/null
        return $?
    fi
    if command -v lsof &>/dev/null; then
        if lsof -i ":$port" -sTCP:LISTEN &>/dev/null; then
            return 1
        fi
        return 0
    fi
    return 0
}

find_available_port() {
    local start_port="$1"
    local max_attempts="${2:-$PORT_SEARCH_RANGE}"
    local port="$start_port"
    local attempts=0
    while [[ $attempts -lt $max_attempts ]]; do
        if is_port_available "$port"; then
            echo "$port"
            return 0
        fi
        ((port++))
        ((attempts++))
    done
    return 1
}

update_dade_port() {
    local new_port="$1"
    if ! command -v dade &>/dev/null; then return 0; fi
    if [[ ! -f "$SCRIPT_DIR/.dade" ]]; then return 0; fi
    log_info "Updating dade port to $new_port..."
    if dade project port --set "$new_port" 2>/dev/null; then
        log_success "Caddy proxy updated to port $new_port"
    else
        log_warn "Could not update Caddy proxy (dade project port command failed)"
    fi
}

load_env_file() {
    if [[ -f "$SCRIPT_DIR/.env" ]]; then
        set -a
        source "$SCRIPT_DIR/.env"
        set +a
    fi
}

needs_setup() {
    if [[ ! -f "$SCRIPT_DIR/.env" ]]; then return 0; fi
    local secret_key
    secret_key=$(grep -E "^DJANGO_SECRET_KEY=" "$SCRIPT_DIR/.env" 2>/dev/null | cut -d'=' -f2- | tr -d "'" || echo "")
    if [[ -z "$secret_key" ]]; then return 0; fi
    return 1
}

check_uv() {
    if ! command -v uv &>/dev/null; then
        log_error "uv is not installed."
        log_info "Install: curl -LsSf https://astral.sh/uv/install.sh | sh"
        exit 1
    fi
}

check_python_deps() {
    log_info "Checking Python dependencies..."
    cd "$SCRIPT_DIR"
    if [[ "$DEV_MODE" == true ]]; then
        uv sync --dev
    else
        uv sync --extra prod
    fi
    log_success "Dependencies installed"
}

check_development_env() {
    if needs_setup; then
        log_error "Project not configured. Run ./setup.sh first."
        exit 1
    fi
    load_env_file
    if [[ -z "${DJANGO_SECRET_KEY:-}" ]]; then
        log_error "DJANGO_SECRET_KEY not set. Run ./setup.sh to configure."
        exit 1
    fi
}

check_production_env() {
    local missing_vars=()
    if [[ -z "${DJANGO_SECRET_KEY:-}" ]]; then missing_vars+=("DJANGO_SECRET_KEY"); fi
    if [[ -z "${DJANGO_ALLOWED_HOSTS:-}" ]]; then missing_vars+=("DJANGO_ALLOWED_HOSTS"); fi
    if [[ ${#missing_vars[@]} -gt 0 ]]; then
        log_error "Missing required environment variables for production:"
        for var in "${missing_vars[@]}"; do
            echo -e "  ${RED}• $var${NC}"
        done
        exit 1
    fi
    log_success "Production environment variables validated"
}

run_migrations() {
    log_info "Checking database migrations..."
    cd "$SCRIPT_DIR"
    local pending
    pending=$(uv run python manage.py showmigrations --plan 2>/dev/null | grep -c '\[ \]' || true)
    if [[ "$pending" -gt 0 ]]; then
        log_warn "Found $pending pending migration(s)"
        uv run python manage.py migrate --no-input
        log_success "Migrations applied"
    else
        log_success "Database is up to date"
    fi
}

collect_static() {
    if [[ "$DEV_MODE" == false ]]; then
        log_info "Collecting static files..."
        cd "$SCRIPT_DIR"
        uv run python manage.py collectstatic --no-input --clear
        log_success "Static files collected"
    fi
}

show_server_info() {
    local mode="$1" host="$2" port="$3"
    local project_name="" dade_url=""
    if [[ -f "$SCRIPT_DIR/.dade" ]]; then
        project_name=$(grep -o '"name":[[:space:]]*"[^"]*"' "$SCRIPT_DIR/.dade" 2>/dev/null | sed 's/.*"\([^"]*\)"$/\1/' || echo "")
        if [[ -n "$project_name" ]]; then
            local hostname_short
            hostname_short=$(hostname | cut -d. -f1 | tr '[:upper:]' '[:lower:]')
            dade_url="https://${project_name}.${hostname_short}.local"
        fi
    fi
    echo ""
    echo -e "${MAGENTA}┌─────────────────────────────────────┐${NC}"
    echo -e "${MAGENTA}│${NC} ${CYAN}Server Information${NC}                  ${MAGENTA}│${NC}"
    echo -e "${MAGENTA}├─────────────────────────────────────┤${NC}"
    echo -e "${MAGENTA}│${NC} Mode: ${YELLOW}$mode${NC}"
    echo -e "${MAGENTA}│${NC} Host: ${CYAN}$host${NC}"
    echo -e "${MAGENTA}│${NC} Port: ${CYAN}$port${NC}"
    if [[ -n "$dade_url" ]]; then
        echo -e "${MAGENTA}│${NC}"
        echo -e "${MAGENTA}│${NC} URL:  ${CYAN}$dade_url${NC}"
    else
        echo -e "${MAGENTA}│${NC} URL:  ${CYAN}http://$host:$port/${NC}"
    fi
    echo -e "${MAGENTA}└─────────────────────────────────────┘${NC}"
}

show_help() {
    echo ""
    echo -e "${MAGENTA}Usage${NC}"
    echo ""
    echo "  ./start.sh              Start in production mode"
    echo "  ./start.sh --dev        Start in development mode"
    echo "  ./start.sh --port 8001  Start on specific port"
    echo "  ./start.sh --help       Show this help message"
    echo ""
    echo -e "${MAGENTA}Environment Variables${NC}"
    echo ""
    echo "  HOST     Server host (default: 0.0.0.0)"
    echo "  PORT     Server port (default: 8000)"
    echo "  WORKERS  Gunicorn workers (default: 4, prod only)"
}

start_development_server() {
    show_server_info "development" "127.0.0.1" "$PORT"
    echo ""
    echo -e "${CYAN}Press Ctrl+C to stop the server${NC}"
    echo ""
    cd "$SCRIPT_DIR"
    export DJANGO_SETTINGS_MODULE=config.settings.development
    exec uv run python manage.py runserver "127.0.0.1:$PORT"
}

start_production_server() {
    show_server_info "production" "$HOST" "$PORT"
    echo ""
    echo -e "${CYAN}Press Ctrl+C to stop the server${NC}"
    echo ""
    cd "$SCRIPT_DIR"
    export DJANGO_SETTINGS_MODULE=config.settings.production
    exec uv run gunicorn config.wsgi:application \
        --bind "$HOST:$PORT" \
        --workers "$WORKERS" \
        --access-logfile - \
        --error-logfile -
}

main() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dev) DEV_MODE=true; shift ;;
            --port|-p)
                if [[ -z "${2:-}" ]] || [[ "$2" =~ ^- ]]; then
                    log_error "--port requires a port number"; exit 1
                fi
                PORT_FLAG="$2"; PORT="$2"; shift 2 ;;
            --help|-h) print_header; show_help; exit 0 ;;
            *) log_error "Unknown option: $1"; show_help; exit 1 ;;
        esac
    done

    print_header

    if [[ "$DEV_MODE" == true ]]; then
        echo -e "${YELLOW}🔧 DEVELOPMENT MODE${NC}"
    else
        echo -e "${GREEN}🚀 PRODUCTION MODE${NC}"
    fi
    echo ""

    load_env_file

    if [[ "$DEV_MODE" == true ]] && [[ -z "$PORT_FLAG" ]]; then
        if ! is_port_available "$PORT"; then
            log_warn "Port $PORT is already in use"
            local new_port
            if new_port=$(find_available_port "$PORT"); then
                log_info "Auto-selected port $new_port"
                PORT="$new_port"
                update_dade_port "$new_port"
            else
                log_error "No available port found in range $PORT-$((PORT + PORT_SEARCH_RANGE))"
                exit 1
            fi
        fi
    fi

    check_uv
    check_python_deps

    if [[ "$DEV_MODE" == true ]]; then
        check_development_env
    else
        check_production_env
    fi

    run_migrations
    collect_static

    if [[ "$DEV_MODE" == true ]]; then
        start_development_server
    else
        start_production_server
    fi
}

main "$@"
