#!/usr/bin/env bash
# Adds the recipes the E2E suites need that this template does not ship:
# Varbase Events, News and Podcasts Base. CI only. The committed composer.json
# and composer.lock stay as they are; only these packages and their new
# dependencies are added on the runner, as in the Varbase project template.
set -eo pipefail
composer require --no-update \
  "drupal/varbase_events_base:~1.0.0" \
  "drupal/varbase_news_base:~1.0.0" \
  "drupal/varbase_podcasts_base:~2.0.0"
composer update drupal/varbase_events_base drupal/varbase_news_base drupal/varbase_podcasts_base \
  --with-dependencies --no-interaction --no-progress --optimize-autoloader --prefer-dist
