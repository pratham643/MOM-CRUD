#!/bin/bash

################################################################################
# Production Deployment Script
# Handles zero-downtime deployment with comprehensive error handling
# Usage: ./deploy.sh [environment]
# Example: ./deploy.sh production
################################################################################

set -euo pipefail

# ============================================================================
# CONFIGURATION
# ============================================================================
ENVIRONMENT=${1:-production}
APP_DIR="/var/www/html/mom-crud"
BACKUP_DIR="/var/backups/mom-crud"
LOG_DIR="/var/log/deployments"
LOG_FILE="${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log"
CURRENT_VERSION_FILE="${APP_DIR}/.current-version"
FAILED=0

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

log() {
    local level=$1
    shift
    local message="$@"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${BLUE}[${timestamp}] [${level}]${NC} ${message}" | tee -a "${LOG_FILE}"
}

success() {
    echo -e "${GREEN}✓ $@${NC}" | tee -a "${LOG_FILE}"
}

error() {
    echo -e "${RED}✗ $@${NC}" | tee -a "${LOG_FILE}"
    FAILED=$((FAILED + 1))
}

warning() {
    echo -e "${YELLOW}⚠ $@${NC}" | tee -a "${LOG_FILE}"
}

# Create log directory
mkdir -p "${LOG_DIR}"
mkdir -p "${BACKUP_DIR}"

log "INFO" "========================================================================"
log "INFO" "Starting ${ENVIRONMENT} Deployment"
log "INFO" "========================================================================"

# ============================================================================
# PRE-DEPLOYMENT CHECKS
# ============================================================================

log "INFO" "Performing pre-deployment checks..."

# Check if app directory exists
if [ ! -d "${APP_DIR}" ]; then
    error "Application directory ${APP_DIR} does not exist"
    exit 1
fi

# Check if PHP is available
if ! command -v php &> /dev/null; then
    error "PHP is not installed"
    exit 1
fi

# Check if Composer is available
if ! command -v composer &> /dev/null; then
    error "Composer is not installed"
    exit 1
fi

# Check database connectivity
log "INFO" "Checking database connectivity..."
if ! php artisan db:ping 2>/dev/null; then
    error "Cannot connect to database"
    exit 1
fi

success "Pre-deployment checks passed"

# ============================================================================
# BACKUP CURRENT APPLICATION
# ============================================================================

log "INFO" "Creating backup..."

BACKUP_FILE="${BACKUP_DIR}/backup-$(date +%Y%m%d-%H%M%S).tar.gz"

if [ -d "${APP_DIR}" ]; then
    tar -czf "${BACKUP_FILE}" \
        --exclude='.git' \
        --exclude='storage/logs' \
        --exclude='storage/framework/sessions' \
        --exclude='storage/framework/cache' \
        --exclude='storage/framework/views' \
        --exclude='node_modules' \
        --exclude='bootstrap/cache' \
        "${APP_DIR}" 2>/dev/null || {
        error "Failed to create backup"
        exit 1
    }
    success "Backup created: ${BACKUP_FILE}"
    
    # Keep only last 10 backups
    ls -t "${BACKUP_DIR}"/backup-*.tar.gz 2>/dev/null | tail -n +11 | xargs -r rm
else
    warning "Application directory not found, skipping backup"
fi

# ============================================================================
# ENABLE MAINTENANCE MODE
# ============================================================================

log "INFO" "Enabling maintenance mode..."

cd "${APP_DIR}"

# Create maintenance mode file
php artisan down --render="errors::503" 2>/dev/null || true

success "Maintenance mode enabled"

# ============================================================================
# PULL LATEST CODE
# ============================================================================

log "INFO" "Pulling latest code..."

if ! git fetch origin --quiet 2>/dev/null; then
    error "Failed to fetch from origin"
    php artisan up 2>/dev/null || true
    exit 1
fi

case "${ENVIRONMENT}" in
    production)
        BRANCH="main"
        ;;
    staging)
        BRANCH="develop"
        ;;
    *)
        error "Unknown environment: ${ENVIRONMENT}"
        php artisan up 2>/dev/null || true
        exit 1
        ;;
esac

if ! git checkout --quiet "${BRANCH}" 2>/dev/null; then
    error "Failed to checkout branch ${BRANCH}"
    php artisan up 2>/dev/null || true
    exit 1
fi

if ! git reset --hard "origin/${BRANCH}" --quiet 2>/dev/null; then
    error "Failed to pull latest changes"
    php artisan up 2>/dev/null || true
    exit 1
fi

CURRENT_COMMIT=$(git rev-parse HEAD)
success "Latest code pulled (commit: ${CURRENT_COMMIT:0:7})"

# ============================================================================
# INSTALL DEPENDENCIES
# ============================================================================

log "INFO" "Installing dependencies..."

if [ "${ENVIRONMENT}" = "production" ]; then
    if ! composer install --no-dev --no-progress --no-interaction --prefer-dist --optimize-autoloader --classmap-authoritative 2>/dev/null; then
        error "Composer install failed"
        git reset --hard HEAD~1 --quiet 2>/dev/null || true
        php artisan up 2>/dev/null || true
        exit 1
    fi
else
    if ! composer install --no-progress --no-interaction --prefer-dist 2>/dev/null; then
        error "Composer install failed"
        git reset --hard HEAD~1 --quiet 2>/dev/null || true
        php artisan up 2>/dev/null || true
        exit 1
    fi
fi

success "Dependencies installed"

# ============================================================================
# INSTALL FRONTEND DEPENDENCIES
# ============================================================================

log "INFO" "Building frontend assets..."

if command -v npm &> /dev/null; then
    if npm ci --production 2>/dev/null; then
        if npm run build 2>/dev/null; then
            success "Frontend assets built"
        else
            error "Frontend build failed"
            git reset --hard HEAD~1 --quiet 2>/dev/null || true
            php artisan up 2>/dev/null || true
            exit 1
        fi
    else
        error "npm install failed"
        git reset --hard HEAD~1 --quiet 2>/dev/null || true
        php artisan up 2>/dev/null || true
        exit 1
    fi
else
    warning "npm not found, skipping frontend build"
fi

# ============================================================================
# ENVIRONMENT SETUP
# ============================================================================

log "INFO" "Setting up environment..."

# Load environment-specific .env file
if [ -f ".env.${ENVIRONMENT}" ]; then
    cp ".env.${ENVIRONMENT}" .env
    success "Environment file loaded (.env.${ENVIRONMENT})"
else
    warning "Environment file .env.${ENVIRONMENT} not found, using existing .env"
fi

# Generate application key if needed
if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env; then
    php artisan key:generate --force 2>/dev/null
    success "Application key generated"
fi

# ============================================================================
# RUN MIGRATIONS
# ============================================================================

log "INFO" "Running database migrations..."

if ! php artisan migrate --force --no-interaction 2>/dev/null; then
    error "Database migration failed"
    php artisan up 2>/dev/null || true
    exit 1
fi

success "Database migrations completed"

# ============================================================================
# CACHE CONFIGURATIONS
# ============================================================================

log "INFO" "Caching configurations..."

# Clear caches
php artisan cache:clear 2>/dev/null || true
php artisan config:clear 2>/dev/null || true
php artisan route:clear 2>/dev/null || true
php artisan view:clear 2>/dev/null || true

# Rebuild caches
php artisan config:cache 2>/dev/null || warning "Failed to cache config"
php artisan route:cache 2>/dev/null || warning "Failed to cache routes"
php artisan view:cache 2>/dev/null || warning "Failed to cache views"

# Optimize autoloader for production
if [ "${ENVIRONMENT}" = "production" ]; then
    php artisan optimize 2>/dev/null || warning "Failed to optimize"
fi

success "Caching configurations completed"

# ============================================================================
# SET PERMISSIONS
# ============================================================================

log "INFO" "Setting file permissions..."

WEB_USER=$(ps aux | grep -E '[a]pache|[w]ww-data|[p]hp-fpm' | awk '{print $1}' | head -1)

if [ -z "${WEB_USER}" ]; then
    WEB_USER="www-data"
fi

sudo chown -R "${WEB_USER}:${WEB_USER}" storage bootstrap/cache 2>/dev/null || true
chmod -R 775 storage bootstrap/cache 2>/dev/null || true

success "Permissions set (user: ${WEB_USER})"

# ============================================================================
# RUN TESTS (Development/Staging only)
# ============================================================================

if [ "${ENVIRONMENT}" != "production" ]; then
    log "INFO" "Running tests..."
    
    if php artisan test --no-coverage 2>/dev/null; then
        success "Tests passed"
    else
        warning "Some tests failed"
    fi
fi

# ============================================================================
# CLEAR EXPIRED TOKENS & SESSIONS
# ============================================================================

log "INFO" "Cleaning up..."

php artisan tinker --execute="
    try {
        \DB::table('sessions')->where('last_activity', '<', now()->subDays(7)->timestamp)->delete();
    } catch (\Exception \$e) {
        echo 'Sessions cleanup skipped: ' . \$e->getMessage();
    }
" 2>/dev/null || true

success "Cleanup completed"

# ============================================================================
# DISABLE MAINTENANCE MODE
# ============================================================================

log "INFO" "Disabling maintenance mode..."

php artisan up 2>/dev/null || true

success "Maintenance mode disabled"

# ============================================================================
# RESTART SERVICES
# ============================================================================

log "INFO" "Restarting services..."

# Detect and restart appropriate service
if command -v systemctl &> /dev/null; then
    if systemctl is-active --quiet php-fpm; then
        sudo systemctl restart php-fpm 2>/dev/null || true
    elif systemctl is-active --quiet php8.2-fpm; then
        sudo systemctl restart php8.2-fpm 2>/dev/null || true
    elif systemctl is-active --quiet php8.1-fpm; then
        sudo systemctl restart php8.1-fpm 2>/dev/null || true
    fi
    
    if systemctl is-active --quiet nginx; then
        sudo systemctl reload nginx 2>/dev/null || true
    elif systemctl is-active --quiet apache2; then
        sudo systemctl reload apache2 2>/dev/null || true
    elif systemctl is-active --quiet httpd; then
        sudo systemctl reload httpd 2>/dev/null || true
    fi
fi

success "Services restarted"

# ============================================================================
# POST-DEPLOYMENT VERIFICATION
# ============================================================================

log "INFO" "Performing post-deployment verification..."

# Check if application is responsive
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/health 2>/dev/null || echo "000")

if [ "${HEALTH_CHECK}" = "200" ]; then
    success "Health check passed"
else
    warning "Health check returned status: ${HEALTH_CHECK}"
fi

# Store current version
echo "${CURRENT_COMMIT}" > "${CURRENT_VERSION_FILE}"
success "Deployment version recorded: ${CURRENT_COMMIT:0:7}"

# ============================================================================
# DEPLOYMENT SUMMARY
# ============================================================================

log "INFO" "========================================================================"

if [ ${FAILED} -eq 0 ]; then
    success "Deployment completed successfully!"
    log "INFO" "Environment: ${ENVIRONMENT}"
    log "INFO" "Commit: ${CURRENT_COMMIT}"
    log "INFO" "Timestamp: $(date)"
    log "INFO" "========================================================================"
    exit 0
else
    error "Deployment failed with ${FAILED} error(s)"
    log "INFO" "Attempting to restore from backup..."
    
    if [ -f "${BACKUP_FILE}" ]; then
        rm -rf "${APP_DIR}"
        tar -xzf "${BACKUP_FILE}"
        success "Restored from backup"
    fi
    
    php artisan up 2>/dev/null || true
    log "INFO" "========================================================================"
    exit 1
fi