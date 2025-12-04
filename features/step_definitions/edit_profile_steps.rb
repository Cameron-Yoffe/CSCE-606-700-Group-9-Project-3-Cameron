# Step definitions for US-110: Edit Profile

Given("the following editable profile user exists:") do |table|
  table.hashes.each do |row|
    @edit_profile_user = User.create!(
      email: row['email'],
      username: row['username'],
      password: row['password'],
      password_confirmation: row['password'],
      first_name: row['first_name'],
      last_name: row['last_name'],
      bio: row['bio']
    )
  end
end

Given("I am signed in as editable profile user {string} with password {string}") do |username, password|
  @edit_profile_user = User.find_by(username: username)
  visit sign_in_path
  fill_in 'email', with: @edit_profile_user.email
  fill_in 'password', with: password
  click_button 'Sign In'
end

When("I visit my profile page for editing") do
  visit profile_path
end

When("I click the edit profile {string} link") do |link_text|
  click_link link_text
end

Then("I should be on the edit profile page") do
  expect(current_path).to eq(profile_edit_path)
end

Then("I should see {string} heading") do |heading|
  expect(page).to have_css("h1, h2", text: heading)
end

When("I visit the edit profile page directly") do
  visit profile_edit_path
end

Then("I should see the first name field with {string}") do |value|
  expect(page).to have_field("First name", with: value)
end

Then("I should see the last name field with {string}") do |value|
  expect(page).to have_field("Last name", with: value)
end

Then("I should see the bio field with {string}") do |value|
  expect(page).to have_field("Bio", with: value)
end

When("I fill in the first name field with {string}") do |value|
  fill_in "First name", with: value
end

When("I fill in the last name field with {string}") do |value|
  fill_in "Last name", with: value
end

When("I fill in the bio field with {string}") do |value|
  fill_in "Bio", with: value
end

When("I fill in the profile image URL with {string}") do |value|
  fill_in "Profile Image URL", with: value
end

When("I click the save changes button") do
  click_button "Save Changes"
end

Then("I should see profile success message {string}") do |text|
  expect(page).to have_content(text)
end

Then("I should be on my profile page") do
  expect(current_path).to eq(profile_path)
end

Then("I should see {string} on my profile") do |text|
  expect(page).to have_content(text)
end

Then("I should see {string} setting") do |setting_name|
  expect(page).to have_content(setting_name)
end

When("I enable the private account toggle") do
  check "user_is_private"
end

When("I click the edit profile cancel link") do
  click_link "Cancel"
end

Then("I should see edit profile back link {string}") do |link_text|
  expect(page).to have_link(link_text)
end

Then("I should see {string} section heading") do |section_title|
  expect(page).to have_css("h2", text: section_title)
end
