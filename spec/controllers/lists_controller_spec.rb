require "rails_helper"

RSpec.describe ListsController, type: :controller do
  let(:user) { create(:user) }

  describe "#create" do
    it "requires login" do
      post :create, params: {}

      expect(response).to redirect_to(sign_in_path)
      expect(flash[:alert]).to eq("You must be logged in")
    end

    it "returns error when name is missing" do
      session[:user_id] = user.id

      post :create, params: { list: { description: "desc" } }

      expect(response).to redirect_to(favorites_path)
      expect(flash[:alert]).to eq("Name can't be blank")
    end

    it "creates list and attaches movies" do
      session[:user_id] = user.id
      movie_attrs = { tmdb_id: 321, title: "New Movie", poster_url: "http://poster" }

      expect {
        post :create, params: { list: { name: "My List" }, movies: [ movie_attrs ] }
      }.to change { user.lists.count }.by(1)

      list = user.lists.last
      expect(list.list_items.count).to eq(1)
      expect(list.movies.first.title).to eq("New Movie")
      expect(response).to redirect_to(favorites_path(tab: "list-#{list.id}"))
      expect(flash[:notice]).to eq("List created")
    end
  end

  describe "#destroy" do
    it "returns alert when list missing" do
      session[:user_id] = user.id

      delete :destroy, params: { id: 999 }

      expect(response).to redirect_to(favorites_path)
      expect(flash[:alert]).to eq("List not found")
    end

    it "destroys existing list" do
      session[:user_id] = user.id
      list = create(:list, user: user)

      expect {
        delete :destroy, params: { id: list.id }
      }.to change { user.lists.count }.by(-1)

      expect(response).to redirect_to(favorites_path)
      expect(flash[:notice]).to eq("List deleted")
    end
  end
end
