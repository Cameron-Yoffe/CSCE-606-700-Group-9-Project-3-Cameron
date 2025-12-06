Feature: Import Letterboxd Diary
  As a user
  I want to be able to import my diary from Letterboxd
  So that I don't lose my previous data

  Background:
    Given I am a logged in user
    And I visit my profile

  Scenario: Start a diary import with a CSV export
    When I upload my Letterboxd diary CSV
    Then I should see the diary import started message

  Scenario: Warn when trying to import without a file
    When I start a diary import without attaching a file
    Then I should see the diary import attachment warning
