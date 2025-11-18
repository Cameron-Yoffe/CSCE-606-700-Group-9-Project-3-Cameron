Feature: User Sign Up
  As a visitor
  I want to sign up for an account
  So that I can create my movie diary and track my viewing history

  Background:
    Given I am on the sign up page

  Scenario: Successful sign up with valid information
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser123"
    And I fill in "First Name (Optional)" with "John"
    And I fill in "Last Name (Optional)" with "Doe"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "Account created successfully"
    And I should be on the dashboard page
    And the user "newuser123" should exist

  Scenario: Sign up fails with invalid email
    When I fill in "Email Address" with "invalid-email"
    And I fill in "Username" with "validuser"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "must be a valid email address"
    And I should be on the sign up page

  Scenario: Sign up fails with duplicate email
    Given a user exists with email "existing@example.com"
    When I fill in "Email Address" with "existing@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "has already been taken"
    And I should be on the sign up page

  Scenario: Sign up fails with duplicate username
    Given a user exists with username "existinguser"
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "existinguser"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "has already been taken"
    And I should be on the sign up page

  Scenario: Sign up fails with weak password
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "weak"
    And I fill in "Confirm Password" with "weak"
    And I click "Sign Up"
    Then I should see "must be at least 8 characters"
    And I should be on the sign up page

  Scenario: Sign up fails with password missing uppercase letter
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "lowercase123"
    And I fill in "Confirm Password" with "lowercase123"
    And I click "Sign Up"
    Then I should see "must include at least one uppercase letter"
    And I should be on the sign up page

  Scenario: Sign up fails with password missing lowercase letter
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "UPPERCASE123"
    And I fill in "Confirm Password" with "UPPERCASE123"
    And I click "Sign Up"
    Then I should see "must include at least one uppercase letter"
    And I should be on the sign up page

  Scenario: Sign up fails with password missing number
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "NoNumbers!"
    And I fill in "Confirm Password" with "NoNumbers!"
    And I click "Sign Up"
    Then I should see "must include at least one uppercase letter"
    And I should be on the sign up page

  Scenario: Sign up fails with mismatched passwords
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "DifferentPass123"
    And I click "Sign Up"
    Then I should see "doesn't match"
    And I should be on the sign up page

  Scenario: Username must be between 3 and 20 characters
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "ab"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "must be between 3 and 20 characters"
    And I should be on the sign up page

  Scenario: Optional fields are not required
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should see "Account created successfully"
    And I should be on the dashboard page

  Scenario: User is logged in after successful sign up
    When I fill in "Email Address" with "newuser@example.com"
    And I fill in "Username" with "newuser123"
    And I fill in "Password" with "ValidPass123"
    And I fill in "Confirm Password" with "ValidPass123"
    And I click "Sign Up"
    Then I should be logged in as "newuser123"
