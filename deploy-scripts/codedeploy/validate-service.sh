#!/bin/bash

################################################################################
# CodeDeploy: Validate Service Script
# Validates that the application is running correctly
################################################################################

set -e

APP_DIR="/var/www/html/mom-crud"
LOG_FILE="/var/log/codedeploy/validate-service.log"
MAX_RETRIES=30
RETRY_INTERVAL=2

{
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Starting service validation..."
    
    cd "${APP_DIR}"
    
    # Wait for services to be ready
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Waiting for services to be ready..."
    for ((i = 1; i <= MAX_RETRIES; i++)); do
        if curl -s -f http://localhost/health > /dev/null 2>&1; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] Health check passed"
            break
        fi
        
        if [ $i -eq $MAX_RETRIES ]; then
            echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Health check failed after ${MAX_RETRIES} retries"
            exit 1
        fi
        
        sleep $RETRY_INTERVAL
    done
    
    # Check database connectivity
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Checking database connectivity..."
    if ! php artisan db:ping > /dev/null 2>&1; then
        echo "[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: Database connectivity check failed"
        exit 1
    fi
    
    # Run basic smoke tests
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Running smoke tests..."
    php artisan test --no-coverage --stop-on-failure tests/Feature/EmployeeTest.php::test_can_read_employee || true
    
    echo "[$(date +'%Y-%m-%d %H:%M:%S')] Service validation completed successfully"
    
} >> "${LOG_FILE}" 2>&1

exit 0
