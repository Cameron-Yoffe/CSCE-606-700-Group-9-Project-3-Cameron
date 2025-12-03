require 'rails_helper'

RSpec.describe "ReviewReactions", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:rating) { create(:rating) }
  let(:emoji) { ReviewReaction::ALLOWED_EMOJIS.first }

  def sign_in
    post sign_in_path, params: { email: user.email, password: password }
  end

  describe "POST /review_reactions" do
    it "requires authentication" do
      post review_reactions_path, params: { rating_id: rating.id, emoji: emoji }

      expect(response).to redirect_to(sign_in_path)
    end

    it "creates a new reaction" do
      sign_in

      expect {
        post review_reactions_path, params: { rating_id: rating.id, emoji: emoji }
      }.to change { ReviewReaction.count }.by(1)

      expect(response).to redirect_to(movie_path(rating.movie.tmdb_id))
    end

    it "renders turbo stream updates when requested" do
      sign_in

      post review_reactions_path(format: :turbo_stream),
           params: { rating_id: rating.id, emoji: emoji }

      expect(response.media_type).to include("text/vnd.turbo-stream")
      expect(response.body).to include("emoji-reactions-#{rating.id}")
    end

    it "toggles an existing reaction off" do
      existing = create(:review_reaction, rating: rating, user: user, emoji: emoji)
      sign_in

      expect {
        post review_reactions_path, params: { rating_id: rating.id, emoji: emoji }
      }.to change { ReviewReaction.exists?(existing.id) }.from(true).to(false)
    end
  end
end
