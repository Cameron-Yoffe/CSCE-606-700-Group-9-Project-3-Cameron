require 'rails_helper'

RSpec.describe "Lists", type: :request do
  let(:password) { "SecurePass123" }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "POST /lists" do
    it "creates a list with movies for the signed-in user" do
      user = create(:user, password: password, password_confirmation: password)
      sign_in(user)

      movie_params = {
        tmdb_id: 321_654,
        title: "Interstellar",
        poster_url: "https://image.tmdb.org/t/p/w500/interstellar.jpg",
        release_date: "2014-11-05"
      }

      expect do
        post lists_path, params: { list: { name: "Space Epics", description: "My favorite space adventures" }, movies: [movie_params] }
      end.to change { user.lists.count }.by(1).and change(ListItem, :count).by(1)

      new_list = user.lists.last
      expect(response).to redirect_to(favorites_path(tab: "list-#{new_list.id}"))
      follow_redirect!
      expect(response.body).to include("List created")
      expect(new_list.movies.first.title).to eq("Interstellar")
    end

    it "redirects with an alert when the name is missing" do
      user = create(:user, password: password, password_confirmation: password)
      sign_in(user)

      expect do
        post lists_path, params: {}
      end.not_to change(List, :count)

      expect(response).to redirect_to(favorites_path)
      follow_redirect!
      expect(response.body).to include("Please provide a list name")
    end

    it "requires authentication" do
      expect do
        post lists_path, params: { list: { name: "Unauthorized" } }
      end.not_to change(List, :count)

      expect(response).to redirect_to(sign_in_path)
    end

    it "associates an existing movie by id without creating duplicates" do
      user = create(:user, password: password, password_confirmation: password)
      movie = create(:movie)
      sign_in(user)

      existing_movie_count = Movie.count

      expect do
        post lists_path, params: { list: { name: "Existing Movie List" }, movies: [{ movie_id: movie.id }] }
      end.to change { user.lists.count }.by(1).and change(ListItem, :count).by(1)

      created_list = user.lists.last
      expect(created_list.movies).to contain_exactly(movie)
      expect(Movie.count).to eq(existing_movie_count)
    end

    it "does not create duplicate list items when the same movie is provided multiple times" do
      user = create(:user, password: password, password_confirmation: password)
      movie = create(:movie)
      sign_in(user)

      expect do
        post lists_path, params: { list: { name: "No Duplicates" }, movies: [{ movie_id: movie.id }, { movie_id: movie.id }] }
      end.to change { user.lists.count }.by(1).and change(ListItem, :count).by(1)

      created_list = user.lists.last
      expect(created_list.movies).to contain_exactly(movie)
    end

    it "creates a movie from tmdb attributes when an internal id is not provided" do
      user = create(:user, password: password, password_confirmation: password)
      sign_in(user)

      tmdb_id = 987_654
      poster_url = "https://image.tmdb.org/t/p/w500/new_movie.jpg"
      release_date = "2023-06-01"

      expect do
        post lists_path, params: {
          list: { name: "From TMDB" },
          movies: [{ tmdb_id: tmdb_id, title: "New TMDB Movie", poster_url: poster_url, release_date: release_date }]
        }
      end.to change { user.lists.count }.by(1).and change(Movie, :count).by(1).and change(ListItem, :count).by(1)

      created_list = user.lists.last
      movie = created_list.movies.first
      expect(movie.tmdb_id).to eq(tmdb_id)
      expect(movie.title).to eq("New TMDB Movie")
      expect(movie.poster_url).to eq(poster_url)
      expect(movie.release_date.to_s).to eq(release_date)
    end
  end

  describe "DELETE /lists/:id" do
    it "deletes a list owned by the current user" do
      user = create(:user, password: password, password_confirmation: password)
      list = create(:list, user: user)
      sign_in(user)

      expect do
        delete list_path(list)
      end.to change { user.lists.count }.by(-1)

      expect(response).to redirect_to(favorites_path)
      follow_redirect!
      expect(response.body).to include("List deleted")
    end

    it "does not allow deleting another user's list" do
      user = create(:user, password: password, password_confirmation: password)
      other_user = create(:user)
      list = create(:list, user: other_user)
      sign_in(user)

      expect do
        delete list_path(list)
      end.not_to change(List, :count)

      expect(response).to redirect_to(favorites_path)
      follow_redirect!
      expect(response.body).to include("List not found")
    end
  end
end
