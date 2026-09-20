#!/usr/bin/env bash
################################################################################
# Run ONE Varbase E2E feature suite on Bitbucket Pipelines.
#
#   ci/bitbucket/run-e2e-suite.sh <SUITE> [FEATURES_GLOB]
#
# SUITE          names the per-suite cucumber JSON the reports step merges.
# FEATURES_GLOB  optional override of the feature files to run. Omitted, the
#                whole `tests/features/<SUITE>/` folder runs. This is what lets
#                a heavy folder be split across several steps without inventing
#                new folders, exactly as the GitHub Actions matrix does.
#
# This script exists so that adding a suite to bitbucket-pipelines.yml is ONE
# line of shell inside a six-line step, rather than a copy of forty lines of
# build-and-serve YAML. Bitbucket Pipelines has no matrix and no way to
# parameterise a YAML anchor, so the parameterisation has to live here.
#
# WHY THIS STEP REBUILDS THE CODEBASE
#
# The Actions workflow carries the built `vendor` / `node_modules` / `web` /
# `recipes` trees between jobs in an `actions/cache` entry. Bitbucket refuses to
# upload a cache larger than 1 GB and caps a step's total artifacts at 1 GB, and
# a built Varbase tree is well past both. So the heavy trees are NOT shipped
# between steps; what is shipped is:
#
#   * content-addressed Composer / Yarn / Playwright download caches, so
#     rebuilding is a local unpack rather than a network fetch, and
#   * the small installed-site state (gzipped DB dump, settings.php, the files
#     directory, .easy_encryption) as a step artifact.
#
# Rebuilding costs roughly 3-5 warm minutes per suite step. That is the price
# Bitbucket's 1 GB ceiling charges, and it is why the E2E fan-out is behind a
# manual `custom:` pipeline.
################################################################################
set -euo pipefail

SUITE="${1:?usage: run-e2e-suite.sh <SUITE> [FEATURES_GLOB]}"
FEATURES_GLOB="${2:-tests/features/${SUITE}/**/*.feature}"

export FEATURES="${FEATURES_GLOB}"
export CUCUMBER_JSON="cucumber_report_${SUITE}"
# Report generation is the separate reports step; disable varbase-e2e's auto
# HTML hook so it does not build one from process.on('exit').
export VARBASE_E2E_REPORT_DISABLE=1

export LAUNCH_URL="${LAUNCH_URL:-http://127.0.0.1:8080}"
export DRUPAL_TEST_BASE_URL="${DRUPAL_TEST_BASE_URL:-http://127.0.0.1:8080}"
export SIMPLETEST_DB="${SIMPLETEST_DB:-mysql://drupal:drupal@127.0.0.1:3306/drupal}"
export PLAYWRIGHT_BROWSERS_PATH="${PLAYWRIGHT_BROWSERS_PATH:-/root/.cache/ms-playwright}"
export YARN_ENABLE_IMMUTABLE_INSTALLS=false
export FORCE_COLOR=1

echo "=== Suite ${SUITE}"
echo "=== Features ${FEATURES}"

# ---------------------------------------------------------------------------
# 1. Make the tree writable BEFORE anything else touches it.
#
# `drush site:install` hardens the site directory: web/sites/default becomes
# 0555 and settings.php 0444. Those modes travel with the artifact, and
# Bitbucket unpacks artifacts into the working directory BEFORE this script
# runs. Anything that writes into web/sites afterwards - `composer install`
# refreshing the scaffold files, drush rewriting settings, the files directory -
# fails on a read-only directory with an error that reads like a Composer bug.
# chmod FIRST, never after.
# ---------------------------------------------------------------------------
chmod -R u+w web/sites 2>/dev/null || true

# ---------------------------------------------------------------------------
# 2. Tooling and codebase.
# ---------------------------------------------------------------------------
WITH_NODE=1 WITH_BROWSER=1 . ci/bitbucket/setup-tooling.sh

composer install --no-interaction --no-progress --optimize-autoloader --prefer-dist

test -f .yarnrc.yml || echo "nodeLinker: node-modules" > .yarnrc.yml
# varbase-e2e's postinstall scaffolds a cucumber.js when none exists. Under
# yarn 4 it can clobber the committed one, so restore it afterwards.
cp cucumber.js .cucumber.js.bak
yarn install
cp .cucumber.js.bak cucumber.js && rm .cucumber.js.bak

./node_modules/.bin/playwright install --with-deps chromium

# ---------------------------------------------------------------------------
# 3. Restore the installed site and serve it.
# ---------------------------------------------------------------------------
chmod -R u+w web/sites 2>/dev/null || true
mkdir -p web/sites/default/files web/sites/simpletest
chmod -R 777 web/sites/default/files web/sites/simpletest

test -f varbase-db.sql.gz || { echo "The install step's database artifact is missing."; exit 1; }
gunzip -c varbase-db.sql.gz | ./vendor/bin/drush --root="${PWD}/web" sql:cli
./vendor/bin/drush --root="${PWD}/web" cache:rebuild

# Drupal core's own router rewrites missing files (image-style derivatives,
# including the WebP ones drimage_improved generates on the fly) back to
# index.php. PHP's built-in server is single-process by default; a real browser
# opens many parallel requests and Drupal issues sub-requests, so without extra
# workers the suite serialises or dead-locks.
(
  cd web
  PHP_CLI_SERVER_WORKERS=8 php -S 127.0.0.1:8080 .ht.router.php > "${OLDPWD}/webserver.log" 2>&1 &
)
for _ in $(seq 1 30); do
  if curl -sf -o /dev/null "http://127.0.0.1:8080/user/login"; then
    echo "Web server is up."
    break
  fi
  sleep 2
done
curl -sf -o /dev/null "http://127.0.0.1:8080/user/login" || {
  echo "Web server did not come up."; cat webserver.log; exit 1;
}

# ---------------------------------------------------------------------------
# 4. Run the suite.
# ---------------------------------------------------------------------------
./node_modules/.bin/cucumber-js --config cucumber.js --tags "not @wip"
