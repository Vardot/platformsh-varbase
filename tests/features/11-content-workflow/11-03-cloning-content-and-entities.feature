# @wip until Entity Clone is enabled on a Varbase site again.
#
# Varbase Admin Base 1.0.1 removed the entity_clone module deliberately,
# "temporarily remove Entity Clone until it has a stable release"
# (https://www.drupal.org/i/3621449), and 1.0.2 cleaned up the permission
# grants it left behind (https://www.drupal.org/i/3621823). The profile still
# requires drupal/entity_clone as a package, but no recipe enables the module,
# so /admin/config/system/entity-clone returns "Page not found" on a fresh
# install. Confirmed from this suite's own failure screenshot.
#
# The scenarios are kept, and corrected, rather than deleted: when Entity Clone
# gets a stable release and the recipe takes it back, remove the @wip tag and
# they run as they stand.
@wip @regression @any @content @workflow
Feature: Content Management - Cloning content and entities
      As a site admin user
      I want to be able to access the Entity Clone settings
      So that I can configure content cloning options.

  @check @local @development @staging @production
  Scenario: Check that the webmaster can access the Entity clone settings
    Given I am a logged in user with the "webmaster" user
     When I go to "/admin/config/system/entity-clone"
      And wait
     Then I should see "Entity clone settings"

  @check @local @development @staging @production
  Scenario: Check that anonymous users can not access the Entity clone settings
    Given I am an anonymous user
     When I go to "/admin/config/system/entity-clone"
      And wait
     Then I should not see "Entity clone settings"

  @check @local @development @staging @production
  Scenario: Check that Normal users can not access the Entity clone settings
    Given I am a logged in user with the "Normal user" user
     When I go to "/admin/config/system/entity-clone"
      And wait
     Then I should not see "Entity clone settings"
