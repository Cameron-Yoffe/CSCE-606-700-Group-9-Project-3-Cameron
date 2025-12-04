Feature: Manage Custom Lists
  As a logged-in user
  I want to manage custom movie lists
  So that I can organize my library into collections

  Background:
    Given I am a logged in user

  @javascript
  Scenario: User creates a new custom list
    When I visit my library page
    And I open the new list modal
    And I fill out the new list form with name "Weekend Picks" and description "Movies for the weekend"
    And I submit the new list form
    Then I should see "List created"
    And I should see a tab for list "Weekend Picks"

  @javascript
  Scenario: User views a custom list with movies
    Given I have a custom list named "Favorites" with movie "Inception"
    When I visit my library page
    And I switch to the "Favorites" list tab
    Then I should see "Inception"

  @javascript
  Scenario: User deletes a custom list
    Given I have a custom list named "Temporary List" with movie "Inception"
    When I visit my library page
    And I switch to the "Temporary List" list tab
    And I delete the current custom list
    Then I should see "List deleted"
    And I should not see "Temporary List"
