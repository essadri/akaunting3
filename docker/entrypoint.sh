#!/usr/bin/env bash
set -euo pipefail

cd /var/www/html

if [ ! -f .env ]; then
  cp .env.example .env
fi

touch .env

run_user="www-data"
run_group="www-data"

if [ -n "${APP_UID:-}" ] && [ -n "${APP_GID:-}" ]; then
  if ! getent group "${APP_GID}" >/dev/null 2>&1; then
    groupadd -g "${APP_GID}" appgroup
  fi

  if ! id -u "${APP_UID}" >/dev/null 2>&1; then
    useradd -u "${APP_UID}" -g "${APP_GID}" -m -s /bin/bash appuser
  fi

  chown -R "${APP_UID}:${APP_GID}" /var/www/html
  run_user="${APP_UID}"
  run_group="${APP_GID}"
fi

set_env_value() {
  local key="$1"
  local value="$2"

  if grep -q "^${key}=" .env; then
    sed -i "s#^${key}=.*#${key}=${value}#" .env
  else
    echo "${key}=${value}" >> .env
  fi
}

if [ -n "${APP_URL:-}" ]; then
  set_env_value APP_URL "${APP_URL}"
fi

if [ -n "${APP_ENV:-}" ]; then
  set_env_value APP_ENV "${APP_ENV}"
fi

if [ -n "${APP_DEBUG:-}" ]; then
  set_env_value APP_DEBUG "${APP_DEBUG}"
fi

if [ -n "${DB_HOST:-}" ]; then
  set_env_value DB_HOST "${DB_HOST}"
fi

if [ -n "${DB_PORT:-}" ]; then
  set_env_value DB_PORT "${DB_PORT}"
fi

if [ -n "${DB_DATABASE:-}" ]; then
  set_env_value DB_DATABASE "${DB_DATABASE}"
fi

if [ -n "${DB_USERNAME:-}" ]; then
  set_env_value DB_USERNAME "${DB_USERNAME}"
fi

if [ -n "${DB_PASSWORD:-}" ]; then
  set_env_value DB_PASSWORD "${DB_PASSWORD}"
fi

if ! grep -q "^APP_KEY=" .env || [ -z "$(grep -E '^APP_KEY=' .env | cut -d= -f2)" ]; then
  php artisan key:generate --force
fi

php artisan package:discover --ansi || true
php artisan storage:link || true
php artisan config:cache || true
php artisan route:cache || true

exec gosu "${run_user}:${run_group}" "$@"
