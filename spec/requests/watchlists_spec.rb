require 'rails_helper'

RSpec.describe "Watchlists", type: :request do
  let(:password) { "SecurePass123" }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "POST /watchlists (Turbo Stream)" do
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
  end

  describe "DELETE /watchlists/:id (Turbo Stream)" do
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
  end
end
