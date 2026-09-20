#!/usr/bin/env bash
################################################################################
# Shared tooling setup for every Bitbucket Pipelines step.
#
# The pipeline runs on the official `php:8.4.25-cli-bookworm` image, which ships
# PHP and nothing else. This script adds what the Varbase build, the lint jobs
# and the browser suite need, and it is the ONE place that list lives, so the
# 24 parallel E2E steps cannot drift from the install step.
#
# Usage:
#   . ci/bitbucket/setup-tooling.sh            # PHP + Composer only
#   WITH_NODE=1 . ci/bitbucket/setup-tooling.sh
#   WITH_NODE=1 WITH_BROWSER=1 . ci/bitbucket/setup-tooling.sh
#
# Bitbucket runs the build container as root, so there is no `sudo` here (the
# image has none). That is the main mechanical difference from the GitHub
# Actions workflows, which run as a normal user on a full ubuntu-latest runner.
################################################################################
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive
export COMPOSER_MEMORY_LIMIT=-1
export COMPOSER_ALLOW_SUPERUSER=1

WITH_NODE="${WITH_NODE:-0}"
WITH_BROWSER="${WITH_BROWSER:-0}"
NODE_VERSION="${NODE_VERSION:-20}"

echo "--- apt packages"
apt-get update -y
apt-get install -y --no-install-recommends \
  ca-certificates curl git unzip zip jq gzip procps \
  libpng-dev libjpeg62-turbo-dev libfreetype6-dev libwebp-dev \
  libzip-dev libxml2-dev libonig-dev libyaml-dev libsodium-dev \
  libmagickwand-dev imagemagick webp libwebp7

# Varbase uses ImageMagick as its image toolkit and drimage_improved emits WebP
# derivatives on the fly. Without a permissive WebP policy those derivative
# requests fail and front-end pages log resource 404s. Same fix as the Actions
# workflow.
sed -i 's/rights="none"\s*pattern="WEBP"/rights="read|write" pattern="WEBP"/I' \
  /etc/ImageMagick-*/policy.xml 2>/dev/null || true

echo "--- PHP extensions"
# gd is configured with jpeg/freetype/webp so image styles and WebP derivatives
# work. pdo_mysql is the only database driver installed: composer.json REPLACES
# ext-pgsql / ext-pdo_pgsql so the Upsun runtime (which ships neither) still
# satisfies drupal/ai_provider_amazeeio. A root package that replaces an
# extension cannot coexist with that extension being loaded, so PostgreSQL must
# stay absent here. The php:cli image ships neither, which is why this pipeline
# needs no equivalent of the Actions `:pgsql, :pdo_pgsql` removals.
docker-php-ext-configure gd --with-jpeg --with-freetype --with-webp >/dev/null
docker-php-ext-install -j"$(nproc)" gd pdo_mysql zip bcmath opcache sodium >/dev/null
pecl install -f apcu imagick yaml >/dev/null
docker-php-ext-enable apcu imagick yaml >/dev/null
php -r 'foreach (["gd","pdo_mysql","mbstring","xml","curl","zip","sodium","apcu","yaml","bcmath","imagick"] as $e) { if (!extension_loaded($e)) { fwrite(STDERR, "missing PHP extension: $e\n"); exit(1); } }'

echo "--- Composer"
if ! command -v composer >/dev/null 2>&1; then
  curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
fi
composer --version

if [ "${WITH_NODE}" = "1" ]; then
  echo "--- Node.js ${NODE_VERSION} and Yarn"
  if ! command -v node >/dev/null 2>&1; then
    curl -fsSL "https://deb.nodesource.com/setup_${NODE_VERSION}.x" | bash -
    apt-get install -y --no-install-recommends nodejs
  fi
  node --version
  # package.json pins packageManager: yarn@4.x, so corepack is what provides it.
  corepack enable
fi

if [ "${WITH_BROWSER}" = "1" ]; then
  echo "--- Playwright system libraries"
  # Browsers themselves are cached (see the `playwright` cache in
  # bitbucket-pipelines.yml); the shared libraries are not, so they are
  # installed here on every step that opens a browser.
  : "${PLAYWRIGHT_BROWSERS_PATH:=/root/.cache/ms-playwright}"
  export PLAYWRIGHT_BROWSERS_PATH
fi

echo "--- tooling ready"
