Feature: Top 5 Movies on Profile
  As a user
  I want to showcase my top 5 favorite movies on my profile
  So that others can see my favorite movies at a glance

  Background:
    Given the following user exists:
      | email              | username    | password      |
      | user@example.com   | moviefan    | SecurePass123 |
    And the following movies exist:
      | title           | tmdb_id |
      | The Godfather   | 238     |
      | Inception       | 27205   |
      | Interstellar    | 157336  |
      | The Dark Knight | 155     |
      | Pulp Fiction    | 680     |
      | Fight Club      | 550     |
    And I am signed in as "moviefan" with password "SecurePass123"

  Scenario: User sees empty top 5 movies slots on profile
    When I visit my profile page
    Then I should see "Top Movies"
    And I should see 5 empty movie slots
    And each empty slot should have a position number from 1 to 5

  @javascript
  Scenario: User adds a favorite movie to top 5
    Given I have favorited "The Godfather"
    And I have favorited "Inception"
    When I visit my profile page
    And I click on position 1 slot
    Then I should see a modal to select a movie
    And I should see "The Godfather" in my favorites list
    And I should see "Inception" in my favorites list

  @javascript
  Scenario: User sets a movie to top position 1
    Given I have favorited "The Godfather"
    When I visit my profile page
    And I click on position 1 slot
    And I select "The Godfather" from the favorites list
    Then "The Godfather" should appear in position 1
    And position 1 slot should show the movie poster

  @javascript
  Scenario: User sets multiple movies to top 5
    Given I have favorited the following movies:
      | title           |
      | The Godfather   |
      | Inception       |
      | Interstellar    |
    When I visit my profile page
    And I add "The Godfather" to position 1
    And I add "Inception" to position 2
    And I add "Interstellar" to position 3
    Then I should see all 3 movies in their respective positions
    And positions 4 and 5 should be empty

  @javascript
  Scenario: User removes a movie from top 5
    Given I have the following movies in my top 5:
      | title         | position |
      | The Godfather | 1        |
      | Inception     | 2        |
    When I visit my profile page
    And I hover over position 1
    And I click the remove button
    And I confirm the removal
    Then position 1 should be empty
    And "Inception" should still be in position 2

  @javascript
  Scenario: User can only have 5 movies in top positions
    Given I have favorited 10 movies
    When I visit my profile page
    Then I should see exactly 5 top movie slots
    And I should not be able to add more than 5 movies to top positions

  @javascript
  Scenario: Replacing a movie in a filled position
    Given I have the following movies in my top 5:
      | title         | position |
      | The Godfather | 1        |
    And I have favorited "Inception"
    When I visit my profile page
    And I hover over position 1
    And I click the remove button
    And I confirm the removal
    And I click on position 1 slot
    And I select "Inception" from the favorites list
    Then "Inception" should appear in position 1

  @javascript
  Scenario: Top movies are visible to the user
    Given I have the following movies in my top 5:
      | title           | position |
      | The Godfather   | 1        |
      | Inception       | 2        |
      | Interstellar    | 3        |
      | The Dark Knight | 4        |
      | Pulp Fiction    | 5        |
    When I visit my profile page
    Then I should see "The Godfather" in position 1
    And I should see "Inception" in position 2
    And I should see "Interstellar" in position 3
    And I should see "The Dark Knight" in position 4
    And I should see "Pulp Fiction" in position 5

  @javascript
  Scenario: User can search for movies to add to favorites first
    When I visit my profile page
    And I click on position 1 slot
    Then I should see a search input
    When I search for "Matrix"
    Then I should see search results

  @javascript
  Scenario: Empty slots show plus icon and position badge
    When I visit my profile page
    Then each empty slot should show a plus icon
    And each slot should display its position number

  @javascript
  Scenario: Filled slots show movie poster and position badge
    Given I have "The Godfather" in position 1
    When I visit my profile page
    Then position 1 should show "The Godfather" poster
    And position 1 should display the number "1"
