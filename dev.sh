#!/bin/bash
# Personal Website Development Script
# Manages local development environment for backend and frontend

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$PROJECT_DIR/backend"
FRONTEND_DIR="$PROJECT_DIR/frontend"
PID_DIR="$PROJECT_DIR/.dev"
BACKEND_PID_FILE="$PID_DIR/backend.pid"
FRONTEND_PID_FILE="$PID_DIR/frontend.pid"
LOG_DIR="$PROJECT_DIR/.dev/logs"

# Development environment variables
export DATABASE_URL="sqlite:///tmp/dev-blog.db"
export UPLOAD_DIR="/tmp/dev-photos"
export RUST_LOG="info"

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_debug() {
    echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Setup function - Prepare development environment
setup() {
    log_info "Setting up development environment..."

    # Create directories
    mkdir -p "$PID_DIR" "$LOG_DIR" "$UPLOAD_DIR"

    # Check Rust installation
    if ! command -v cargo &> /dev/null; then
        log_error "Rust/Cargo not found. Please install from https://rustup.rs/"
        exit 1
    else
        log_info "Rust version: $(rustc --version)"
    fi

    # Check Node installation
    if ! command -v npm &> /dev/null; then
        log_error "Node.js/npm not found. Please install Node.js"
        exit 1
    else
        log_info "Node version: $(node --version)"
        log_info "npm version: $(npm --version)"
    fi

    # Install frontend dependencies
    log_info "Installing frontend dependencies..."
    cd "$FRONTEND_DIR"
    npm install

    # Install cargo-watch for auto-reload (optional)
    if ! command -v cargo-watch &> /dev/null; then
        log_warn "cargo-watch not found. Install it for auto-reload functionality:"
        echo "  cargo install cargo-watch"
    fi

    log_info "Development environment setup complete!"
    echo ""
    log_info "Run './dev.sh start' to start the development servers"
}

# Start development servers
start() {
    log_info "Starting development servers..."

    # Check if already running
    if is_running; then
        log_warn "Development servers are already running"
        status
        exit 0
    fi

    # Start backend
    log_info "Starting backend on http://localhost:8080..."
    cd "$BACKEND_DIR"

    if command -v cargo-watch &> /dev/null; then
        log_debug "Using cargo-watch for auto-reload"
        cargo watch -x run >> "$LOG_DIR/backend.log" 2>&1 &
    else
        cargo run >> "$LOG_DIR/backend.log" 2>&1 &
    fi

    BACKEND_PID=$!
    echo $BACKEND_PID > "$BACKEND_PID_FILE"
    log_info "Backend started (PID: $BACKEND_PID)"

    # Wait a moment for backend to start
    sleep 2

    # Start frontend
    log_info "Starting frontend on http://localhost:5173..."
    cd "$FRONTEND_DIR"
    npm run dev >> "$LOG_DIR/frontend.log" 2>&1 &
    FRONTEND_PID=$!
    echo $FRONTEND_PID > "$FRONTEND_PID_FILE"
    log_info "Frontend started (PID: $FRONTEND_PID)"

    echo ""
    log_info "Development servers started successfully!"
    echo ""
    echo -e "${GREEN}Backend:${NC}  http://localhost:8080"
    echo -e "${GREEN}Frontend:${NC} http://localhost:5173"
    echo ""
    log_info "View logs with: ./dev.sh logs [backend|frontend]"
    log_info "Stop servers with: ./dev.sh stop"
}

# Stop development servers
stop() {
    log_info "Stopping development servers..."

    STOPPED=0

    # Stop backend
    if [ -f "$BACKEND_PID_FILE" ]; then
        BACKEND_PID=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$BACKEND_PID" 2>/dev/null; then
            log_info "Stopping backend (PID: $BACKEND_PID)..."
            kill "$BACKEND_PID" 2>/dev/null || true
            # Also kill any child processes (cargo-watch spawns children)
            pkill -P "$BACKEND_PID" 2>/dev/null || true
            STOPPED=1
        fi
        rm -f "$BACKEND_PID_FILE"
    fi

    # Stop frontend
    if [ -f "$FRONTEND_PID_FILE" ]; then
        FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$FRONTEND_PID" 2>/dev/null; then
            log_info "Stopping frontend (PID: $FRONTEND_PID)..."
            kill "$FRONTEND_PID" 2>/dev/null || true
            pkill -P "$FRONTEND_PID" 2>/dev/null || true
            STOPPED=1
        fi
        rm -f "$FRONTEND_PID_FILE"
    fi

    if [ $STOPPED -eq 0 ]; then
        log_warn "No running development servers found"
    else
        log_info "Development servers stopped"
    fi
}

# Restart development servers
restart() {
    log_info "Restarting development servers..."
    stop
    sleep 2
    start
}

# Check if servers are running
is_running() {
    RUNNING=0

    if [ -f "$BACKEND_PID_FILE" ]; then
        BACKEND_PID=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$BACKEND_PID" 2>/dev/null; then
            RUNNING=1
        fi
    fi

    if [ -f "$FRONTEND_PID_FILE" ]; then
        FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$FRONTEND_PID" 2>/dev/null; then
            RUNNING=1
        fi
    fi

    return $((1 - RUNNING))
}

# Show status
status() {
    log_info "Development server status..."
    echo ""

    # Backend status
    echo -e "${GREEN}=== Backend ===${NC}"
    if [ -f "$BACKEND_PID_FILE" ]; then
        BACKEND_PID=$(cat "$BACKEND_PID_FILE")
        if kill -0 "$BACKEND_PID" 2>/dev/null; then
            echo -e "Status: ${GREEN}Running${NC} (PID: $BACKEND_PID)"
            echo "URL: http://localhost:8080"
        else
            echo -e "Status: ${RED}Stopped${NC}"
        fi
    else
        echo -e "Status: ${RED}Stopped${NC}"
    fi

    # Frontend status
    echo ""
    echo -e "${GREEN}=== Frontend ===${NC}"
    if [ -f "$FRONTEND_PID_FILE" ]; then
        FRONTEND_PID=$(cat "$FRONTEND_PID_FILE")
        if kill -0 "$FRONTEND_PID" 2>/dev/null; then
            echo -e "Status: ${GREEN}Running${NC} (PID: $FRONTEND_PID)"
            echo "URL: http://localhost:5173"
        else
            echo -e "Status: ${RED}Stopped${NC}"
        fi
    else
        echo -e "Status: ${RED}Stopped${NC}"
    fi

    # Environment
    echo ""
    echo -e "${GREEN}=== Environment ===${NC}"
    echo "Database: $DATABASE_URL"
    echo "Upload Dir: $UPLOAD_DIR"
    if [ -f "/tmp/dev-blog.db" ]; then
        echo "DB Size: $(du -h /tmp/dev-blog.db | cut -f1)"
    fi
}

# View logs
logs() {
    if [ ! -d "$LOG_DIR" ]; then
        log_error "Log directory not found. Have you started the servers?"
        exit 1
    fi

    case "$1" in
        backend)
            log_info "Showing backend logs (Ctrl+C to exit)..."
            tail -f "$LOG_DIR/backend.log"
            ;;
        frontend)
            log_info "Showing frontend logs (Ctrl+C to exit)..."
            tail -f "$LOG_DIR/frontend.log"
            ;;
        *)
            log_info "Showing all logs (Ctrl+C to exit)..."
            tail -f "$LOG_DIR/backend.log" "$LOG_DIR/frontend.log"
            ;;
    esac
}

# Clean development artifacts
clean() {
    log_info "Cleaning development artifacts..."

    # Stop servers first
    stop

    # Clean backend
    if [ -d "$BACKEND_DIR/target" ]; then
        log_info "Cleaning Rust build artifacts..."
        cd "$BACKEND_DIR"
        cargo clean
    fi

    # Clean frontend
    if [ -d "$FRONTEND_DIR/node_modules" ]; then
        log_warn "Removing node_modules (run 'setup' to reinstall)..."
        rm -rf "$FRONTEND_DIR/node_modules"
    fi

    if [ -d "$FRONTEND_DIR/dist" ]; then
        log_info "Removing frontend build..."
        rm -rf "$FRONTEND_DIR/dist"
    fi

    # Clean dev files
    log_info "Cleaning dev files..."
    rm -rf "$PID_DIR" "$LOG_DIR"
    rm -f /tmp/dev-blog.db
    rm -rf "$UPLOAD_DIR"

    log_info "Clean complete!"
}

# Reset database
reset_db() {
    log_warn "This will delete the development database!"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log_info "Removing database..."
        rm -f /tmp/dev-blog.db
        rm -rf "$UPLOAD_DIR"/*
        log_info "Database reset. Restart the backend to recreate."
    else
        log_info "Cancelled"
    fi
}

# Show usage
usage() {
    cat << EOF
Personal Website Development Script

Usage: $0 [command]

Commands:
    setup       Setup development environment (install dependencies)
    start       Start backend and frontend development servers
    stop        Stop development servers
    restart     Restart development servers
    status      Show development server status
    logs        View logs (use 'backend' or 'frontend' for specific service)
    clean       Clean all development artifacts and dependencies
    reset-db    Reset development database
    help        Show this help message

Examples:
    $0 setup                # First time setup
    $0 start                # Start dev servers
    $0 logs backend         # View backend logs
    $0 status               # Check server status
    $0 stop                 # Stop servers
    $0 reset-db             # Reset database

Development URLs:
    Backend:  http://localhost:8080
    Frontend: http://localhost:5173

EOF
}

# Main script
case "$1" in
    setup)
        setup
        ;;
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
        ;;
    clean)
        clean
        ;;
    reset-db)
        reset_db
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
