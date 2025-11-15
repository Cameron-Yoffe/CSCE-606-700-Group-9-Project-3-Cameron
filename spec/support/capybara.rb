require 'capybara/rails'
require 'capybara/rspec'

Capybara.default_driver = :selenium_chrome_headless
Capybara.app_host = 'http://localhost:3000'
Capybara.default_max_wait_time = 5

# Configure Chrome options for headless testing
Capybara.register_driver :selenium_chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument('--headless')
  options.add_argument('--no-sandbox')
  options.add_argument('--disable-dev-shm-usage')
  options.add_argument('--disable-gpu')
  options.add_argument('--window-size=1920,1080')

  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end
