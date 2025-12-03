require 'rails_helper'

RSpec.describe ApplicationHelper, type: :helper do
  let(:user) { create(:user) }
  let(:movie) { create(:movie) }

  it "logs users in and out while tracking current_user" do
    helper.log_in(user)

    expect(helper.session[:user_id]).to eq(user.id)
    expect(helper.current_user).to eq(user)
    expect(helper.logged_in?).to be(true)

    helper.log_out
    expect(helper.session[:user_id]).to be_nil
    expect(helper.logged_in?).to be(false)
  end

  it "returns the current user's rating for a movie" do
    rating = create(:rating, user: user, movie: movie)

    helper.log_in(user)

    expect(helper.user_rating_for(movie)).to eq(rating)
  end

  it "returns nil when no user is logged in" do
    expect(helper.logged_in?).to be(false)
    expect(helper.user_rating_for(movie)).to be_nil
  end
end
