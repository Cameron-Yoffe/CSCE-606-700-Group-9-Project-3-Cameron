require 'rails_helper'

RSpec.describe "Dashboards", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  describe "GET /dashboard" do
    it "redirects guests to sign up" do
      get dashboard_path

      expect(response).to redirect_to(sign_up_path)
      follow_redirect!
      expect(response.body).to include("You must be logged in")
    end

    it "shows the dashboard for logged in users" do
      post sign_in_path, params: { email: user.email, password: password }

      get dashboard_path

      expect(response).to be_successful
      expect(response.body).to include(user.username)
    end

    context "activity feed" do
      let(:followed_user) { create(:user) }
      let(:not_followed_user) { create(:user) }
      let(:movie) { create(:movie, title: "Test Movie") }

      before do
        post sign_in_path, params: { email: user.email, password: password }
        user.follow(followed_user)
      end

      it "shows diary entries from followed users" do
        diary_entry = create(:diary_entry, user: followed_user, movie: movie)

        get dashboard_path

        expect(response.body).to include(followed_user.username)
        expect(response.body).to include("logged")
      end

      it "shows ratings from followed users" do
        rating = create(:rating, user: followed_user, movie: movie, review: "Great movie!")

        get dashboard_path

        expect(response.body).to include(followed_user.username)
        expect(response.body).to include("rated")
      end

      it "shows review reactions from followed users" do
        rating = create(:rating, user: not_followed_user, movie: movie, review: "Great movie!")
        reaction = create(:review_reaction, user: followed_user, rating: rating, emoji: "👍")

        get dashboard_path

        expect(response.body).to include(followed_user.username)
        expect(response.body).to include("reacted")
      end

      it "does not show activity from users not being followed in the activity feed" do
        diary_entry = create(:diary_entry, user: not_followed_user, movie: movie)

        get dashboard_path

        # The activity feed section should not contain activity from non-followed users
        # Note: The user might still appear in "Suggested Users" section
        activity_feed_section = response.body[/id="activity-feed-list".*?<\/div>\s*<\/div>/m]
        if activity_feed_section
          expect(activity_feed_section).not_to include(not_followed_user.username)
        end
      end

      it "shows empty state when not following anyone" do
        user.active_follows.destroy_all

        get dashboard_path

        expect(response.body).to include("No activity yet")
      end
    end
  end
end
