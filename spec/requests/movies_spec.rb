require 'rails_helper'

RSpec.describe "Movies", type: :request do
  let(:client) { instance_double(Tmdb::Client) }

  before do
    allow(Tmdb::Client).to receive(:new).and_return(client)
  end

  describe "GET /movies" do
    it "renders the search page without running a query" do
      allow(client).to receive(:get)

      get movies_path

      expect(response).to be_successful
      expect(response.body).to include("Find a movie by title")
      expect(client).not_to have_received(:get)
    end

    it "alerts when query is blank" do
      allow(client).to receive(:get)

      get movies_path, params: { query: "" }

      expect(response.body).to include("Please enter a movie title to search.")
    end

    it "shows search results" do
      allow(client).to receive(:get).and_return({ "results" => [ { "id" => 1, "title" => "Inception", "overview" => "Dream", "poster_path" => "/abc" } ] })

      get movies_path, params: { query: "Inception" }

      expect(response).to be_successful
      expect(response.body).to include("Top results for \"Inception\"")
      expect(response.body).to include("Inception")
    end

    it "handles TMDB errors gracefully" do
      allow(client).to receive(:get).and_raise(Tmdb::Error, "API failure")

      get movies_path, params: { query: "Nope" }

      expect(response.body).to include("API failure")
    end

    it "surfaces authentication errors when the client cannot be created" do
      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError, "Missing key")

      get movies_path

      expect(response.body).to include("Missing key")
    end

    context "JSON API for search" do
      it "returns movies when search query is provided" do
        allow(client).to receive(:get).and_return({
          "results" => [
            { "id" => 123, "title" => "Test Movie", "poster_path" => "/test.jpg", "release_date" => "2024-01-01" }
          ]
        })

        get movies_path, params: { search: "Test" }, headers: { 'Accept' => 'application/json' }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["movies"]).to be_an(Array)
        expect(json["movies"].first["title"]).to eq("Test Movie")
        expect(json["movies"].first["poster_url"]).to include("https://image.tmdb.org")
      end

      it "returns empty array when search query is blank" do
        get movies_path, params: { search: "" }, headers: { 'Accept' => 'application/json' }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["movies"]).to eq([])
      end

      it "returns service unavailable when TMDB raises error" do
        allow(client).to receive(:get).and_raise(Tmdb::Error.new("API failure"))

        get movies_path, params: { search: "Test" }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("API failure")
      end

      it "returns service unavailable when TMDB client is nil" do
        allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("Missing key"))

        get movies_path, params: { search: "Test" }, headers: { 'Accept' => 'application/json' }

        expect(response).to have_http_status(:service_unavailable)
        json = JSON.parse(response.body)
        expect(json["error"]).to include("TMDB API not available")
      end

      it "handles movies without poster path" do
        allow(client).to receive(:get).and_return({
          "results" => [
            { "id" => 456, "title" => "No Poster Movie", "poster_path" => nil, "release_date" => "2023-05-15" }
          ]
        })

        get movies_path, params: { search: "No Poster" }, headers: { 'Accept' => 'application/json' }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["movies"].first["poster_url"]).to be_nil
      end
    end
  end

  describe "GET /movies/:id" do
    it "renders movie details" do
      allow(client).to receive(:movie).and_return({ "id" => 12, "title" => "Heat" })

      get movie_path(12)

      expect(response).to be_successful
      expect(response.body).to include("Heat")
    end

    it "redirects when TMDB raises an error" do
      allow(client).to receive(:movie).and_raise(Tmdb::Error, "Not found")

      get movie_path(999)

      expect(response).to redirect_to(movies_path)
      follow_redirect!
      expect(response.body).to include("Not found")
    end
  end
end
