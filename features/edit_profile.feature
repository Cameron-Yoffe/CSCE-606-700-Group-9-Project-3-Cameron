Feature: Edit Profile
  As a user
  I want to be able to edit my profile
  So I can customize my profile, profile picture, and any other editable content

  Background:
    Given the following editable profile user exists:
      | email               | username   | password    | first_name | last_name | bio              |
      | edituser@example.com | edituser   | Password123 | John       | Doe       | Movie enthusiast |
    And I am signed in as editable profile user "edituser" with password "Password123"

  Scenario: User navigates to the edit profile page
    When I visit my profile page for editing
    And I click the edit profile "Edit Profile" link
    Then I should be on the edit profile page
    And I should see "Edit Profile" heading

  Scenario: User sees current profile information on edit page
    When I visit the edit profile page directly
    Then I should see the first name field with "John"
    And I should see the last name field with "Doe"
    And I should see the bio field with "Movie enthusiast"

  Scenario: User updates their first name
    When I visit the edit profile page directly
    And I fill in the first name field with "Jane"
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"
    And I should be on my profile page

  Scenario: User updates their last name
    When I visit the edit profile page directly
    And I fill in the last name field with "Smith"
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"

  Scenario: User updates their bio
    When I visit the edit profile page directly
    And I fill in the bio field with "I love sci-fi and action movies!"
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"
    When I visit my profile page for editing
    Then I should see "I love sci-fi and action movies!" on my profile

  Scenario: User updates their profile image URL
    When I visit the edit profile page directly
    And I fill in the profile image URL with "https://example.com/avatar.jpg"
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"

  Scenario: User enables private account setting
    When I visit the edit profile page directly
    Then I should see "Private Account" setting
    When I enable the private account toggle
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"

  Scenario: User cancels profile edit
    When I visit the edit profile page directly
    And I fill in the first name field with "Changed Name"
    And I click the edit profile cancel link
    Then I should be on my profile page

  Scenario: User sees back to profile link
    When I visit the edit profile page directly
    Then I should see edit profile back link "Back to profile"

  Scenario: User updates multiple fields at once
    When I visit the edit profile page directly
    And I fill in the first name field with "Alice"
    And I fill in the last name field with "Johnson"
    And I fill in the bio field with "Film critic and movie buff"
    And I click the save changes button
    Then I should see profile success message "Profile updated successfully"
    When I visit my profile page for editing
    Then I should see "Film critic and movie buff" on my profile

  Scenario: Edit profile form shows Personal Information section
    When I visit the edit profile page directly
    Then I should see "Personal Information" section heading

  Scenario: Edit profile form shows Privacy Settings section
    When I visit the edit profile page directly
    Then I should see "Privacy Settings" section heading
