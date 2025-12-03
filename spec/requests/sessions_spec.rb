require 'rails_helper'

RSpec.describe "Sessions", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  describe "GET /sign_in" do
    it "renders the sign in form" do
      get sign_in_path
      expect(response).to be_successful
      expect(response.body).to include("Welcome Back")
    end

    it "redirects logged in users to the dashboard" do
      post sign_in_path, params: { email: user.email, password: password }
      get sign_in_path

      expect(response).to redirect_to(dashboard_path)
    end
  end

  describe "POST /sign_in" do
    it "signs in with valid credentials" do
      post sign_in_path, params: { email: user.email, password: password }

      expect(response).to redirect_to(dashboard_path)
      follow_redirect!
      expect(response.body).to include("You have been signed in successfully.")
    end

    it "renders errors with invalid credentials" do
      post sign_in_path, params: { email: user.email, password: "wrong" }

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.body).to include("Invalid email or password.")
    end
  end

  describe "DELETE /logout" do
    it "clears the session and redirects home" do
      post sign_in_path, params: { email: user.email, password: password }
      delete logout_path

      expect(session[:user_id]).to be_nil
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include("You have been signed out.")
    end
  end
end
