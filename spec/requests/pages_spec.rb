require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the home page for guests" do
      get root_path

      expect(response).to be_successful
      expect(response.body).to include("Movie Search")
    end

    context "when user is logged in" do
      let(:password) { "SecurePass123" }
      let(:user) { create(:user, password: password, password_confirmation: password) }

      before do
        post sign_in_path, params: { email: user.email, password: password }
      end

      it "redirects to dashboard" do
        get root_path

        expect(response).to redirect_to(dashboard_path)
      end
    end
  end
end
