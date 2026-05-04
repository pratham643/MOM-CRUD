#!/bin/bash

################################################################################
# CodeDeploy: After Install Script
# Installs dependencies and prepares the application
################################################################################

set -e

APP_DIR="/var/www/html/mom-crud"
LOG_FILE="/var/log/codedeploy/after-install.log"

{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting post-installation setup..."
    
    cd "${APP_DIR}"
    
    # Install Composer dependencies
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Installing PHP dependencies..."
    composer install --no-dev --no-progress --no-interaction --prefer-dist --optimize-autoloader --classmap-authoritative
    
    # Install Node dependencies
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Installing Node dependencies..."
    npm ci --production || true
    
    # Build frontend assets
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Building frontend assets..."
    npm run build || true
    
    # Setup environment
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Setting up environment..."
    if [ -f ".env.production" ]; then
        cp .env.production .env
    fi
    
    # Generate key if needed
    if ! grep -q "APP_KEY=" .env || grep -q "APP_KEY=$" .env; then
        php artisan key:generate --force
    fi
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Post-installation setup completed"
    
} >> "${LOG_FILE}" 2>&1

exit 0
