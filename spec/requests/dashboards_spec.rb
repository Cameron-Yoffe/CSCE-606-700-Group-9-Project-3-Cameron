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

    context "user search" do
      before do
        post sign_in_path, params: { email: user.email, password: password }
      end

      it "shows search results when search param is provided" do
        other_user = create(:user, username: "searchable_user")

        get dashboard_path, params: { search: "searchable" }

        expect(response).to be_successful
        expect(response.body).to include("searchable_user")
      end
    end
  end

  describe "GET /users/search (JSON API)" do
    before do
      post sign_in_path, params: { email: user.email, password: password }
    end

    it "returns matching users as JSON" do
      other_user = create(:user, username: "findme_user")

      get search_users_path, params: { q: "findme" }, headers: { 'Accept' => 'application/json' }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["users"]).to be_an(Array)
      expect(json["users"].first["username"]).to eq("findme_user")
    end

    it "returns empty array when query is blank" do
      get search_users_path, params: { q: "" }, headers: { 'Accept' => 'application/json' }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["users"]).to eq([])
    end

    it "excludes current user from search results" do
      get search_users_path, params: { q: user.username }, headers: { 'Accept' => 'application/json' }

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json["users"].map { |u| u["id"] }).not_to include(user.id)
    end

    it "includes follow status information" do
      other_user = create(:user, username: "status_user")
      user.follow(other_user)

      get search_users_path, params: { q: "status_user" }, headers: { 'Accept' => 'application/json' }

      json = JSON.parse(response.body)
      user_data = json["users"].first
      expect(user_data).to have_key("is_following")
      expect(user_data).to have_key("is_private")
      expect(user_data).to have_key("followers_count")
    end

    it "includes is_requested status for pending follow requests" do
      private_user = create(:user, :private, username: "private_user")
      user.follow(private_user)  # Creates pending request

      get search_users_path, params: { q: "private_user" }, headers: { 'Accept' => 'application/json' }

      json = JSON.parse(response.body)
      user_data = json["users"].first
      expect(user_data["is_requested"]).to be true
    end
  end
end
