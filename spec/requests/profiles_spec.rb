require 'rails_helper'

RSpec.describe "Profiles", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password, bio: "Movie lover") }

  def sign_in
    post sign_in_path, params: { email: user.email, password: password }
  end

  describe "GET /profile" do
    it "redirects guests to sign up" do
      get profile_path

      expect(response).to redirect_to(sign_up_path)
      follow_redirect!
      expect(response.body).to include("You must be logged in")
    end

    it "renders stats for the current user" do
      sign_in
      drama = create(:movie, genres: [ { name: "Drama" } ], director: "Director A")
      comedy = create(:movie, genres: [ { name: "Comedy" }, { name: "Drama" } ], director: "Director B")

      create(:diary_entry, user: user, movie: drama, watched_date: Date.current.beginning_of_year)
      create(:diary_entry, user: user, movie: comedy, watched_date: Date.current.beginning_of_year + 1.month, rating: 8)
      create(:rating, user: user, movie: drama, value: 7)

      get profile_path

      expect(response).to be_successful
      expect(response.body).to include(user.username)
      expect(response.body).to include("Movie lover")
      expect(response.body).to include("2") # diary count
      expect(response.body).to include("2") # movies this year
      expect(response.body).to include("7.0") # average rating
      expect(response.body).to include("Drama")
      expect(response.body).to include("Director A")
    end

    it "shows import sections on own profile" do
      sign_in
      get profile_path

      expect(response.body).to include("Import diary from Letterboxd")
      expect(response.body).to include("Import ratings from Letterboxd")
    end
  end

  describe "GET /users/:id (viewing other user's profile)" do
    let(:other_user) { create(:user, username: "other_user", bio: "Another movie fan") }

    before { sign_in }

    it "shows the other user's profile" do
      get user_profile_path(other_user)

      expect(response).to be_successful
      expect(response.body).to include(other_user.username)
      expect(response.body).to include("Another movie fan")
    end

    it "does not show import sections on other user's profile" do
      get user_profile_path(other_user)

      expect(response.body).not_to include("Import diary from Letterboxd")
      expect(response.body).not_to include("Import ratings from Letterboxd")
    end

    it "shows follow button on other user's profile" do
      get user_profile_path(other_user)

      expect(response.body).to include("Follow")
    end

    context "when viewing a private profile" do
      let(:private_user) { create(:user, :private, username: "private_user") }

      it "shows private account message when not following" do
        get user_profile_path(private_user)

        expect(response.body).to include("This Account is Private")
      end

      it "shows profile content when following" do
        user.follow(private_user)
        private_user.pending_follow_requests.first&.accept!

        get user_profile_path(private_user)

        expect(response.body).not_to include("This Account is Private")
        expect(response.body).to include(private_user.username)
      end
    end
  end

  describe "GET /users/:id/followers" do
    before { sign_in }

    it "shows current user's followers when viewing own profile" do
      follower = create(:user, username: "follower_user")
      create(:follow, follower: follower, followed: user, status: "accepted")

      get user_followers_path(user)

      expect(response).to be_successful
      expect(response.body).to include("follower_user")
    end

    it "shows another user's followers" do
      other_user = create(:user, username: "other_user")
      follower = create(:user, username: "other_follower")
      create(:follow, follower: follower, followed: other_user, status: "accepted")

      get user_followers_path(other_user)

      expect(response).to be_successful
      expect(response.body).to include("other_follower")
    end
  end

  describe "GET /users/:id/following" do
    before { sign_in }

    it "shows current user's following list when viewing own profile" do
      following = create(:user, username: "following_user")
      create(:follow, follower: user, followed: following, status: "accepted")

      get user_following_path(user)

      expect(response).to be_successful
      expect(response.body).to include("following_user")
    end

    it "shows another user's following list" do
      other_user = create(:user, username: "other_user")
      following = create(:user, username: "other_following")
      create(:follow, follower: other_user, followed: following, status: "accepted")

      get user_following_path(other_user)

      expect(response).to be_successful
      expect(response.body).to include("other_following")
    end
  end

  describe "GET /profile/edit" do
    it "redirects guests to sign up" do
      get profile_edit_path

      expect(response).to redirect_to(sign_up_path)
    end

    it "renders edit form for logged in user" do
      sign_in
      get profile_edit_path

      expect(response).to be_successful
    end
  end

  describe "PATCH /profile" do
    before { sign_in }

    it "updates user profile successfully" do
      patch profile_path, params: { user: { first_name: "Updated", last_name: "Name", bio: "New bio" } }

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Profile updated successfully")
      user.reload
      expect(user.first_name).to eq("Updated")
      expect(user.bio).to eq("New bio")
    end

    it "renders edit form on validation error" do
      patch profile_path, params: { user: { bio: "x" * 501 } }  # bio too long

      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "POST /profile/import_letterboxd" do
    before { sign_in }

    it "redirects with alert when no file is attached" do
      post profile_import_letterboxd_path

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Please attach your Letterboxd CSV export")
    end

    it "starts import job when valid file is attached" do
      file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/letterboxd_diary.csv"),
        "text/csv"
      )

      expect {
        post profile_import_letterboxd_path, params: { letterboxd_file: file }
      }.to have_enqueued_job(LetterboxdImportJob)

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Import started")
    end
  end

  describe "POST /profile/import_letterboxd_ratings" do
    before { sign_in }

    it "redirects with alert when no file is attached" do
      post profile_import_letterboxd_ratings_path

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Please attach your Letterboxd ratings CSV export")
    end

    it "starts ratings import job when valid file is attached" do
      file = fixture_file_upload(
        Rails.root.join("spec/fixtures/files/letterboxd_ratings.csv"),
        "text/csv"
      )

      expect {
        post profile_import_letterboxd_ratings_path, params: { letterboxd_ratings_file: file }
      }.to have_enqueued_job(LetterboxdRatingsImportJob)

      expect(response).to redirect_to(profile_path)
      follow_redirect!
      expect(response.body).to include("Import started")
    end
  end
end
