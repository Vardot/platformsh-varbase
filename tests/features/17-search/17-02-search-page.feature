@regression @any @content @search
Feature: Search - The search page
      As a site visitor
      I want the search page to list matching blog posts and let me narrow them by tag, type and date
      So that I can find the post I am after without paging through everything.

  @check @local @development @staging @production
  Scenario: Check the search page has one heading, a keyword bar and a result summary
    Given I am an anonymous user
     When I go to "/search?keywords=the"
     Then "main h1" should have a count of 1
      And "main h1" should have text "Search"
      And "#views-exposed-form-search-results-block input[name='keywords']" should have value "the"
      And I should see text matching "Displaying 1 - 10 of \d+ results"

  @check @local @development @staging @production
  Scenario: Check a blog post result renders as a card with a title and a link
    Given I am an anonymous user
     When I go to "/search?keywords=the&f[0]=content_type:blog"
     Then ".view-display-id-results_block .views-row .card" should be visible
      And ".view-display-id-results_block .views-row:not(:has(a.stretched-link[href^='/blog/']))" should have a count of 0
      And ".view-display-id-results_block .views-row:not(:has(.card h3))" should have a count of 0
      And ".view-display-id-results_block .views-row .card h3:empty" should have a count of 0
      And I should not see "LogicException"
      And I should not see "Requested delta"
      And I should not see "The website encountered an unexpected error"

  @check @local @development @staging @production
  Scenario: Check the filter rail lists Tags, then Content type, then Date Published
    Given I am an anonymous user
     When I go to "/search?keywords=the"
     Then the element "[data-drupal-facet-id='search_content_type']" should appear after the element "[data-drupal-facet-id='search_tags']"
      And the element "#views-exposed-form-search-date-block" should appear after the element "[data-drupal-facet-id='search_content_type']"
      And "#content-type-blog" should be visible
      And "#views-exposed-form-search-date-block input[name='published']" should have a count of 5

  @check @local @development @staging @production
  Scenario: Check two Tags boxes together widen the results and keep the keyword
    Given I am an anonymous user
     When I go to "/search?keywords=varbase"
      And I click on the element "#tags-drupal"
      And I wait until the URL contains "tags"
      And I wait until the page is loaded
      And I should see "Show more"
      And I click on the element "a.facets-soft-limit-link"
      And I click on the element "#tags-seo"
      And I wait until the URL contains "SEO"
     Then "#tags-seo:checked" should have a count of 1 within 10 seconds
      And "#tags-drupal:checked" should have a count of 1
      And the url should match "keywords=varbase"
      And I should see "How Varbase Optimizes Your Site for Search Engines"

  @check @local @development @staging @production
  Scenario: Check a Tags box and the Content type box combine
    Given I am an anonymous user
     When I go to "/search?keywords=varbase&f[0]=tags:SEO&f[1]=content_type:blog"
     Then "#tags-seo:checked" should have a count of 1
      And "#content-type-blog:checked" should have a count of 1
      And I should see "How Varbase Optimizes Your Site for Search Engines"
      And ".view-display-id-results_block .views-row:not(:has(a.stretched-link[href^='/blog/']))" should have a count of 0

  @check @local @development @staging @production
  Scenario: Check choosing a date keeps the keyword
    Given I am an anonymous user
     When I go to "/search?keywords=the"
      And I click on the element "#views-exposed-form-search-date-block input[name='published'][value='4']"
      And I wait until the URL contains "published=4"
     Then the url should match "keywords=the"
      And "#views-exposed-form-search-date-block input[name='published'][value='4']:checked" should have a count of 1 within 10 seconds

  @check @local @development @staging @production
  Scenario: Check a new keyword keeps the chosen date
    Given I am an anonymous user
     When I go to "/search?keywords=the&published=4"
      And I fill in the field "#views-exposed-form-search-results-block input[name='keywords']" with "security"
      And I click on the element "#views-exposed-form-search-results-block .form-submit"
      And I wait until the URL contains "keywords=security"
     Then the url should match "published=4"

  @wip @check @local @development @staging @production
  Scenario: Check a new keyword keeps the ticked tag
    Given I am an anonymous user
     When I go to "/search?keywords=varbase&f[0]=tags:SEO"
      And I fill in the field "#views-exposed-form-search-results-block input[name='keywords']" with "drupal"
      And I click on the element "#views-exposed-form-search-results-block .form-submit"
      And I wait until the URL contains "keywords=drupal"
     Then the url should match "tags"

  @check @local @development @staging @production
  Scenario: Check paging moves the range on and keeps the keyword
    Given I am an anonymous user
     When I go to "/search?keywords=the"
      And I click on the link with the title "Go to page 2"
      And I wait until the URL contains "page=1"
     Then the url should match "keywords=the"
      And I should see text matching "Displaying 11 - \d+ of \d+ results"

  @check @local @development @staging @production
  Scenario: Check a query that matches nothing says so and keeps the query
    Given I am an anonymous user
     When I go to "/search?keywords=telescope"
     Then I should see "No results match your search. Try other keywords or clear the filters."
      And ".view-display-id-results_block .views-row" should have a count of 0
      And "#views-exposed-form-search-results-block input[name='keywords']" should have value "telescope"

  @check @local @development @staging @production
  Scenario: Check the search page with no keyword renders without results or errors
    Given I am an anonymous user
     When I go to "/search"
     Then "main h1" should have text "Search"
      And "#views-exposed-form-search-results-block input[name='keywords']" should have value ""
      And ".view-display-id-results_block .views-row" should have a count of 0
      And I should see "Enter a keyword to search the site."
      And I should not see "Page not found"

  @check @local @development @staging @production
  Scenario Outline: Check the search page works <width> pixels wide
    Given I am an anonymous user
     When I set the viewport to <width> by <height>
      And I go to "/search?keywords=the"
     Then "#views-exposed-form-search-results-block input[name='keywords']" should be visible
      And "[data-drupal-facet-id='search_tags'] .facets-checkbox" should be visible
      And "#content-type-blog" should be visible
      And "#views-exposed-form-search-date-block input[name='published']" should be visible
      And ".view-display-id-results_block .views-row .card" should be visible
      And "main nav[aria-label='Pagination']" should be visible
      And there should be no JavaScript errors

    Examples:
      | width | height |
      | 1440  | 900    |
      | 390   | 844    |

  @check @a11y @local @development @staging @production
  Scenario: Check the filtered search page is labelled and structured
    Given I am an anonymous user
     When I go to "/search?keywords=varbase&f[0]=tags:SEO"
     Then every form field should have an accessible label
      And the page should have exactly one h1
      And the heading hierarchy should be valid
      And the page should have no serious accessibility violations
