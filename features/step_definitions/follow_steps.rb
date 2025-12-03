# frozen_string_literal: true

Given("I am signed in as a user {string}") do |username|
  @current_user = User.create!(
    email: "#{username.downcase}@example.com",
    username: username,
    password: "SecurePass123",
    password_confirmation: "SecurePass123"
  )
  visit sign_in_path
  fill_in "email", with: @current_user.email
  fill_in "password", with: "SecurePass123"
  click_button "Sign In"
end

Given("there is another user {string}") do |username|
  @other_users ||= {}
  @other_users[username] = User.create!(
    email: "#{username.downcase}@example.com",
    username: username,
    password: "SecurePass123",
    password_confirmation: "SecurePass123"
  )
end

Given("I am following Bob") do
  bob = @other_users["Bob"]
  @current_user.follow(bob)
end

Given("I am following {word}") do |username|
  user = @other_users[username]
  @current_user.follow(user)
end

Given("Bob is following me") do
  bob = @other_users["Bob"]
  bob.follow(@current_user)
end

Given("Bob follows me") do
  bob = @other_users["Bob"]
  bob.follow(@current_user)
end

Given("{word} follows me") do |username|
  user = @other_users[username]
  user.follow(@current_user)
end

Given("Bob has a private account") do
  bob = @other_users["Bob"]
  bob.update!(is_private: true)
end

Given("I have a private account") do
  @current_user.update!(is_private: true)
end

Given("Bob has requested to follow me") do
  bob = @other_users["Bob"]
  Follow.create!(follower: bob, followed: @current_user, status: "pending")
end

Given("I have requested to follow Bob") do
  bob = @other_users["Bob"]
  Follow.create!(follower: @current_user, followed: bob, status: "pending")
end

When("I visit Bob's profile") do
  bob = @other_users["Bob"]
  visit user_profile_path(bob)
end

When("I visit {word}'s profile") do |username|
  user = @other_users[username]
  visit user_profile_path(user)
end

When("I visit my profile") do
  visit profile_path
end

When("I visit my notifications") do
  visit notifications_path
end

When("I click the {string} button") do |button_text|
  click_button button_text
end

When("I click {string}") do |link_text|
  click_on link_text
end

When("I click on {string}") do |link_text|
  click_link link_text
end

When("Bob accepts my follow request") do
  bob = @other_users["Bob"]
  follow = Follow.find_by(follower: @current_user, followed: bob)
  follow.accept!
end

Then("I should see {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should see the {string} button") do |button_text|
  expect(page).to have_button(button_text)
end

Then("I should not see Bob's activity") do
  # Private profiles should not show diary entries, ratings, etc.
  expect(page).not_to have_css("[data-testid='diary-entries']")
  expect(page).not_to have_css("[data-testid='activity-feed']")
end

Then("I should see Bob's profile information") do
  bob = @other_users["Bob"]
  expect(page).to have_content(bob.username)
end

Then("I should see {string} in the followers list") do |username|
  within("[data-testid='followers-list']") do
    expect(page).to have_content(username)
  end
end

Then("I should see {string} in the following list") do |username|
  within("[data-testid='following-list']") do
    expect(page).to have_content(username)
  end
end
