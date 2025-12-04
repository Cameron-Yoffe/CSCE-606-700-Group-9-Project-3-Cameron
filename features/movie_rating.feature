Feature: Rate a Movie
  As a user
  I want to set a star rating for a movie
  So I can track how much I enjoyed a movie

  Background:
    Given I am a logged in user

  Scenario: User can see the rating form on movie page
    When I visit the movie page for "Inception"
    Then I should see "Your Rating"
    And I should see "Rate this movie"
    And I should see star rating buttons

  Scenario: User can rate a movie
    When I visit the movie page for "Inception"
    And I set a rating of 8 out of 10
    And I click "Save Rating & Review"
    Then I should see "Rating saved successfully"

  Scenario: Rating is displayed on movie page
    Given I have rated "Inception" with 8 out of 10
    When I visit the movie page for "Inception"
    Then I should see my previous rating displayed
    And I should see "Your previous rating"

  Scenario: User can edit their rating
    Given I have rated "Inception" with 6 out of 10
    When I visit the movie page for "Inception"
    And I set a rating of 9 out of 10
    And I click "Update Rating & Review"
    Then I should see "Rating updated successfully"

  Scenario: User can add a review with their rating
    When I visit the movie page for "Inception"
    And I set a rating of 8 out of 10
    And I fill in the review with "Amazing movie! The concept is mind-blowing."
    And I click "Save Rating & Review"
    Then I should see "Rating saved successfully"

  Scenario: Non-logged in user sees sign in prompt
    Given I am not logged in
    When I visit the movie search page
    And I search for movie "Inception"
    And I click on "View details" for the first result
    Then I should see "Sign in"
