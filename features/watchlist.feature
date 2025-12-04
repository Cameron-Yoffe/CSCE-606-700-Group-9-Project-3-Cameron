Feature: Add a Movie to Watchlist
  As a user
  I want to add/remove a movie to a watchlist
  So that I can find movies I want to watch easily

  Background:
    Given I am a logged in user

  Scenario: User adds a movie to watchlist from search
    When I visit the movie search page
    And I search for movie "Inception"
    Then I should see an "Add" button for the movie
    When I click the "Add" button for the first movie
    Then I should see "Added to your library"

  Scenario: User removes a movie from watchlist
    Given I have "Inception" in my watchlist
    When I visit the movie search page
    And I search for movie "Inception"
    Then I should see a "Remove" button for the movie
    When I click the "Remove" button for the first movie
    Then I should see "Removed from your library"

  Scenario: Watchlist button toggles between Add and Remove
    When I visit the movie search page
    And I search for movie "The Matrix"
    Then I should see an "Add" button for the movie
    When I click the "Add" button for the first movie
    Then the button should change to "Remove"
    When I click the "Remove" button for the first movie
    Then the button should change to "Add"

  Scenario: Watchlist shows movie poster and title
    Given I have "Inception" in my watchlist
    When I visit my library page
    Then I should see "Inception" in my library
    And I should see a movie poster in the library

  Scenario: Movie is auto-removed from watchlist when logged as watched
    Given I have "Inception" in my watchlist
    When I log "Inception" as watched with notes "Finally watched it!"
    Then I should see "Diary entry created successfully"
    When I visit my library page
    Then I should not see "Inception" in the watchlist section

  Scenario: User can access watchlist from dashboard
    When I visit the dashboard
    Then I should see a "My Library" link
    When I click on the "My Library" link
    Then I should be on the library page
