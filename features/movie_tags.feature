Feature: Add Tags to a Movie
  As a logged-in user
  I want to add tags to movies in my library
  So that I can categorize and organize my movie collection

  Background:
    Given the following tag user exists:
      | email              | username | password    |
      | taguser@example.com | taguser  | Password123 |
    And I am signed in as tag user "taguser" with password "Password123"
    And a movie exists in the user's library with title "The Dark Knight"
    And predefined tags exist in the database

  @javascript
  Scenario: User sees the Tags section on a movie page
    When I visit the movie tags page for "The Dark Knight"
    Then I should see the Tags section
    And I should see the main category buttons

  @javascript
  Scenario: User views predefined tag categories
    When I visit the movie tags page for "The Dark Knight"
    Then I should see category button "comedy"
    And I should see category button "action"
    And I should see category button "thriller"
    And I should see category button "horror"
    And I should see category button "romantic"
    And I should see category button "drama"
    And I should see category button "sci-fi"
    And I should see category button "fantasy"

  @javascript
  Scenario: User clicks a category to see subcategories
    When I visit the movie tags page for "The Dark Knight"
    And I click the category button "action"
    Then I should see the subcategories container
    And I should see subcategory tags for "action"

  @javascript
  Scenario: User adds a tag to a movie
    When I visit the movie tags page for "The Dark Knight"
    And I click the category button "action"
    And I click to add the "action" tag
    Then I should see the tag "action" displayed on the movie
    And the tag should appear as a chip with a remove button

  @javascript
  Scenario: User cannot add the same tag twice
    Given the movie "The Dark Knight" has the tag "action"
    When I visit the movie tags page for "The Dark Knight"
    Then I should see the tag "action" displayed on the movie
    When I click the category button "action"
    And I click to add the "action" tag
    Then I should still only see one instance of "action" tag

  @javascript
  Scenario: User removes a tag from a movie
    Given the movie "The Dark Knight" has the tag "action"
    When I visit the movie tags page for "The Dark Knight"
    Then I should see the tag "action" displayed on the movie
    When I click the remove button for the tag "action"
    Then the tag "action" should be removed from the movie

  @javascript
  Scenario: Tags are displayed in the user's library
    Given the movie "The Dark Knight" has the tag "action"
    And the movie "The Dark Knight" has the tag "thriller"
    When I visit my tags library page
    Then I should see movie "The Dark Knight" in library
    And I should see the movie's tags displayed

  Scenario: Guest user cannot add tags
    Given I am a guest user for tags
    When I visit the movie tags page for "The Dark Knight"
    Then I should not see the add tags section
    And I should see a prompt to sign in to add tags

  @javascript
  Scenario: Tags are stored case-insensitively
    When I visit the movie tags page for "The Dark Knight"
    And I click the category button "action"
    And I click to add the "action" tag
    Then I should see the tag "action" displayed on the movie in lowercase
