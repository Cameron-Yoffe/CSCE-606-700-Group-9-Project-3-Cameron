require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    it "renders the home page" do
      get root_path

      expect(response).to be_successful
      expect(response.body).to include("Movie Search")
    end
  end
end
