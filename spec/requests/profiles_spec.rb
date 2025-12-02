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
      drama = create(:movie, genres: [{ name: "Drama" }], director: "Director A")
      comedy = create(:movie, genres: [{ name: "Comedy" }, { name: "Drama" }], director: "Director B")

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
  end
end
