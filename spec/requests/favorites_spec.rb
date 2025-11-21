require 'rails_helper'

RSpec.describe "Favorites", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:movie) { create(:movie) }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "GET /favorites" do
    it "redirects guests to sign in" do
      get favorites_path
      expect(response).to redirect_to(sign_in_path)
    end

    it "shows the user's favorites" do
      sign_in(user)
      favorite = create(:favorite, user: user, movie: movie)

      get favorites_path

      expect(response).to be_successful
      expect(response.body).to include(favorite.movie.title)
    end
  end

  describe "POST /favorites" do
    before { sign_in(user) }

    it "adds the movie to favorites" do
      expect {
        post favorites_path, params: { movie_id: movie.id }
      }.to change { user.favorites.count }.by(1)
    end

    it "returns an error when movie is missing" do
      post favorites_path
      expect(response).to redirect_to(movies_path)
      expect(flash[:alert]).to eq("Movie not found")
    end
  end

  describe "DELETE /favorites/:id" do
    it "removes the favorite" do
      favorite = create(:favorite, user: user, movie: movie)
      sign_in(user)

      expect {
        delete favorite_path(favorite)
      }.to change { user.favorites.count }.by(-1)
    end
  end
end
