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
end
