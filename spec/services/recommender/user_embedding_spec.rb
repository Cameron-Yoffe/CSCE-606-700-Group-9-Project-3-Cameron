require "rails_helper"

RSpec.describe Recommender::UserEmbedding do
  describe ".build" do
    it "averages movie vectors using rating weights and most recent dated events" do
      user = create(:user)
      drama = create(:movie, genres: [ "Drama" ].to_json, release_date: Date.new(2015, 5, 5))
      comedy = create(:movie, genres: [ "Comedy" ].to_json, release_date: Date.new(2021, 1, 1))

      create(:diary_entry, user: user, movie: drama, rating: 6, watched_date: 1.year.ago.to_date)
      create(:diary_entry, user: user, movie: drama, rating: 8, watched_date: 1.month.ago.to_date) # should win
      create(:rating, user: user, movie: comedy, value: 10)

      user_embedding = described_class.build(user, decay: false)

      drama_weight = user_embedding["genre:Drama"]
      comedy_weight = user_embedding["genre:Comedy"]

      expect(drama_weight).to be_within(0.001).of(1.0 / 3.0)
      expect(comedy_weight).to be_within(0.001).of(2.0 / 3.0)
    end
  end
end
