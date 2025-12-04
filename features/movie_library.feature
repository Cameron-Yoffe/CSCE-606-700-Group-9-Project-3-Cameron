Feature: Add Movie to My Library
  As a user
  I want to add a movie I found in search to my library
  So that I can log it later

  Background:
    Given I am a logged in user

  Scenario: User adds a movie to library from search results
    When I visit the movie search page
    And I search for movie "Inception"
    Then I should see an "Add" button for the movie
    When I click the "Add" button for the first movie
    Then I should see "Added to your library"
    And the button should change to "Remove"

  Scenario: User removes a movie from library
    Given I have "Inception" in my library
    When I visit the movie search page
    And I search for movie "Inception"
    Then I should see a "Remove" button for the movie
    When I click the "Remove" button for the first movie
    Then I should see "Removed from your library"
    And the button should change to "Add"

  Scenario: Movie appears in My Library page after adding
    When I visit the movie search page
    And I search for movie "The Matrix"
    And I click the "Add" button for the first movie
    And I visit my library page
    Then I should see "The Matrix" in my library

  Scenario: Button toggles between Add and Remove states
    When I visit the movie search page
    And I search for movie "Pulp Fiction"
    Then I should see an "Add" button for the movie
    When I click the "Add" button for the first movie
    Then the button should change to "Remove"
    When I click the "Remove" button for the first movie
    Then the button should change to "Add"

  Scenario: User can access My Library from dashboard
    When I visit the dashboard
    Then I should see a "My Library" link
    When I click on the "My Library" link
    Then I should be on the library page
