require "json"

module Recommender
  class MovieEmbedding
    class << self
      # Build a feature hash for the given movie. Entities currently  include genres, director, cast, and release decade.
      def build(movie, idf_lookup: nil)
        features = {}

        add_categorical_features(features, :genre, normalize_names(movie.genres))
        add_categorical_features(features, :director, Array.wrap(movie.director).compact_blank)
        add_categorical_features(features, :cast, normalize_names(movie.cast))
        add_decade_feature(features, movie.release_date)
        # add_categorical_features(features, :keyword, normalize_names(movie.keywords))

        apply_idf!(features, idf_lookup) if idf_lookup
        features
      end

      def build_and_persist!(movie, idf_lookup: nil)
        embedding = build(movie, idf_lookup: idf_lookup)
        movie.update!(movie_embedding: embedding)
        embedding
      end

      private

      def add_categorical_features(features, type, values)
        values.each do |value|
          key = feature_key(type, value)
          features[key] = FeatureConfig.type_weight(type)
        end
      end

      def add_decade_feature(features, release_date)
        return unless release_date.present?

        year = release_date.year
        decade = (year / 10) * 10
        key = feature_key(:decade, "#{decade}s")
        features[key] = FeatureConfig.type_weight(:decade)
      end

      def feature_key(type, value)
        "#{type}:#{value}"
      end

      def normalize_names(raw_field)
        parsed = case raw_field
        when String
                   begin
                     JSON.parse(raw_field)
                   rescue JSON::ParserError
                     raw_field.split(",").map(&:strip)
                   end
        else
                   raw_field
        end

        Array(parsed).map do |value|
          value.is_a?(Hash) ? (value["name"] || value[:name]) : value
        end.compact_blank
      end

      def apply_idf!(features, lookup)
        features.keys.each do |feature|
          idf_value = case lookup
          when Hash then lookup.fetch(feature, 1.0)
          else lookup.respond_to?(:call) ? lookup.call(feature) : 1.0
          end
          features[feature] *= idf_value
        end
      end
    end
  end
end
