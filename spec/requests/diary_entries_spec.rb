require 'rails_helper'

RSpec.describe "DiaryEntries", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:movie) { create(:movie) }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "GET /diary_entries" do
    context "when not logged in" do
      it "redirects to sign in" do
        get diary_entries_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      it "displays all diary entries for the user" do
        sign_in(user)
        entry1 = create(:diary_entry, user: user)
        entry2 = create(:diary_entry, user: user)
        other_user_entry = create(
          :diary_entry,
          movie: create(:movie, title: "Hidden Gem")
        )

        get diary_entries_path
        expect(response).to be_successful
        expect(response.body).to include(entry1.movie.title)
        expect(response.body).to include(entry2.movie.title)
        expect(response.body).not_to include(other_user_entry.movie.title)
      end

      it "displays entries sorted by watched_date descending" do
        sign_in(user)
        old_entry = create(:diary_entry, user: user, watched_date: 10.days.ago.to_date)
        recent_entry = create(:diary_entry, user: user, watched_date: Date.today)

        get diary_entries_path
        expect(response).to be_successful
        expect(response.body).to match(/#{recent_entry.movie.title}.*#{old_entry.movie.title}/m)
      end

      it "shows empty state when no entries exist" do
        sign_in(user)
        get diary_entries_path
        expect(response).to be_successful
        expect(response.body).to include("No diary entries yet")
      end
    end
  end

  describe "GET /diary_entries/new" do
    context "when not logged in" do
      it "redirects to sign in" do
        get new_diary_entry_path
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      it "displays the new diary entry form" do
        sign_in(user)
        get new_diary_entry_path
        expect(response).to be_successful
        expect(response.body).to include("Log Movie")
      end

      it "pre-fills watched_date with today" do
        sign_in(user)
        get new_diary_entry_path
        expect(response.body).to include(Date.today.to_s)
      end

      it "shows the movie if movie_id is provided" do
        sign_in(user)
        get new_diary_entry_path(movie_id: movie.id)
        expect(response).to be_successful
        expect(response.body).to include(movie.title)
      end
    end
  end

  describe "POST /diary_entries" do
    context "when not logged in" do
      it "redirects to sign in" do
        post diary_entries_path, params: { diary_entry: { movie_id: movie.id, content: "Great movie!" } }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      before { sign_in(user) }

      it "creates a new diary entry" do
        expect {
          post diary_entries_path, params: {
            diary_entry: {
              movie_id: movie.id,
              content: "Loved this movie!",
              watched_date: Date.today,
              mood: "excited",
              rating: 9
            }
          }
        }.to change { user.diary_entries.count }.by(1)

        entry = user.diary_entries.last
        expect(entry.content).to eq("Loved this movie!")
        expect(entry.mood).to eq("excited")
        expect(entry.rating).to eq(9)
        expect(entry.watched_date).to eq(Date.today)
      end

      it "redirects to diary_entries_path on success" do
        post diary_entries_path, params: {
          diary_entry: {
            movie_id: movie.id,
            content: "Great movie!",
            watched_date: Date.today
          }
        }
        expect(response).to redirect_to(diary_entries_path)
      end

      it "renders new with errors when validation fails" do
        post diary_entries_path, params: {
          diary_entry: {
            movie_id: movie.id,
            content: "",
            watched_date: Date.today
          }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Log Movie")
      end

      it "shows error when movie is not found" do
        post diary_entries_path, params: {
          diary_entry: {
            movie_id: 999_999,
            content: "Test",
            watched_date: Date.today
          }
        }
        expect(response).to redirect_to(diary_entries_path)
        expect(flash[:alert]).to include("Movie not found")
      end

      it "doesn't create entry when watched_date is in the future" do
        expect {
          post diary_entries_path, params: {
            diary_entry: {
              movie_id: movie.id,
              content: "Great movie!",
              watched_date: 1.day.from_now.to_date
            }
          }
        }.not_to change { user.diary_entries.count }

        expect(response).to have_http_status(:unprocessable_content)
      end

      it "allows optional fields to be blank" do
        post diary_entries_path, params: {
          diary_entry: {
            movie_id: movie.id,
            content: "Test content",
            watched_date: Date.today,
            mood: "",
            rating: nil
          }
        }
        expect(response).to redirect_to(diary_entries_path)
        entry = user.diary_entries.last
        expect(entry.mood).to be_blank
        expect(entry.rating).to be_nil
      end
    end
  end

  describe "GET /diary_entries/:id" do
    let(:entry) { create(:diary_entry, user: user) }

    context "when not logged in" do
      it "redirects to sign in" do
        get diary_entry_path(entry)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      before { sign_in(user) }

      it "displays the diary entry" do
        get diary_entry_path(entry)
        expect(response).to be_successful
        expect(response.body).to include(entry.movie.title)
        expect(response.body).to include(entry.watched_date.strftime("%B %d, %Y"))
        expect(response.body).to include(entry.content)
      end

      it "shows rating if present" do
        entry.update(rating: 8)
        get diary_entry_path(entry)
        expect(response.body).to include("8")
      end

      it "shows mood/tags if present" do
        entry.update(mood: "inspiring")
        get diary_entry_path(entry)
        expect(response.body).to include("inspiring")
      end

      it "redirects to diary_entries_path if entry not found" do
        get diary_entry_path(999_999)
        expect(response).to redirect_to(diary_entries_path)
        expect(flash[:alert]).to include("not found")
      end
    end
  end

  describe "GET /diary_entries/:id/edit" do
    let(:entry) { create(:diary_entry, user: user) }

    context "when not logged in" do
      it "redirects to sign in" do
        get edit_diary_entry_path(entry)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      before { sign_in(user) }

      it "displays the edit form" do
        get edit_diary_entry_path(entry)
        expect(response).to be_successful
        expect(response.body).to include("Edit Diary Entry")
        expect(response.body).to include(entry.content)
      end
    end
  end

  describe "PATCH /diary_entries/:id" do
    let(:entry) { create(:diary_entry, user: user) }

    context "when not logged in" do
      it "redirects to sign in" do
        patch diary_entry_path(entry), params: { diary_entry: { content: "Updated" } }
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      before { sign_in(user) }

      it "updates the diary entry" do
        patch diary_entry_path(entry), params: {
          diary_entry: {
            content: "Updated content",
            mood: "happy",
            rating: 7
          }
        }
        entry.reload
        expect(entry.content).to eq("Updated content")
        expect(entry.mood).to eq("happy")
        expect(entry.rating).to eq(7)
        expect(response).to redirect_to(diary_entries_path)
      end

      it "renders edit with errors when validation fails" do
        patch diary_entry_path(entry), params: {
          diary_entry: { content: "" }
        }
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("Edit Diary Entry")
      end
    end
  end

  describe "DELETE /diary_entries/:id" do
    let(:entry) { create(:diary_entry, user: user) }

    context "when not logged in" do
      it "redirects to sign in" do
        delete diary_entry_path(entry)
        expect(response).to redirect_to(sign_in_path)
      end
    end

    context "when logged in" do
      before { sign_in(user) }

      it "deletes the diary entry" do
        entry_id = entry.id
        expect {
          delete diary_entry_path(entry)
        }.to change { DiaryEntry.exists?(entry_id) }.to(false)

        expect(response).to redirect_to(diary_entries_path)
      end

      it "shows success message after deletion" do
        delete diary_entry_path(entry)
        expect(flash[:notice]).to include("deleted")
      end
    end
  end
end
