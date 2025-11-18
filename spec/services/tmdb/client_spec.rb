# frozen_string_literal: true

require "rails_helper"

RSpec.describe Tmdb::Client do
  let(:client) do
    described_class.new(
      api_key: ENV.fetch("TMDB_API_KEY", "test_api_key"),
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

    it "uses the system certificate store for HTTPS requests" do
      cert_store = instance_double(OpenSSL::X509::Store, set_default_paths: true, add_file: true)
      allow(OpenSSL::X509::Store).to receive(:new).and_return(cert_store)

      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).with("api.themoviedb.org", 443).and_return(http)

      allow(http).to receive(:use_ssl?).and_return(true)
      allow(http).to receive(:use_ssl=).with(true)
      allow(http).to receive(:cert_store=).with(cert_store)
      allow(http).to receive(:open_timeout=)
      allow(http).to receive(:read_timeout=)

      response = Net::HTTPOK.new("1.1", "200", "OK")
      allow(response).to receive(:body).and_return("{}")
      allow(http).to receive(:request).and_return(response)

      client.movie(550)

      expect(cert_store).to have_received(:set_default_paths)
      expect(http).to have_received(:cert_store=).with(cert_store)
    end
  end

  describe ".new" do
    it "raises authentication error when api key missing" do
      expect { described_class.new(api_key: nil) }
        .to raise_error(Tmdb::AuthenticationError, /missing/i)
    end
  end
end
