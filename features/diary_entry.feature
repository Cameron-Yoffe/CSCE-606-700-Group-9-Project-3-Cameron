Feature: Log a Diary Entry
  As a user
  I want to record or favorite a movie
  So that I can track my favorite listing

  Background:
    Given I am a logged in user
    And a movie "Inception" exists in the database

  Scenario: User can access the diary entry form
    When I visit the new diary entry page for "Inception"
    Then I should see "Log Movie"
    And I should see a date field defaulting to today
    And I should see a notes field
    And I should see a tags field

  Scenario: User creates a diary entry with viewing date
    When I visit the new diary entry page for "Inception"
    And I fill in the viewing date with "2025-01-15"
    And I fill in notes with "Watched it again"
    And I submit the diary entry form
    Then I should see "Diary entry created successfully"
    And I should be on the diary page

  Scenario: User creates a diary entry with notes
    When I visit the new diary entry page for "Inception"
    And I fill in notes with "Amazing movie, loved the concept!"
    And I submit the diary entry form
    Then I should see "Diary entry created successfully"

  Scenario: User creates a diary entry with tags
    When I visit the new diary entry page for "Inception"
    And I fill in notes with "Great film"
    And I fill in tags with "mind-bending, sci-fi, thriller"
    And I submit the diary entry form
    Then I should see "Diary entry created successfully"

  Scenario: Diary entries show on the Diary page with movie poster and date
    Given I have a diary entry for "Inception" watched on "2025-01-15"
    When I visit the diary page
    Then I should see "Inception"
    And I should see "January 15, 2025"
    And I should see a movie poster

  Scenario: User can view their diary entries list
    Given I have the following diary entries:
      | movie       | watched_date |
      | Inception   | 2025-01-15   |
      | The Matrix  | 2025-01-10   |
    When I visit the diary page
    Then I should see "Inception"
    And I should see "The Matrix"
    And I should see "My Diary"

  Scenario: User can edit a diary entry
    Given I have a diary entry for "Inception" watched on "2025-01-15"
    When I visit the diary page
    And I click "Edit" for the diary entry
    Then I should see "Edit Diary Entry"

  Scenario: User can delete a diary entry
    Given I have a diary entry for "Inception" watched on "2025-01-15"
    When I visit the diary page
    And I click "Delete" for the diary entry
    Then I should see "Diary entry deleted successfully"
