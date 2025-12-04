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
  end
end
