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

  describe ".build_and_persist!" do
    it "builds the embedding and persists it to the user" do
      user = create(:user)
      movie = create(:movie, genres: [ "Action" ].to_json, release_date: Date.new(2020, 1, 1))
      create(:rating, user: user, movie: movie, value: 10)

      result = described_class.build_and_persist!(user, decay: false)

      expect(result).to be_a(Hash)
      expect(result["genre:Action"]).to be_present
      user.reload
      expect(user.user_embedding).to eq(result)
    end

    it "builds the embedding with decay enabled by default" do
      user = create(:user)
      movie = create(:movie, genres: [ "Comedy" ].to_json, release_date: Date.new(2020, 1, 1))
      create(:diary_entry, user: user, movie: movie, rating: 8, watched_date: 1.week.ago.to_date)

      result = described_class.build_and_persist!(user)

      expect(result).to be_a(Hash)
      user.reload
      expect(user.user_embedding).to eq(result)
    end

    it "persists an empty hash when user has no viewing events" do
      user = create(:user)

      result = described_class.build_and_persist!(user)

      expect(result).to eq({})
      user.reload
      expect(user.user_embedding).to eq({})
    end
  end
end
