#!/usr/bin/env bash

set -Eeuo pipefail

APP_DIR="${APP_DIR:-/var/www/html/mom-crud}"
ENVIRONMENT="${DEPLOY_ENV:-${1:-production}}"
LOG_DIR="${LOG_DIR:-/var/log/mom-crud}"
LOG_FILE="${LOG_FILE:-${LOG_DIR}/deploy-$(date +%Y%m%d-%H%M%S).log}"
SHARED_ENV_DIR="${SHARED_ENV_DIR:-/etc/mom-crud}"
SERVICE_NAME="${SERVICE_NAME:-}"

mkdir -p "${LOG_DIR}"

log() {
  printf '[%s] [%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$1" "$2" | tee -a "${LOG_FILE}"
}

fail() {
  log "ERROR" "$1"
  if [ -d "${APP_DIR}" ]; then
    cd "${APP_DIR}"
    php artisan up >/dev/null 2>&1 || true
  fi
  exit 1
}

run() {
  log "INFO" "$1"
  shift
  "$@" >>"${LOG_FILE}" 2>&1 || fail "$1 failed"
}

detect_environment() {
  case "${DEPLOYMENT_GROUP_NAME:-}" in
    *staging*|*Staging*) ENVIRONMENT="staging" ;;
    *production*|*Production*) ENVIRONMENT="production" ;;
  esac
}

switch_environment() {
  local shared_file="${SHARED_ENV_DIR}/.env.${ENVIRONMENT}"
  local repo_file="${APP_DIR}/.env.${ENVIRONMENT}"

  if [ -f "${shared_file}" ]; then
    cp "${shared_file}" "${APP_DIR}/.env"
    log "INFO" "Loaded environment from ${shared_file}"
  elif [ -f "${repo_file}" ]; then
    cp "${repo_file}" "${APP_DIR}/.env"
    log "WARN" "Loaded repository environment template ${repo_file}; store real secrets in ${shared_file}"
  elif [ ! -f "${APP_DIR}/.env" ]; then
    fail "No .env file found for ${ENVIRONMENT}"
  fi
}

pull_latest_code_if_repo_exists() {
  if [ ! -d "${APP_DIR}/.git" ]; then
    log "INFO" "CodeDeploy artifact detected; skipping git pull"
    return
  fi

  local branch="main"
  if [ "${ENVIRONMENT}" = "staging" ] || [ "${ENVIRONMENT}" = "dev" ]; then
    branch="develop"
  fi

  run "Fetching latest ${branch}" git -C "${APP_DIR}" fetch origin "${branch}"
  run "Checking out ${branch}" git -C "${APP_DIR}" checkout "${branch}"
  run "Resetting to origin/${branch}" git -C "${APP_DIR}" reset --hard "origin/${branch}"
}

restart_services() {
  if [ -n "${SERVICE_NAME}" ]; then
    run "Restarting ${SERVICE_NAME}" systemctl restart "${SERVICE_NAME}"
    return
  fi

  if systemctl is-active --quiet php8.2-fpm; then
    run "Restarting php8.2-fpm" systemctl restart php8.2-fpm
  elif systemctl is-active --quiet php-fpm; then
    run "Restarting php-fpm" systemctl restart php-fpm
  fi

  if systemctl is-active --quiet nginx; then
    run "Reloading nginx" systemctl reload nginx
  elif systemctl is-active --quiet apache2; then
    run "Reloading apache2" systemctl reload apache2
  elif systemctl is-active --quiet httpd; then
    run "Reloading httpd" systemctl reload httpd
  else
    log "WARN" "No nginx/apache service detected"
  fi
}

web_user() {
  if id www-data >/dev/null 2>&1; then
    echo "www-data:www-data"
  elif id apache >/dev/null 2>&1; then
    echo "apache:apache"
  elif id nginx >/dev/null 2>&1; then
    echo "nginx:nginx"
  else
    echo ""
  fi
}

main() {
  detect_environment
  log "INFO" "Starting ${ENVIRONMENT} deployment"

  [ -d "${APP_DIR}" ] || fail "Application directory ${APP_DIR} does not exist"
  cd "${APP_DIR}"

  pull_latest_code_if_repo_exists
  switch_environment

  php artisan down --render="errors::503" >/dev/null 2>&1 || log "WARN" "Maintenance mode could not be enabled"

  run "Installing production Composer dependencies" composer install --no-dev --no-interaction --no-progress --prefer-dist --optimize-autoloader --classmap-authoritative
  run "Running database migrations" php artisan migrate --force --no-interaction

  run "Clearing Laravel caches" php artisan optimize:clear
  run "Caching config" php artisan config:cache
  run "Caching routes" php artisan route:cache
  run "Caching views" php artisan view:cache

  local owner
  owner="$(web_user)"
  if [ -n "${owner}" ]; then
    run "Setting storage permissions" chown -R "${owner}" storage bootstrap/cache
  else
    log "WARN" "No known web user found; skipping chown"
  fi
  run "Making storage writable" chmod -R ug+rwX storage bootstrap/cache

  php artisan up >>"${LOG_FILE}" 2>&1 || true
  restart_services

  log "INFO" "Deployment completed successfully"
}

trap 'fail "Deployment interrupted at line ${LINENO}"' ERR
main "$@"
