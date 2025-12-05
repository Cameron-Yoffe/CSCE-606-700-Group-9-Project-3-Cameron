require "rails_helper"

RSpec.describe Recommender::MovieEmbedding do
  describe ".build" do
    it "converts genres, director, cast, and decade into weighted features" do
      movie = create(
        :movie,
        genres: [ "Drama", "Comedy" ].to_json,
        director: "Greta Gerwig",
        cast: [ "Timothée Chalamet", "Saoirse Ronan" ].to_json,
        release_date: Date.new(2019, 8, 9),
      )

      embedding = described_class.build(movie)

      expect(embedding).to include(
        "genre:Drama" => Recommender::FeatureConfig.type_weight(:genre),
        "genre:Comedy" => Recommender::FeatureConfig.type_weight(:genre),
        "director:Greta Gerwig" => Recommender::FeatureConfig.type_weight(:director),
        "cast:Timothée Chalamet" => Recommender::FeatureConfig.type_weight(:cast),
        "cast:Saoirse Ronan" => Recommender::FeatureConfig.type_weight(:cast),
        "decade:2010s" => Recommender::FeatureConfig.type_weight(:decade),
      )
    end

    it "handles comma-separated string when JSON parsing fails" do
      movie = create(
        :movie,
        genres: "Action, Adventure, Sci-Fi",
        cast: "Actor One, Actor Two",
        release_date: Date.new(2020, 1, 1),
      )

      embedding = described_class.build(movie)

      expect(embedding).to include(
        "genre:Action" => Recommender::FeatureConfig.type_weight(:genre),
        "genre:Adventure" => Recommender::FeatureConfig.type_weight(:genre),
        "genre:Sci-Fi" => Recommender::FeatureConfig.type_weight(:genre),
        "cast:Actor One" => Recommender::FeatureConfig.type_weight(:cast),
        "cast:Actor Two" => Recommender::FeatureConfig.type_weight(:cast),
      )
    end

    it "handles raw array input without JSON parsing" do
      movie = create(:movie, release_date: Date.new(2015, 5, 5))
      allow(movie).to receive(:genres).and_return([ "Horror", "Thriller" ])
      allow(movie).to receive(:cast).and_return([ "Star One", "Star Two" ])

      embedding = described_class.build(movie)

      expect(embedding).to include(
        "genre:Horror" => Recommender::FeatureConfig.type_weight(:genre),
        "genre:Thriller" => Recommender::FeatureConfig.type_weight(:genre),
        "cast:Star One" => Recommender::FeatureConfig.type_weight(:cast),
        "cast:Star Two" => Recommender::FeatureConfig.type_weight(:cast),
      )
    end

    it "applies IDF weights from a hash lookup" do
      movie = create(
        :movie,
        genres: [ "Drama" ].to_json,
        director: "Director Name",
        cast: [].to_json,
        release_date: Date.new(2010, 1, 1),
      )
      idf_lookup = { "genre:Drama" => 2.0, "director:Director Name" => 1.5, "decade:2010s" => 0.8 }

      embedding = described_class.build(movie, idf_lookup: idf_lookup)

      expect(embedding["genre:Drama"]).to eq(Recommender::FeatureConfig.type_weight(:genre) * 2.0)
      expect(embedding["director:Director Name"]).to eq(Recommender::FeatureConfig.type_weight(:director) * 1.5)
      expect(embedding["decade:2010s"]).to eq(Recommender::FeatureConfig.type_weight(:decade) * 0.8)
    end

    it "applies IDF weights from a callable lookup" do
      movie = create(
        :movie,
        genres: [ "Comedy" ].to_json,
        director: nil,
        cast: [].to_json,
        release_date: Date.new(2000, 6, 15),
      )
      callable_lookup = ->(feature) { feature.include?("genre") ? 3.0 : 1.0 }

      embedding = described_class.build(movie, idf_lookup: callable_lookup)

      expect(embedding["genre:Comedy"]).to eq(Recommender::FeatureConfig.type_weight(:genre) * 3.0)
      expect(embedding["decade:2000s"]).to eq(Recommender::FeatureConfig.type_weight(:decade) * 1.0)
    end
  end

  describe ".build_and_persist!" do
    it "builds the embedding and persists it to the movie" do
      movie = create(
        :movie,
        genres: [ "Action" ].to_json,
        director: "Test Director",
        cast: [].to_json,
        release_date: Date.new(2022, 3, 10),
      )

      result = described_class.build_and_persist!(movie)

      expect(result).to be_a(Hash)
      expect(result).to include("genre:Action")
      movie.reload
      expect(movie.movie_embedding).to eq(result)
    end

    it "builds the embedding with idf_lookup and persists it" do
      movie = create(
        :movie,
        genres: [ "Drama" ].to_json,
        director: nil,
        cast: [].to_json,
        release_date: Date.new(2018, 7, 20),
      )
      idf_lookup = { "genre:Drama" => 1.5 }

      result = described_class.build_and_persist!(movie, idf_lookup: idf_lookup)

      expect(result["genre:Drama"]).to eq(Recommender::FeatureConfig.type_weight(:genre) * 1.5)
      movie.reload
      expect(movie.movie_embedding).to eq(result)
    end
  end
end
