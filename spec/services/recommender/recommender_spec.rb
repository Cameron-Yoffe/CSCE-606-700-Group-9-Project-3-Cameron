require "rails_helper"

RSpec.describe Recommender::Recommender do
  describe ".recommend_movies_for" do
    it "ranks candidates by dot product similarity" do
      user = create(:user, user_embedding: { "genre:Drama" => 1.0, "director:Pat" => 1.0 })

      allow(Recommender::CandidateGenerator).to receive(:tmdb_client).and_return(nil)

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

    it "fetches TMDB-backed candidates", vcr: { cassette_name: "recommender/recommend_movies_for_tmdb" } do
      user = create(:user, user_embedding: { "director:Pat Director" => 2.5 })

      Recommender::CandidateGenerator.instance_variable_set(:@tmdb_client, nil)
      allow(Tmdb::Client).to receive(:new).and_return(Tmdb::Client.new(api_key: "test_api_key", request_interval: 0))
      allow(Recommender::CandidateGenerator).to receive(:random).and_return(Random.new(1234))

      client = Recommender::CandidateGenerator.send(:tmdb_client)
      Recommender::CandidateGenerator.instance_variable_set(:@tmdb_client, client)

      captured_tmdb = []
      allow(Recommender::CandidateGenerator).to receive(:tmdb_candidates_for).and_wrap_original do |method, user_arg, kwargs|
        captured_tmdb = method.call(user_arg, **kwargs)
      end

      recommendations = described_class.recommend_movies_for(user, limit: 2)

      expect(recommendations.map(&:tmdb_id)).to include(1000)
      expect(recommendations.first.title).to eq("Pat Movie")
      expect(captured_tmdb.map(&:tmdb_id)).to include(1000, 2000)
    end
  end
end
