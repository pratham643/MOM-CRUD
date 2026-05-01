#!/bin/bash

# ============================================
# AWS EC2 Laravel Deployment Script
# Run this on your EC2 instance
# ============================================

set -e

echo "=========================================="
echo "Starting AWS EC2 Laravel Setup"
echo "=========================================="

# Update system
echo "[1/10] Updating system packages..."
sudo apt update && sudo apt upgrade -y

# Install required packages
echo "[2/10] Installing Nginx, PHP and dependencies..."
sudo apt install -y nginx php8.2-fpm php8.2-mysql php8.2-xml php8.2-mbstring php8.2-curl php8.2-zip php8.2-bcmath php8.2-intl unzip git curl wget

# Install Composer
echo "[3/10] Installing Composer..."
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer
sudo chmod +x /usr/local/bin/composer

# Create application directory
echo "[4/10] Creating application directory..."
sudo mkdir -p /var/www/html/mom-crud
sudo chown -R ubuntu:ubuntu /var/www/html/mom-crud

# Clone repository (replace with your repo URL)
echo "[5/10] Cloning GitHub repository..."
cd /var/www/html/mom-crud
git init
git remote add origin https://github.com/YOUR_USERNAME/mom-crud.git
git pull origin main || echo "Run: git pull origin main"

# Setup .env file
echo "[6/10] Setting up environment file..."
cp .env.example .env

# Ask for database details
echo "Please configure your .env file with database credentials"
echo "Then run: composer install --no-dev --optimize-autoloader"

# Generate key
echo "[7/10] Generating application key..."
php artisan key:generate

# Cache configurations
echo "[8/10] Caching configurations..."
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Configure Nginx
echo "[9/10] Configuring Nginx..."
sudo tee /etc/nginx/sites-available/mom-crud > /dev/null <<'EOF'
server {
    listen 80;
    server_name _;
    root /var/www/html/mom-crud/public;
    index index.php;

    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }

    location ~ /\.(?!well-known).* {
        deny all;
    }
}
EOF

sudo ln -sf /etc/nginx/sites-available/mom-crud /etc/nginx/sites-enabled/
sudo nginx -t

# Restart services
echo "[10/10] Restarting services..."
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm

echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo "Next steps:"
echo "1. Configure .env with your database details"
echo "2. Run: composer install --no-dev --optimize-autoloader"
echo "3. Run: php artisan migrate"
echo "4. Access your app at http://YOUR_EC2_IP"