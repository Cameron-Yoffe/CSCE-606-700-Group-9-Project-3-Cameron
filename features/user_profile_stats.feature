Feature: User Profile Page and Stats
  As a user
  I want a profile page that shows my activity and stats
  So that I can track my movie habits

  Background:
    Given the following profile user exists:
      | email                | username    | password    | bio                    |
      | profile@example.com  | moviefan    | Password123 | I love watching films! |
    And I am signed in as profile user "moviefan" with password "Password123"

  Scenario: User sees their username and bio on profile
    When I visit my user profile page
    Then I should see the username "moviefan" on the profile
    And I should see the bio "I love watching films!" on the profile

  Scenario: User sees their avatar placeholder when no image is set
    When I visit my user profile page
    Then I should see an avatar placeholder with the letter "M"

  Scenario: User sees diary count on profile
    Given the profile user has logged 5 diary entries
    When I visit my user profile page
    Then I should see "Diary entries" stat section
    And I should see the diary count "5"

  Scenario: User sees yearly movies logged count
    Given the profile user has logged 3 movies this year
    When I visit my user profile page
    Then I should see "This year" stat section
    And I should see the yearly count "3"

  Scenario: User sees average rating on profile
    Given the profile user has rated movies with an average of 8.5
    When I visit my user profile page
    Then I should see "Average rating" stat section
    And I should see the average rating displayed

  Scenario: User sees favorite genres auto-calculated
    Given the profile user has logged movies with genres:
      | genre   | count |
      | Action  | 5     |
      | Drama   | 3     |
      | Comedy  | 2     |
    When I visit my user profile page
    Then I should see "Favorite genres" section
    And I should see "Action" in the favorite genres
    And I should see "Auto-calculated" badge

  Scenario: User sees favorite directors auto-calculated
    Given the profile user has logged movies directed by:
      | director           | count |
      | Christopher Nolan  | 4     |
      | Steven Spielberg   | 2     |
    When I visit my user profile page
    Then I should see "Favorite directors" section
    And I should see "Christopher Nolan" in the favorite directors

  @javascript
  Scenario: User sees monthly chart for movies logged
    Given the profile user has logged movies this year
    When I visit my user profile page
    Then I should see "Movies logged this year" section
    And I should see a bar chart canvas

  @javascript
  Scenario: User sees genre breakdown pie chart
    Given the profile user has logged movies with multiple genres
    When I visit my user profile page
    Then I should see "Genre breakdown" section
    And I should see a pie chart canvas

  Scenario: User sees followers and following counts
    Given the profile user has 10 followers
    And the profile user is following 5 users
    When I visit my user profile page
    Then I should see "10" followers count
    And I should see "5" following count

  Scenario: User sees member since date
    When I visit my user profile page
    Then I should see "Member since" on the profile

  Scenario: User can navigate to edit profile
    When I visit my user profile page
    Then I should see an "Edit Profile" link

  Scenario: Profile shows empty state for genres when no movies logged
    When I visit my user profile page
    Then I should see "Log a few movies to see your top genres"

  Scenario: Profile shows empty state for directors when no movies logged
    When I visit my user profile page
    Then I should see "Your most-watched directors will appear here"
