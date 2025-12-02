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
