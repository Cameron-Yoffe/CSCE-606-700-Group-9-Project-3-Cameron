# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tmdb::Client do
  let(:client) do
    described_class.new(
      api_key: Rails.application.config.x.tmdb.api_key,
      request_interval: 0
    )
  end

  describe "#movie" do
    it "fetches movie details and returns parsed JSON",
       vcr: { cassette_name: "tmdb/movie_success" } do
      movie = client.movie(550)

      expect(movie["id"]).to eq(550)
      expect(movie["title"]).to eq("Fight Club")
    end

    it "raises not found error for missing movie",
       vcr: { cassette_name: "tmdb/movie_not_found" } do
      expect { client.movie(0) }
        .to raise_error(Tmdb::NotFoundError, /not found/i)
    end
  end

  describe ".new" do
    it "raises authentication error when api key missing" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(Tmdb::AuthenticationError, /missing/i)
    end
  end
end
