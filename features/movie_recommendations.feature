Feature: Basic Movie Recommendations
  As a user
  I want to see basic movie recommendations based on my ratings
  So that I can discover movies I might enjoy

  Background:
    Given I am a logged in user
    And I have rated the following movies:
      | title           | rating | year |
      | Inception       | 9      | 2010 |
      | The Dark Knight | 8      | 2008 |

  Scenario: View personalized recommendations
    Given I have recommendations ready:
      | title         | tmdb_id | year |
      | Interstellar  | 157336  | 2014 |
      | Dunkirk       | 374720  | 2017 |
    When I visit the recommendations page
    Then I should see "Discover your next watch"
    And I should see "Tap a button to start curating your picks."
    And I should see 2 recommendations in the deck
    And I should see a reload suggestions button

  Scenario: See status while recommendations are being prepared
    Given I have a pending recommendation run
    When I visit the recommendations page
    Then I should see that recommendations are being prepared
    And I should see 0 recommendations in the deck
