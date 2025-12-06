require "rails_helper"

RSpec.describe WatchlistsController, type: :controller do
  let(:user) { create(:user) }

  describe "#create" do
    it "requires login" do
      post :create, params: {}

      expect(response).to redirect_to(sign_up_path)
      expect(flash[:alert]).to eq("You must be logged in")
    end

    it "redirects when tmdb_id is missing" do
      session[:user_id] = user.id
      request.env["HTTP_REFERER"] = movies_path

      post :create, params: { title: "Missing" }

      expect(response).to redirect_to(movies_path)
      expect(flash[:alert]).to eq("Missing movie id")
    end

    it "creates watchlist entry and updates poster url" do
      session[:user_id] = user.id
      request.env["HTTP_REFERER"] = movies_path

      post :create, params: { tmdb_id: 123, title: "Test", poster_url: "http://example.com/poster.jpg" }

      watchlist = user.watchlists.last
      expect(watchlist).to be_present
      expect(watchlist.movie.title).to eq("Test")
      expect(watchlist.movie.poster_url).to eq("http://example.com/poster.jpg")
      expect(response).to redirect_to(movies_path)
      expect(flash[:notice]).to eq("Added to your library")
    end

    it "renders error flash when creation fails" do
      session[:user_id] = user.id
      request.env["HTTP_REFERER"] = movies_path

      allow_any_instance_of(Watchlist).to receive(:persisted?).and_return(false)

      post :create, params: { tmdb_id: 123, title: "Test" }

      expect(response).to redirect_to(movies_path)
      expect(flash[:alert]).to eq("Could not add to library")
    end

    it "renders turbo stream error when creation fails" do
      session[:user_id] = user.id

      allow_any_instance_of(Watchlist).to receive(:persisted?).and_return(false)

      post :create, format: :turbo_stream, params: { tmdb_id: 123, title: "Test" }

      expect(response.media_type).to start_with("text/vnd.turbo-stream")
      expect(response.body).to include("turbo-stream")
    end
  end

  describe "#destroy" do
    it "handles missing watchlist" do
      session[:user_id] = user.id
      request.env["HTTP_REFERER"] = dashboard_path

      delete :destroy, params: { id: 999 }

      expect(response).to redirect_to(dashboard_path)
      expect(flash[:alert]).to eq("Item not found in your library")
    end

    it "removes watchlist and associated rating" do
      session[:user_id] = user.id
      movie = create(:movie)
      watchlist = create(:watchlist, user: user, movie: movie)
      create(:rating, user: user, movie: movie)
      request.env["HTTP_REFERER"] = dashboard_path

      expect {
        delete :destroy, params: { id: watchlist.id }
      }.to change { user.watchlists.count }.by(-1)

      expect(user.ratings.find_by(movie: movie)).to be_nil
      expect(response).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Removed from your library")
    end
  end
end
