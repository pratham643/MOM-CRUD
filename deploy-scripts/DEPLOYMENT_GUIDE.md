# ============================================
# AWS CI/CD Deployment Guide
# Run commands in order
# ============================================

## PART 1: LOCAL MACHINE SETUP

### Step 1: Push workflow to GitHub
```powershell
git add .
git commit -m "Add CI/CD deployment workflow"
git push origin main
```

### Step 2: Get your APP_KEY
```powershell
php artisan key:generate
php artisan key:generate --show
```

---

## PART 2: GITHUB CONFIGURATION

Go to: https://github.com/YOUR_USERNAME/mom-crud/settings/secrets/actions

Add these secrets:

| Secret | Value | Example |
|--------|-------|---------|
| AWS_HOST | Your EC2 Public IP | 13.234.56.78 |
| SSH_USER | EC2 username | ubuntu |
| SSH_KEY | Private SSH key content | (paste entire key) |

---

## PART 3: AWS EC2 SETUP

### Option A: Run Setup Script (Recommended)

SSH into your EC2 instance and run:

```bash
# Download and run setup script
cd /tmp
wget https://raw.githubusercontent.com/YOUR_USERNAME/mom-crud/main/deploy-scripts/setup-ec2.sh
chmod +x setup-ec2.sh
sudo bash setup-ec2.sh
```

### Option B: Manual Setup

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Nginx, PHP
sudo apt install -y nginx php8.2-fpm php8.2-mysql php8.2-xml php8.2-mbstring php8.2-curl php8.2-zip unzip git

# 3. Install Composer
curl -sS https://getcomposer.org/installer | php
sudo mv composer.phar /usr/local/bin/composer

# 4. Create directory
sudo mkdir -p /var/www/html/mom-crud
sudo chown -R ubuntu:ubuntu /var/www/html/mom-crud

# 5. Clone repo
cd /var/www/html/mom-crud
git clone https://github.com/YOUR_USERNAME/mom-crud.git .

# 6. Setup .env
cp .env.example .env
nano .env  # Configure DB credentials

# 7. Install dependencies
composer install --no-dev --optimize-autoloader
php artisan key:generate

# 8. Configure Nginx
sudo nano /etc/nginx/sites-available/mom-crud
```

Nginx config content:
```nginx
server {
    listen 80;
    server_name _;
    root /var/www/html/mom-crud/public;
    index index.php;

    location / {
        try_files $uri $uri/ /index.php?$query_string;
    }

    location ~ \.php$ {
        fastcgi_pass unix:/var/run/php/php8.2-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
        include fastcgi_params;
    }
}
```

```bash
# 9. Enable site and restart
sudo ln -s /etc/nginx/sites-available/mom-crud /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl restart nginx
sudo systemctl restart php8.2-fpm
```

---

## PART 4: TEST DEPLOYMENT

```powershell
# Make a small change and push
git add .
git commit -m "Trigger CI/CD"
git push origin main
```

Check: https://github.com/YOUR_USERNAME/mom-crud/actions

---

## PART 5: TROUBLESHOOTING

### Check deployment logs
```bash
sudo journalctl -u nginx -f
sudo tail -f /var/www/html/mom-crud/storage/logs/laravel.log
```

### Common issues:
- Permission denied: `sudo chown -R www-data:www-data /var/www/html/mom-crud`
- 502 error: `sudo systemctl restart php8.2-fpm`
- Database connection: Check .env DB settings