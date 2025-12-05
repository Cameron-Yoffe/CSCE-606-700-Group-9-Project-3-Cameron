Feature: Write Movie Reviews
  As a user
  I want to write and manage reviews for movies
  So that I can share my detailed thoughts and opinions

  Background:
    Given I am a logged in user
    And a movie "Inception" exists in the database

  @javascript
  Scenario: User writes a new review with a rating
    When I visit the movie page for "Inception"
    And I set a rating of 9 out of 10
    And I write a review with text "A mind-bending classic."
    And I submit my movie review
    Then I should see my review text "A mind-bending classic."
    And I should see my username on the review

  @javascript
  Scenario: User edits an existing review
    Given I have previously reviewed "Inception" with text "Initial thoughts."
    When I visit the movie page for "Inception"
    And I edit my review to "Updated impressions."
    And I submit my movie review
    Then I should see my review text "Updated impressions."

  @javascript
  Scenario: User sees validation when review text is empty
    When I visit the movie page for "Inception"
    And I leave the review text blank
    And I submit my movie review
    Then I should see a review validation message "Error saving rating."
