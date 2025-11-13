# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  tmdb_api_key = Rails.application.config.x.tmdb.api_key
  config.filter_sensitive_data("<TMDB_API_KEY>") { tmdb_api_key if tmdb_api_key.present? }

  config.default_cassette_options = { record: :once }
end

WebMock.disable_net_connect!(allow_localhost: true)
