#!/bin/bash

################################################################################
# CodeDeploy: Start Service Script
# Starts the application and runs final setup
################################################################################

set -e

APP_DIR="/var/www/html/mom-crud"
LOG_FILE="/var/log/codedeploy/start.log"

{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting application..."
    
    cd "${APP_DIR}"
    
    # Run migrations
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running migrations..."
    php artisan migrate --force --no-interaction
    
    # Cache configurations
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Caching configurations..."
    php artisan config:cache
    php artisan route:cache
    php artisan view:cache
    php artisan optimize
    
    # Set permissions
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Setting permissions..."
    chown -R www-data:www-data storage bootstrap/cache
    chmod -R 775 storage bootstrap/cache
    
    # Disable maintenance mode
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Disabling maintenance mode..."
    php artisan up
    
    # Restart services
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Restarting services..."
    systemctl restart php8.2-fpm || systemctl restart php-fpm
    systemctl reload nginx || systemctl reload apache2
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Application started successfully"
    
} >> "${LOG_FILE}" 2>&1

exit 0
