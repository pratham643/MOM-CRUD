#!/bin/bash

################################################################################
# CodeDeploy: Stop Service Script
# Gracefully stops the application
################################################################################

set -e

APP_DIR="/var/www/html/mom-crud"
LOG_FILE="/var/log/codedeploy/stop.log"

{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting application stop..."
    
    cd "${APP_DIR}"
    
    # Enable maintenance mode
    php artisan down --render="errors::503" 2>/dev/null || true
    
    # Stop queue workers if present
    pkill -f "queue:work" || true
    pkill -f "queue:daemon" || true
    
    # Wait for graceful shutdown
    sleep 5
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Application stopped successfully"
    
} >> "${LOG_FILE}" 2>&1

exit 0
