require 'rails_helper'

RSpec.describe "watchlists/_button.html.erb", type: :view do
  it "renders Add button when no watchlist exists" do
    movie = build_stubbed(:movie, tmdb_id: 111_222, title: "Spec Title")
    render partial: "watchlists/button", locals: { movie_hash: nil, local_movie: movie, wl: nil }

    expect(rendered).to include("Add")
    expect(rendered).to include(watchlists_path)
  end

  it "renders Remove button when watchlist exists" do
    user = create(:user)
    movie = create(:movie, tmdb_id: 333_444, title: "Exists")
    wl = create(:watchlist, user: user, movie: movie)

    render partial: "watchlists/button", locals: { local_movie: movie, wl: wl }

    expect(rendered).to include("Remove")
    expect(rendered).to include(watchlist_path(wl))
  end
end
