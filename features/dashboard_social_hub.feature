Feature: Dashboard social hub and activity feed
  As a user
  I want to view an activity feed for users I follow
  So that I can keep up with their movie activity and reviews

  Scenario: Signed-in users land on the dashboard
    Given I am a logged in user
    When I visit the root page
    Then I should be on the dashboard
    And I should see "Activity Feed"

  Scenario: Guests see the landing page
    When I visit the root page
    Then I should see "Movie Diary"

  Scenario: Activity feed shows reactions and controls
    Given I am signed in as a user "Alice"
    And there is another user "Bob"
    And there is another user "Charlie"
    And Alice is following Bob
    And Alice is following Charlie
    And Bob has rated "Inception" with a review
    And Charlie has reacted to Bob's review with an emoji
    And I have a movie "The Iron Giant" on my watchlist
    When I visit my dashboard
    Then I should see "Inception" in the activity feed
    And I should see "👍" in the activity feed
    And I should see a new activity indicator
    And I should see a "Mark all as read" button
    And the watchlist should be managed from my favorites library
