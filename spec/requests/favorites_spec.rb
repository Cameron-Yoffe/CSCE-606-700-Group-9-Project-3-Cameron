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

  describe "PATCH /favorites/:id/set_top_position" do
    let!(:favorite) { create(:favorite, user: user, movie: movie) }

    before { sign_in(user) }

    context "with valid position" do
      it "sets the top_position" do
        patch set_top_position_favorite_path(favorite), params: { position: 1 }, as: :json
        expect(response).to have_http_status(:success)
        expect(favorite.reload.top_position).to eq(1)
      end

      it "returns success JSON response" do
        patch set_top_position_favorite_path(favorite), params: { position: 2 }, as: :json
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
        expect(json["favorite"]["top_position"]).to eq(2)
      end
    end

    context "when position is already taken" do
      let!(:existing_top) { create(:favorite, user: user, movie: create(:movie), top_position: 1) }

      it "swaps positions by clearing the existing one" do
        patch set_top_position_favorite_path(favorite), params: { position: 1 }, as: :json
        expect(response).to have_http_status(:success)
        expect(favorite.reload.top_position).to eq(1)
        expect(existing_top.reload.top_position).to be_nil
      end
    end

    context "with invalid position" do
      it "rejects position less than 1" do
        patch set_top_position_favorite_path(favorite), params: { position: 0 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end

      it "rejects position greater than 5" do
        patch set_top_position_favorite_path(favorite), params: { position: 6 }, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end

    context "when favorite not found" do
      it "returns 404" do
        patch set_top_position_favorite_path(id: 99999), params: { position: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
        json = JSON.parse(response.body)
        expect(json["error"]).to eq("Favorite not found")
      end
    end

    context "when trying to modify another user's favorite" do
      let(:other_user) { create(:user, email: "other@example.com", username: "otheruser") }
      let!(:other_favorite) { create(:favorite, user: other_user, movie: create(:movie)) }

      it "returns 404" do
        patch set_top_position_favorite_path(other_favorite), params: { position: 1 }, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe "DELETE /favorites/:id/remove_top_position" do
    let!(:favorite) { create(:favorite, user: user, movie: movie, top_position: 3) }

    before { sign_in(user) }

    it "removes the top_position" do
      delete remove_top_position_favorite_path(favorite), as: :json
      expect(response).to have_http_status(:success)
      expect(favorite.reload.top_position).to be_nil
    end

    it "returns success JSON response" do
      delete remove_top_position_favorite_path(favorite), as: :json
      json = JSON.parse(response.body)
      expect(json["success"]).to be true
    end

    context "when favorite not found" do
      it "returns 404" do
        delete remove_top_position_favorite_path(id: 99999), as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
