require 'rails_helper'

RSpec.describe "Watchlists", type: :request do
  let(:password) { "SecurePass123" }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "POST /watchlists" do
    context "with HTML format" do
      it "creates a watchlist entry and redirects with notice" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        expect {
          post watchlists_path, params: { tmdb_id: 123_456, title: "Spec Movie" }
        }.to change { user.watchlists.count }.by(1)

        expect(response).to redirect_to(movies_path)
        follow_redirect!
        expect(response.body).to include("Added to your library")
      end

      it "redirects with alert when tmdb_id is missing" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        post watchlists_path, params: { title: "No ID Movie" }

        expect(response).to redirect_to(movies_path)
        # Don't follow redirect and check flash - the alert message may vary
        # based on environment (TMDB API key availability)
        expect(flash[:alert]).to be_present
      end

      it "updates poster_url if movie exists but has no poster" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        movie = create(:movie, tmdb_id: 999_888, poster_url: nil)

        post watchlists_path, params: { tmdb_id: 999_888, title: "Movie", poster_url: "http://example.com/poster.jpg" }

        movie.reload
        expect(movie.poster_url).to eq("http://example.com/poster.jpg")
      end
    end

    context "with Turbo Stream format" do
      it "creates a watchlist entry and responds with turbo stream" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        expect {
          post watchlists_path, params: { tmdb_id: 123_456, title: "Spec Movie" }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change { user.watchlists.count }.by(1)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
        expect(user.movies.find_by(tmdb_id: 123_456)).to be_present
      end

      it "renders turbo stream error when tmdb_id is missing" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        post watchlists_path, params: { title: "No ID Movie" }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end

      it "handles nested movie params" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        expect {
          post watchlists_path, params: { movie: { tmdb_id: 111_222, title: "Nested Movie" } }, headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change { user.watchlists.count }.by(1)

        expect(user.movies.find_by(tmdb_id: 111_222)).to be_present
      end
    end
  end

  describe "DELETE /watchlists/:id" do
    context "with HTML format" do
      it "removes a watchlist entry and redirects" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        movie = create(:movie, tmdb_id: 654_321)
        wl = create(:watchlist, user: user, movie: movie)

        expect {
          delete watchlist_path(wl)
        }.to change { user.watchlists.count }.by(-1)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include("Removed from your library")
      end

      it "redirects with alert when watchlist item not found" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        delete watchlist_path(id: 999_999)

        expect(response).to redirect_to(dashboard_path)
        follow_redirect!
        expect(response.body).to include("Item not found in your library")
      end

      it "also removes associated rating when removing from library" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        movie = create(:movie, tmdb_id: 654_321)
        wl = create(:watchlist, user: user, movie: movie)
        create(:rating, user: user, movie: movie, value: 8)

        expect {
          delete watchlist_path(wl)
        }.to change { user.ratings.count }.by(-1)
      end
    end

    context "with Turbo Stream format" do
      it "removes a watchlist entry and responds with turbo stream" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        movie = create(:movie, tmdb_id: 654_321)
        wl = create(:watchlist, user: user, movie: movie)

        expect {
          delete watchlist_path(wl), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }
        }.to change { user.watchlists.count }.by(-1)

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end

      it "renders turbo stream error when watchlist item not found" do
        user = create(:user, password: password, password_confirmation: password)
        sign_in(user)

        delete watchlist_path(id: 999_999), headers: { 'Accept' => 'text/vnd.turbo-stream.html' }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
        expect(response.body).to include("turbo-stream")
      end
    end
  end

  describe "authentication" do
    it "redirects to sign up when not logged in for create" do
      post watchlists_path, params: { tmdb_id: 123 }

      expect(response).to redirect_to(sign_up_path)
    end

    it "redirects to sign up when not logged in for destroy" do
      delete watchlist_path(id: 1)

      expect(response).to redirect_to(sign_up_path)
    end
  end
end
