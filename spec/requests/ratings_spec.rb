require 'rails_helper'

RSpec.describe "Ratings", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:movie) { create(:movie) }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "POST /ratings" do
    it "redirects unauthenticated users" do
      post ratings_path, params: { rating: { value: 8, movie_id: movie.id } }
      expect(response).to redirect_to(sign_in_path)
    end

    it "creates a rating and removes the movie from the watchlist" do
      sign_in(user)
      create(:watchlist, user: user, movie: movie)

      expect {
        post ratings_path, params: { rating: { value: 9, review: "Loved it", movie_id: movie.id } }
      }.to change(Rating, :count).by(1)

      expect(response).to redirect_to(movie_path(movie.tmdb_id))
      expect(user.watchlists.where(movie_id: movie.id)).to be_empty
    end

    it "returns validation errors when attributes are invalid" do
      sign_in(user)

      expect {
        post ratings_path, params: { rating: { value: nil, movie_id: movie.id } }, as: :json
      }.not_to change(Rating, :count)

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Value can't be blank")
    end
  end

  describe "PATCH /ratings/:id" do
    it "updates the rating and clears related watchlists" do
      sign_in(user)
      rating = create(:rating, user: user, movie: movie, value: 6)
      create(:watchlist, user: user, movie: movie)

      patch rating_path(rating), params: { rating: { value: 10, review: "Even better" } }

      expect(response).to redirect_to(movie_path(movie.tmdb_id))
      expect(rating.reload.value).to eq(10)
      expect(user.watchlists.where(movie_id: movie.id)).to be_empty
    end

    it "returns errors for invalid updates" do
      sign_in(user)
      rating = create(:rating, user: user, movie: movie, value: 5)

      patch rating_path(rating), params: { rating: { value: 11 } }, as: :json

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Value is not included in the list")
      expect(rating.reload.value).to eq(5)
    end
  end
end
