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

    it "fetches TMDB-backed candidates" do
      user = create(:user, user_embedding: { "director:Pat Director" => 2.5 })

      Recommender::CandidateGenerator.instance_variable_set(:@tmdb_client, nil)
      allow(Recommender::CandidateGenerator).to receive(:random).and_return(Random.new(1234))

      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)

      allow(client).to receive(:get).and_return({ "results" => [] })

      allow(client).to receive(:get).with("/search/person", hash_including(query: "Pat Director")).and_return({
        "results" => [ {
          "known_for_department" => "Directing",
          "known_for" => [
            { "media_type" => "movie", "id" => 1000 },
            { "media_type" => "movie", "id" => 2000 }
          ]
        } ]
      })

      allow(client).to receive(:movie).with(1000, append_to_response: "credits").and_return({
        "id" => 1000,
        "title" => "Pat Movie",
        "release_date" => "2020-01-01",
        "poster_path" => "/poster.jpg",
        "backdrop_path" => "/backdrop.jpg",
        "vote_average" => 7.5,
        "vote_count" => 500,
        "runtime" => 110,
        "genres" => [ { "name" => "Drama" } ],
        "credits" => { "crew" => [ { "job" => "Director", "name" => "Pat Director" } ], "cast" => [] }
      })

      allow(client).to receive(:movie).with(2000, append_to_response: "credits").and_return({
        "id" => 2000,
        "title" => "Other Movie",
        "release_date" => "2020-01-02",
        "poster_path" => "/poster2.jpg",
        "backdrop_path" => "/backdrop2.jpg",
        "vote_average" => 7.0,
        "vote_count" => 400,
        "runtime" => 100,
        "genres" => [ { "name" => "Drama" } ],
        "credits" => { "crew" => [], "cast" => [] }
      })

      captured_tmdb = []
      allow(Recommender::CandidateGenerator).to receive(:tmdb_candidates_for).and_wrap_original do |method, user_arg, **kwargs|
        captured_tmdb = method.call(user_arg, **kwargs)
      end

      recommendations = described_class.recommend_movies_for(user, limit: 2)

      expect(recommendations.map(&:tmdb_id)).to include(1000)
      expect(recommendations.first.title).to eq("Pat Movie")
      expect(captured_tmdb.map(&:tmdb_id)).to include(1000, 2000)
    end
  end
end
