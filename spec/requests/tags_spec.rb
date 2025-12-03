require 'rails_helper'

RSpec.describe "Tags", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:movie) { create(:movie) }
  let(:tag) { create(:tag) }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "POST /movies/:movie_id/tags" do
    it "requires authentication" do
      post movie_tags_path(movie), params: { tag_id: tag.id }
      expect(response).to redirect_to(sign_in_path)
    end

    it "returns error when tag_id is missing" do
      sign_in(user)

      post movie_tags_path(movie), headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Tag ID is required")
    end

    it "creates a movie tag relationship" do
      sign_in(user)

      expect {
        post movie_tags_path(movie), params: { tag_id: tag.id }, headers: { "ACCEPT" => "application/json" }
      }.to change { movie.tags.reload.count }.by(1)

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["tag"]).to include("id" => tag.id, "name" => tag.name)
    end

    it "returns an error for duplicate tags" do
      sign_in(user)
      movie.tags << tag

      post movie_tags_path(movie), params: { tag_id: tag.id }, headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Tag already added")
    end
  end

  describe "DELETE /movies/:movie_id/tags/:id" do
    it "removes an existing association" do
      sign_in(user)
      movie.tags << tag

      expect {
        delete movie_tag_path(movie, tag), headers: { "ACCEPT" => "application/json" }
      }.to change { movie.tags.reload.count }.by(-1)

      expect(response).to have_http_status(:ok)
      body = JSON.parse(response.body)
      expect(body["success"]).to be(true)
    end

    it "returns an error when tag is not associated" do
      sign_in(user)

      delete movie_tag_path(movie, tag), headers: { "ACCEPT" => "application/json" }

      expect(response).to have_http_status(:unprocessable_content)
      body = JSON.parse(response.body)
      expect(body["errors"]).to include("Tag is not associated with this movie")
    end
  end
end
