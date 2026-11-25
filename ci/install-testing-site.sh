#!/usr/bin/env bash
# Installs the site every E2E suite runs against, in GitHub Actions and
# Bitbucket Pipelines. Port of the "Install Varbase" job in the Varbase project
# template's .gitlab-ci.yml.
#
# Run from the project root after composer install and
# ci/require-testing-recipes.sh. SIMPLETEST_DB is the database URL.
#
# 1. Installs the testing site template: Varbase Starter plus Events, News and
#    Podcasts (tests/recipes/varbase_testing_site). Those three stop on config
#    validation errors when applied to an installed site, so they go in with
#    the install.
# 2. Seeds the events, news, podcasts and search test content.
# 3. Applies the base and AI recipes, then the AI recipes Varbase ships but does
#    not apply by default (Readable, SEO, Chatbot, Content Operations, Figma).
#    AI Search Base and AI Answers stay out: they need a vector database.
# 4. Sets the AI provider: amazee.ai, or the Echo test provider when amazee.ai
#    cannot be reached (tests/scripts/ai-provider.sh).
# 5. Seeds the testing users and prepares the site for deterministic testing.
#
# NOTE: the testing users share one published password. That is acceptable
# only on a throwaway CI site.
set -eo pipefail

ROOT="$(pwd)"
WEB="${ROOT}/web"
DRUSH="${ROOT}/vendor/bin/drush --root=${WEB}"
# This template sets composer config bin-dir to vendor/bin, so `dr` lives
# there, not in bin/. Drush 13.x has no `recipe` command.
DR="php ${ROOT}/vendor/bin/dr"
SETTINGS_PHP="${WEB}/sites/default/settings.php"
test -f "${ROOT}/vendor/bin/dr" || { echo "core recipe runner 'dr' missing from vendor/bin"; exit 1; }

# = Settings the install reads =
chmod u+w "$(dirname "$SETTINGS_PHP")" "$SETTINGS_PHP"
# Profile installs read the settings line, not DRUPAL_CMS_TELEMETRY.
echo "\$settings['drupal_cms_telemetry'] = FALSE;" >> "$SETTINGS_PHP"
# Varbase AI Readable Base: let /llms.txt past fast_404 (the step its README documents).
echo "\$settings['fast404_exts'] = '/^(?!\/robots)^(?!\/llms\.txt\$)^(?!\/system\/files).*\.(txt|png|gif|jpe?g|css|js|ico|swf|flv|cgi|bat|pl|dll|exe|asp)\$/i';" >> "$SETTINGS_PHP"

# = Install the testing site template =
cp -r "${ROOT}/tests/recipes/varbase_testing_site" "${ROOT}/recipes/"
$DRUSH site:install varbase \
  ${SIMPLETEST_DB:+--db-url="$SIMPLETEST_DB"} \
  --account-name="${DRUPAL_ADMIN_USERNAME:-webmaster}" \
  --account-pass="${DRUPAL_ADMIN_PASSWORD:-dD.123123ddd}" \
  --account-mail=webmaster@vardot.com \
  --site-name="Varbase Test" --locale=en -y \
  installer_site_template_form.add_ons=varbase_testing_site

# = Test content for the events, news, podcasts and search scenarios =
# Seeded before the AI recipes: AI Taxonomy Tagging adds a status field to
# Utility pages that a node created outside the form fails to validate.
for r in varbase_events_base_test_content varbase_news_base_test_content varbase_podcasts_base_test_content varbase_search_base_test_content; do
  $DRUSH cache:rebuild
  $DR recipe "${ROOT}/tests/recipes/$r"
done

# = Base and AI recipes =
# A cache rebuild before each apply lets a recipe see the modules and hooks the
# previous one enabled.
apply_recipe() {
  $DRUSH cache:rebuild || true
  $DR recipe "${ROOT}/recipes/$1" || true
}
apply_recipe varbase_dev_base
apply_recipe varbase_i18n_base
apply_recipe varbase_api_base
apply_recipe varbase_auth_base
# Auth Base enables Google only; Facebook and LinkedIn ship disabled.
$DRUSH pm:enable social_auth_facebook social_auth_linkedin -y || true
apply_recipe varbase_ai_base
apply_recipe varbase_ai_context
apply_recipe varbase_ai_safety
# The AI safety/taxonomy sub-recipes abort on config actions that need a live
# AI provider, so their modules never get enabled. Enable them so their admin
# pages exist; the config actions are optional.
$DRUSH cache:rebuild || true
$DRUSH pm:enable ai_logging ai_observability ai_automators -y || true
# The AI recipes Varbase ships but does not apply by default. None needs a
# provider key to apply.
for r in varbase_ai_readable_base varbase_ai_seo varbase_ai_chatbot_base varbase_ai_content_operations_base varbase_ai_figma_base; do
  $DRUSH cache:rebuild
  $DR recipe "${ROOT}/recipes/$r"
done

# = AI provider: amazee.ai, or the Echo test provider =
export DRUSH DR SETTINGS_PHP
export DRUPAL_CMS_AI="${ROOT}/recipes/drupal_cms_ai"
export AI_RECIPES="${ROOT}/recipes/varbase_ai_base ${ROOT}/recipes/varbase_ai_context ${ROOT}/recipes/varbase_ai_safety"
. "${ROOT}/tests/scripts/ai-provider.sh"

# Rendering the ai_ckeditor "AI Assistant" settings subform performs a live
# AI-provider lookup, which hangs on a runner and blows the browser's
# navigation budget on the text-format edit page. Strip the button/plugin from
# every editor; the module stays enabled.
$DRUSH php:eval 'foreach(\Drupal::entityTypeManager()->getStorage("editor")->loadMultiple() as $e){$s=$e->getSettings();$c=false;if(!empty($s["toolbar"]["items"])&&is_array($s["toolbar"]["items"])){$n=array_values(array_filter($s["toolbar"]["items"],function($i){return stripos((string)$i,"ai_ckeditor")===false&&stripos((string)$i,"aickeditor")===false;}));if($n!==$s["toolbar"]["items"]){$s["toolbar"]["items"]=$n;$c=true;}}if(!empty($s["plugins"])&&is_array($s["plugins"])){foreach(array_keys($s["plugins"]) as $k){if(stripos($k,"ai_ckeditor")!==false){unset($s["plugins"][$k]);$c=true;}}}if($c){$e->setSettings($s);$e->save();}}' || true
$DRUSH cache:rebuild || true

# = Testing users (the registry mirrors worldParameters.users in cucumber.js) =
( cd "${ROOT}/recipes/varbase_starter/scripts" && bash add-testing-users.sh )

# = Deterministic testing =
$DRUSH pm:uninstall antibot -y || true
$DRUSH config:set user.flood ip_limit 1000000 -y
$DRUSH config:set user.flood user_limit 1000000 -y
$DRUSH config:set honeypot.settings time_limit 0 -y || true
$DRUSH php:eval '$b=\Drupal::entityTypeManager()->getStorage("block")->load("ai_chatbot"); if($b){$b->disable()->save();}' || true
# While /admin/config/ai renders, the AI dashboard's two Project Browser blocks
# fetch from drupal.org and git.drupalcode.org, and its Status and Setup blocks
# ask every AI provider whether it is usable. A slow answer blows the browser's
# 30 s navigation budget. Remove those blocks on the CI site only; the
# dashboard page, its configuration links and documentation stay.
$DRUSH php:eval '$c=\Drupal::configFactory()->getEditable("dashboard.dashboard.ai_dashboard"); $l=$c->get("layout"); if(is_array($l)){foreach($l as $i=>$s){foreach(($s["components"]??[]) as $u=>$b){$id=(string)($b["configuration"]["id"]??""); if(str_starts_with($id,"project_browser_block:")||in_array($id,["ai_operations_status","ai_setup_ai_provider"],true)){unset($l[$i]["components"][$u]);}}} $c->set("layout",$l)->save();}' || true
# Keep aggregation ON: with it off, heavy admin pages emit ~90 script tags and
# exceed the browser's domcontentloaded budget.
$DRUSH config:set system.performance css.preprocess 1 -y
$DRUSH config:set system.performance js.preprocess 1 -y
$DRUSH config:set system.logging error_level all -y
$DRUSH search-api:index content
$DRUSH cache:rebuild
