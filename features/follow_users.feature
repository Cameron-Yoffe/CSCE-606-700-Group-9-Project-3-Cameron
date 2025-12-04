Feature: Follow Other Users
  As a movie enthusiast
  I want to follow other users
  So that I can see their movie activity and connect with them

  Background:
    Given I am signed in as a user "Alice"
    And there is another user "Bob"

  Scenario: Following a public user
    When I visit Bob's profile
    And I click the "Follow" button
    Then I should see "You are now following Bob"
    And I should see the "Following" button

  Scenario: Unfollowing a user
    Given I am following Bob
    When I visit Bob's profile
    And I click the "Following" button
    Then I should see "You have unfollowed Bob"
    And I should see the "Follow" button

  Scenario: Viewing follower and following counts
    Given I am following Bob
    And Bob is following me
    When I visit my profile
    Then I should see "1 followers"
    And I should see "1 following"

  Scenario: Following a private user sends a request
    Given Bob has a private account
    When I visit Bob's profile
    And I click the profile "Follow" button
    Then I should see "Follow request sent to Bob"
    And I should see the "Requested" button

  Scenario: Private user can accept follow requests
    Given I have a private account
    And Bob has requested to follow me
    When I visit my notifications
    Then I should see "Bob requested to follow you"
    When I click the first "Accept" button
    Then I should see "Follow request accepted"

  Scenario: Private user can decline follow requests
    Given I have a private account
    And Bob has requested to follow me
    When I visit my notifications
    Then I should see "Bob requested to follow you"
    When I click the first "Decline" button
    Then I should see "Follow request from Bob rejected"

  Scenario: Viewing a private profile that I don't follow
    Given Bob has a private account
    When I visit Bob's profile
    Then I should see "This Account is Private"
    And I should not see Bob's activity

  Scenario: Viewing a private profile that I follow
    Given Bob has a private account
    And I am following Bob
    When I visit Bob's profile
    Then I should see Bob's profile information

  Scenario: Receiving notification when someone follows me
    Given Bob follows me
    When I visit my notifications
    Then I should see "Bob started following you"

  Scenario: Receiving notification when follow request is accepted
    Given Bob has a private account
    And I have requested to follow Bob
    When Bob accepts my follow request
    And I visit my notifications
    Then I should see "Bob accepted your follow request"

  Scenario: Viewing followers list
    Given Bob follows me
    And there is another user "Charlie"
    And Charlie follows me
    When I visit my profile
    And I click on the followers link
    Then I should see "Bob" in the followers list
    And I should see "Charlie" in the followers list

  Scenario: Viewing following list
    Given I am following Bob
    And there is another user "Charlie"
    And I am following Charlie
    When I visit my profile
    And I click on the following link
    Then I should see "Bob" in the following list
    And I should see "Charlie" in the following list
