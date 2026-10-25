@regression @any @content @search
Feature: Search - Header search
      As a site visitor
      I want a search control in the header of every page
      So that I can look something up from wherever I am.

  @check @local @development @staging @production
  Scenario: Check the header search is a labelled toggle, closed at rest
    Given I am an anonymous user
     When I go to "/"
     Then "header[role='banner'] .icon-toggle__button" should be visible
      And "header[role='banner'] .icon-toggle__button" should have attribute "aria-label" with value "Search"
      And "header[role='banner'] .icon-toggle__button" should have attribute "aria-expanded" with value "false"
      And "header[role='banner'] .icon-toggle__panel" should be hidden

  @check @local @development @staging @production
  Scenario: Check the header search opens and closes again
    Given I am an anonymous user
     When I go to "/"
      And I click on the element "header[role='banner'] .icon-toggle__button"
     Then "header[role='banner'] .icon-toggle__panel input[name='keywords']" should be visible within 10 seconds
      And "header[role='banner'] .icon-toggle__panel label.visually-hidden" should have text "Search by keyword"
      And "header[role='banner'] .icon-toggle__button" should have attribute "aria-expanded" with value "true"
     When I click on the element "header[role='banner'] .icon-toggle__close"
     Then "header[role='banner'] .icon-toggle__panel" should be hidden within 10 seconds
      And "header[role='banner'] .icon-toggle__button" should be visible
      And "header[role='banner'] .icon-toggle__button" should have attribute "aria-expanded" with value "false"

  @check @local @development @staging @production
  Scenario: Check searching from the header lands on the results page with the keyword
    Given I am an anonymous user
     When I go to "/blog"
      And I click on the element "header[role='banner'] .icon-toggle__button"
      And I fill in the field "header[role='banner'] .icon-toggle__panel input[name='keywords']" with "security"
      And I press the key "Enter" on the element "header[role='banner'] .icon-toggle__panel input[name='keywords']"
      And I wait until the URL contains "keywords=security"
     Then the path should be "/search"
      And "#views-exposed-form-search-results-block input[name='keywords']" should have value "security"
      And ".view-display-id-results_block .views-row .card" should be visible
