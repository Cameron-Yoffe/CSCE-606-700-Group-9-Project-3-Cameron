Feature: Search for a Movie (TMDB)
  As a user
  I want to search for movies by title
  So that I can find movies to log or add to my library

  Background:
    Given I am a logged in user

  Scenario: User can access the movie search page
    When I visit the movie search page
    Then I should see "Movie Search"
    And I should see "Find a movie by title"
    And I should see a search input field

  Scenario: User searches for a movie and sees results
    When I visit the movie search page
    And I search for movie "Inception"
    Then I should see search results for "Inception"
    And I should see movie titles in the results
    And I should see "View details" links

  Scenario: User searches with empty query
    When I visit the movie search page
    And I search for movie ""
    Then I should see "Please enter a movie title to search"

  Scenario: User searches for a movie with no results
    When I visit the movie search page
    And I search for movie "xyznonexistentmovie12345"
    Then I should see "No results found"

  Scenario: User can view movie details from search results
    When I visit the movie search page
    And I search for movie "The Godfather"
    And I click on "View details" for the first result
    Then I should be on a movie detail page
    And I should see movie information

  Scenario: Search results display movie information
    When I visit the movie search page
    And I search for movie "Pulp Fiction"
    Then I should see search results for "Pulp Fiction"
    And each result should display the movie title
    And each result should display the release year
