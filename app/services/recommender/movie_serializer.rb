require "json"

module Recommender
  class MovieSerializer
    class << self
      def call(movie)
        cast_members = Array(parse_cast(movie.cast)).compact_blank

        {
          id: movie.id,
          tmdb_id: movie.tmdb_id || movie.id,
          title: movie.title,
          year: movie.release_date&.year,
          director: movie.director.presence || "Unknown",
          cast: cast_members.first(3),
          poster_url: movie.poster_image_url(size: "w500") || movie.poster_url || "https://placehold.co/500x750?text=No+Image",
          details_path: Rails.application.routes.url_helpers.movie_path(movie.tmdb_id || movie.id)
        }
      end

      private

      def parse_cast(raw_cast)
        case raw_cast
        when String
          parse_cast_string(raw_cast)
        when Array
          raw_cast.map { |member| member.is_a?(Hash) ? member["name"] || member[:name] : member.to_s }
        else
          []
        end
      end

      def parse_cast_string(cast_string)
        JSON.parse(cast_string).map do |member|
          member.is_a?(Hash) ? member["name"] || member[:name] : member.to_s
        end
      rescue JSON::ParserError
        cast_string.split(",").map(&:strip)
      end
    end
  end
end
