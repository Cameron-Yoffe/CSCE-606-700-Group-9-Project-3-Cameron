Rails.application.configure do
  config.x.tmdb = ActiveSupport::OrderedOptions.new

  config.x.tmdb.base_url = "https://api.themoviedb.org/3"
  config.x.tmdb.default_language = "en-US"
  # TMDB will allow 40 requests per 10 seconds with the non-commercial tier
  config.x.tmdb.request_interval = 0.26
  config.x.tmdb.api_key = Rails.application.credentials.dig(:tmdb, :api_key)
end
