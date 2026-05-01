#!/bin/bash

# ============================================
# Deployment Script for GitHub Actions
# Runs on EC2 after code push
# ============================================

set -e

echo "=========================================="
echo "Starting Deployment..."
echo "=========================================="

APP_DIR="/var/www/html/mom-crud"

cd $APP_DIR

# Pull latest code
echo "[1/6] Pulling latest code from Git..."
git pull origin main

# Install dependencies
echo "[2/6] Installing Composer dependencies..."
composer install --no-dev --optimize-autoloader

# Run migrations
echo "[3/6] Running database migrations..."
php artisan migrate --force --no-interaction

# Clear and cache configs
echo "[4/6] Caching configurations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Set permissions
echo "[5/6] Setting permissions..."
sudo chown -R www-data:www-data $APP_DIR/storage
sudo chown -R www-data:www-data $APP_DIR/bootstrap/cache
sudo chmod -R 775 $APP_DIR/storage
sudo chmod -R 775 $APP_DIR/bootstrap/cache

# Restart services
echo "[6/6] Restarting services..."
sudo systemctl restart php8.2-fpm
sudo systemctl restart nginx

echo "=========================================="
echo "Deployment Complete!"
echo "=========================================="