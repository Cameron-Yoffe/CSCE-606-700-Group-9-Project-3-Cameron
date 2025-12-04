require "rails_helper"

RSpec.describe Recommender::Recommender do
  describe ".recommend_movies_for" do
    it "ranks candidates by dot product similarity" do
      user = create(:user, user_embedding: { "genre:Drama" => 1.0, "director:Pat" => 1.0 })

      top_pick = create(
        :movie,
        genres: [ "Drama" ].to_json,
        director: "Pat",
        vote_count: 100,
        release_date: Date.new(2020, 1, 1),
      )
      runner_up = create(
        :movie,
        genres: [ "Drama" ].to_json,
        director: "Someone Else",
        vote_count: 100,
        release_date: Date.new(2020, 1, 1),
      )

      recommendations = described_class.recommend_movies_for(user, limit: 2)

      expect(recommendations.first).to eq(top_pick)
      expect(recommendations).to contain_exactly(top_pick, runner_up)
    end
  end
end
