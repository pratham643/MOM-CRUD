#!/bin/bash

################################################################################
# CodeDeploy: Before Install Script
# Prepares the system before deployment
################################################################################

set -e

APP_DIR="/var/www/html/mom-crud"
BACKUP_DIR="/var/backups/mom-crud"
LOG_FILE="/var/log/codedeploy/before-install.log"

{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting pre-installation setup..."
    
    # Create necessary directories
    mkdir -p "${APP_DIR}"
    mkdir -p "${BACKUP_DIR}"
    mkdir -p /var/log/codedeploy
    
    # Backup current application if it exists
    if [ -d "${APP_DIR}/.git" ]; then
        BACKUP_FILE="${BACKUP_DIR}/backup-$(date +%s).tar.gz"
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Creating backup: ${BACKUP_FILE}"
        
        tar -czf "${BACKUP_FILE}" \
            --exclude='node_modules' \
            --exclude='storage/logs' \
            --exclude='storage/framework/cache' \
            "${APP_DIR}" 2>/dev/null || true
        
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] Backup created"
    fi
    
    # Install required packages
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Installing required packages..."
    yum update -y
    yum install -y php82 php82-cli php82-fpm php82-mysql php82-json php82-xml php82-curl composer git nodejs npm
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Pre-installation setup completed"
    
} >> "${LOG_FILE}" 2>&1

exit 0
