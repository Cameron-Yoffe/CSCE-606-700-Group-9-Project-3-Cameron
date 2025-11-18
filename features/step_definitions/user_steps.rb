Given('I am on the sign up page') do
  visit sign_up_path
end

Given('a user exists with email {string}') do |email|
  create(:user, email: email)
end

Given('a user exists with username {string}') do |username|
  create(:user, username: username)
end

When('I fill in {string} with {string}') do |label, value|
  fill_in label, with: value
end

When('I click {string}') do |button_text|
  click_button button_text
end

Then('I should see {string}') do |text|
  expect(page).to have_content(text)
end

Then('I should not see {string}') do |text|
  expect(page).not_to have_content(text)
end

Then('I should be on the sign up page') do
  expect(current_path).to eq(sign_up_path)
end

Then('I should be on the dashboard page') do
  expect(current_path).to eq(dashboard_path)
end

Then('the user {string} should exist') do |username|
  expect(User.find_by(username: username)).to be_present
end

Then('I should be logged in as {string}') do |username|
  user = User.find_by(username: username)
  # Check if we're on the dashboard page and the user name is displayed
  expect(page).to have_content("Welcome, #{user.first_name || user.username}")
  expect(current_path).to eq(dashboard_path)
end
