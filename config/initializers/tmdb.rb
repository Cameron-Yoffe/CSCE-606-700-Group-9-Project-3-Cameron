Rails.application.configure do
  config.x.tmdb = ActiveSupport::OrderedOptions.new

  config.x.tmdb.base_url = "https://api.themoviedb.org/3"
  config.x.tmdb.default_language = "en-US"
  # TMDB will allow 40 requests per 10 seconds with the non-commercial tier
  config.x.tmdb.request_interval = 0.26

  grading_key = "9ee1e9af5ccf586991e69709215e4740"

  tmdb_api_key = ENV["TMDB_API_KEY"].presence ||
                 Rails.application.credentials.dig(:tmdb, :api_key).presence ||
                 grading_key

  config.x.tmdb.api_key = tmdb_api_key
end

# Ensure code paths referencing ENV still work without changes.
ENV["TMDB_API_KEY"] ||= Rails.application.config.x.tmdb.api_key
