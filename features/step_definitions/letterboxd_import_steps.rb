When('I upload my Letterboxd diary CSV') do
  attach_file(
    'letterboxd_file',
    Rails.root.join('spec/fixtures/files/letterboxd_diary.csv')
  )
  click_button 'Import from Letterboxd'
end

When('I start a diary import without attaching a file') do
  click_button 'Import from Letterboxd'
end

Then('I should see the diary import started message') do
  expect(page).to have_content(
    'Import started. Your diary will update shortly once processing finishes.'
  )
end

Then('I should see the diary import attachment warning') do
  expect(page).to have_content(
    'Please attach your Letterboxd CSV export before importing.'
  )
end

When('I upload my Letterboxd ratings CSV') do
  attach_file(
    'letterboxd_ratings_file',
    Rails.root.join('spec/fixtures/files/letterboxd_ratings.csv')
  )
  click_button 'Import ratings'
end

When('I start a ratings import without attaching a file') do
  click_button 'Import ratings'
end
