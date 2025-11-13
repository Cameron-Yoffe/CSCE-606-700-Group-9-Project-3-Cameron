# frozen_string_literal: true

require "test_helper"

module Tmdb
  class ClientTest < ActiveSupport::TestCase
    setup do
      @client = Client.new(api_key: "test_api_key", request_interval: 0)
    end

    test "fetches movie details" do
      VCR.use_cassette("tmdb/movie_success") do
        movie = @client.movie(550)

        assert_equal 550, movie["id"]
        assert_equal "Fight Club", movie["title"]
      end
    end

    test "raises not found error for missing movie" do
      VCR.use_cassette("tmdb/movie_not_found") do
        error = assert_raises(Tmdb::NotFoundError) { @client.movie(0) }
        assert_match(/not found/i, error.message)
      end
    end

    test "raises authentication error when api key missing" do
      error = assert_raises(Tmdb::AuthenticationError) { Client.new(api_key: nil) }
      assert_match(/missing/i, error.message)
    end
  end
end
