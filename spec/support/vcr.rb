# frozen_string_literal: true

require "vcr"
require "webmock/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.hook_into :webmock
  config.ignore_localhost = true
  config.configure_rspec_metadata!

  # Filter the TMDB API key from cassettes and logs
  config.filter_sensitive_data("<TMDB_API_KEY>") { ENV["TMDB_API_KEY"] || "test_api_key" }

  # Match requests ignoring the API key query parameter for robustness
  config.register_request_matcher :uri_without_api_key do |request_1, request_2|
    uri1 = URI(request_1.uri)
    uri2 = URI(request_2.uri)
    params1 = URI.decode_www_form(uri1.query || "").reject { |k, _| k == "api_key" }
    params2 = URI.decode_www_form(uri2.query || "").reject { |k, _| k == "api_key" }
    uri1.path == uri2.path && params1.sort == params2.sort
  end

  config.default_cassette_options = {
    record: :once,
    match_requests_on: [ :method, :uri_without_api_key ]
  }
end

WebMock.disable_net_connect!(allow_localhost: true)
