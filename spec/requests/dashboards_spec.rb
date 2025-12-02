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
  end
end
