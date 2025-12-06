Feature: Import Letterboxd Ratings
  As a user
  I want to be able to import my Letterboxd ratings
  So that I do not lose any of my data

  Background:
    Given I am a logged in user
    And I visit my profile

  Scenario: Start a ratings import with a CSV export
    When I upload my Letterboxd ratings CSV
    Then I should see "Import started. Your ratings will update shortly once processing finishes."

  Scenario: Warn when trying to import ratings without a file
    When I start a ratings import without attaching a file
    Then I should see "Please attach your Letterboxd ratings CSV export before importing."
