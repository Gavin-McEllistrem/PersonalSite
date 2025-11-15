#!/bin/bash
# Personal Website Deployment Script
# Handles setup, updates, backups, and monitoring for the VM

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
PROJECT_DIR="/home/$USER/Master/Personal Website"
DATA_DIR="/var/lib/personal-website"
BACKUP_DIR="$HOME/backups/personal-website"
COMPOSE_FILE="docker-compose.prod.yml"

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

# Setup function - First time VM setup
setup() {
    log_info "Starting initial VM setup..."

    # Update system
    log_info "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y

    # Install Docker
    if ! command -v docker &> /dev/null; then
        log_info "Installing Docker..."
        sudo apt install -y docker.io docker-compose
        sudo systemctl enable docker
        sudo systemctl start docker
        sudo usermod -aG docker $USER
        log_warn "Docker installed. You may need to log out and back in for group changes to take effect."
    else
        log_info "Docker already installed"
    fi

    # Create data directories
    log_info "Creating data directories..."
    sudo mkdir -p "$DATA_DIR/photos"
    sudo chown -R $USER:$USER "$DATA_DIR"

    # Create backup directory
    mkdir -p "$BACKUP_DIR"

    # Configure firewall
    if command -v ufw &> /dev/null; then
        log_info "Configuring firewall..."
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        log_info "Opened ports 80 and 443"
    fi

    log_info "Setup complete! Run './deploy.sh deploy' to deploy the application."
}

# Deploy/Update function
deploy() {
    log_info "Deploying application..."

    cd "$PROJECT_DIR"

    # Pull latest changes if git repo
    if [ -d .git ] || [ -f .git ]; then
        log_info "Pulling latest changes from git..."
        git pull
    fi

    # Stop existing containers
    log_info "Stopping existing containers..."
    docker-compose -f "$COMPOSE_FILE" down

    # Build and start containers
    log_info "Building and starting containers..."
    docker-compose -f "$COMPOSE_FILE" up -d --build

    # Wait for containers to be healthy
    sleep 5

    # Check status
    log_info "Checking container status..."
    docker-compose -f "$COMPOSE_FILE" ps

    log_info "Deployment complete!"
}

# Backup function
backup() {
    log_info "Creating backup..."

    TIMESTAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_PATH="$BACKUP_DIR/backup_$TIMESTAMP"

    mkdir -p "$BACKUP_PATH"

    # Backup database
    if [ -f "$DATA_DIR/blog.db" ]; then
        log_info "Backing up database..."
        cp "$DATA_DIR/blog.db" "$BACKUP_PATH/blog.db"
    else
        log_warn "Database not found at $DATA_DIR/blog.db"
    fi

    # Backup photos
    if [ -d "$DATA_DIR/photos" ]; then
        log_info "Backing up photos..."
        cp -r "$DATA_DIR/photos" "$BACKUP_PATH/"
        PHOTO_COUNT=$(ls -1 "$DATA_DIR/photos" 2>/dev/null | wc -l)
        log_info "Backed up $PHOTO_COUNT photos"
    else
        log_warn "Photos directory not found at $DATA_DIR/photos"
    fi

    # Create archive
    log_info "Creating compressed archive..."
    cd "$BACKUP_DIR"
    tar -czf "backup_$TIMESTAMP.tar.gz" "backup_$TIMESTAMP"
    rm -rf "backup_$TIMESTAMP"

    log_info "Backup complete: $BACKUP_DIR/backup_$TIMESTAMP.tar.gz"

    # Clean old backups (keep last 10)
    log_info "Cleaning old backups (keeping last 10)..."
    ls -t "$BACKUP_DIR"/backup_*.tar.gz | tail -n +11 | xargs -r rm
}

# Restore function
restore() {
    if [ -z "$1" ]; then
        log_error "Please specify backup file to restore"
        log_info "Available backups:"
        ls -lh "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null || echo "No backups found"
        exit 1
    fi

    BACKUP_FILE="$1"

    if [ ! -f "$BACKUP_FILE" ]; then
        log_error "Backup file not found: $BACKUP_FILE"
        exit 1
    fi

    log_warn "This will overwrite existing data. Press Ctrl+C to cancel, or Enter to continue..."
    read

    log_info "Stopping containers..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" down

    log_info "Extracting backup..."
    TEMP_DIR=$(mktemp -d)
    tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

    # Restore database
    if [ -f "$TEMP_DIR"/backup_*/blog.db ]; then
        log_info "Restoring database..."
        cp "$TEMP_DIR"/backup_*/blog.db "$DATA_DIR/"
    fi

    # Restore photos
    if [ -d "$TEMP_DIR"/backup_*/photos ]; then
        log_info "Restoring photos..."
        rm -rf "$DATA_DIR/photos"
        cp -r "$TEMP_DIR"/backup_*/photos "$DATA_DIR/"
    fi

    rm -rf "$TEMP_DIR"

    log_info "Starting containers..."
    docker-compose -f "$COMPOSE_FILE" up -d

    log_info "Restore complete!"
}

# Status/Health check
status() {
    log_info "Checking application status..."

    cd "$PROJECT_DIR"

    echo -e "\n${GREEN}=== Container Status ===${NC}"
    docker-compose -f "$COMPOSE_FILE" ps

    echo -e "\n${GREEN}=== Disk Usage ===${NC}"
    df -h "$DATA_DIR" 2>/dev/null || df -h /

    echo -e "\n${GREEN}=== Data Directory ===${NC}"
    if [ -d "$DATA_DIR" ]; then
        echo "Database: $(ls -lh "$DATA_DIR/blog.db" 2>/dev/null | awk '{print $5}' || echo 'Not found')"
        echo "Photos: $(ls -1 "$DATA_DIR/photos" 2>/dev/null | wc -l) files"
        echo "Photos size: $(du -sh "$DATA_DIR/photos" 2>/dev/null | awk '{print $1}' || echo 'Not found')"
    else
        log_warn "Data directory not found"
    fi

    echo -e "\n${GREEN}=== Recent Backups ===${NC}"
    ls -lht "$BACKUP_DIR"/backup_*.tar.gz 2>/dev/null | head -5 || echo "No backups found"

    echo -e "\n${GREEN}=== Container Health ===${NC}"
    docker ps --filter "name=personal-website" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
}

# Logs function
logs() {
    cd "$PROJECT_DIR"

    if [ "$1" == "backend" ]; then
        docker logs -f personal-website-backend
    elif [ "$1" == "frontend" ]; then
        docker logs -f personal-website-frontend
    else
        docker-compose -f "$COMPOSE_FILE" logs -f
    fi
}

# Stop function
stop() {
    log_info "Stopping application..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" down
    log_info "Application stopped"
}

# Start function
start() {
    log_info "Starting application..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" up -d
    log_info "Application started"
}

# Restart function
restart() {
    log_info "Restarting application..."
    cd "$PROJECT_DIR"
    docker-compose -f "$COMPOSE_FILE" restart
    log_info "Application restarted"
}

# Show usage
usage() {
    cat << EOF
Personal Website Deployment Script

Usage: $0 [command]

Commands:
    setup       Initial VM setup (install Docker, create directories, configure firewall)
    deploy      Deploy or update the application (git pull, rebuild, restart)
    backup      Create a backup of database and photos
    restore     Restore from a backup file
    status      Show application status and health
    logs        View application logs (use 'backend' or 'frontend' for specific service)
    start       Start the application
    stop        Stop the application
    restart     Restart the application
    help        Show this help message

Examples:
    $0 setup                                    # First time setup
    $0 deploy                                   # Deploy/update application
    $0 backup                                   # Create backup
    $0 restore ~/backups/backup_20231115.tar.gz # Restore from backup
    $0 logs backend                             # View backend logs
    $0 status                                   # Check status

EOF
}

# Main script
case "$1" in
    setup)
        setup
        ;;
    deploy)
        deploy
        ;;
    backup)
        backup
        ;;
    restore)
        restore "$2"
        ;;
    status)
        status
        ;;
    logs)
        logs "$2"
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
    help|--help|-h)
        usage
        ;;
    *)
        usage
        exit 1
        ;;
esac
