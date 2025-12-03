Feature: Activity Feed
  As a movie enthusiast
  I want to see an activity feed of my followed users
  So that I can stay updated on their movie activity

  Background:
    Given I am signed in as a user "Alice"
    And there is another user "Bob"
    And Alice is following Bob

  Scenario: Viewing diary entries in the activity feed
    Given Bob has logged a movie "The Dark Knight" in their diary
    When I visit my dashboard
    Then I should see "Bob" in the activity feed
    And I should see "logged" in the activity feed
    And I should see "The Dark Knight" in the activity feed

  Scenario: Viewing ratings in the activity feed
    Given Bob has rated "Inception" with 8 out of 10
    When I visit my dashboard
    Then I should see "Bob" in the activity feed
    And I should see "rated" in the activity feed
    And I should see "Inception" in the activity feed

  Scenario: Viewing review reactions in the activity feed
    Given there is another user "Charlie"
    And Alice is following Charlie
    And Bob has rated "Interstellar" with a review
    And Charlie has reacted to Bob's review with an emoji
    When I visit my dashboard
    Then I should see "Charlie" in the activity feed
    And I should see "reacted" in the activity feed

  Scenario: Activity feed shows only followed users
    Given there is another user "Charlie"
    And Charlie has logged a movie "Avatar" in their diary
    When I visit my dashboard
    Then I should not see "Charlie" in the activity feed
    And I should not see "Avatar" in the activity feed

  Scenario: Empty activity feed when not following anyone
    Given Alice unfollows Bob
    When I visit my dashboard
    Then I should see "No activity yet" on the page
    And I should see "Follow some users to see their movie activity" on the page

  Scenario: Refreshing the activity feed
    Given Bob has logged a movie "The Matrix" in their diary
    When I visit my dashboard
    Then I should see a refresh button in the activity feed
