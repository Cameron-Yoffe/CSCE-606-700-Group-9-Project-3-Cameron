module Recommender
  class CandidateGenerator
    POPULARITY_THRESHOLD = 25
    CANDIDATE_LIMIT = 200

    class << self
      def for(user, limit: CANDIDATE_LIMIT)
        seen_ids = seen_movie_ids(user)
        scope = Movie.where.not(id: seen_ids)
        scope = scope.where("vote_count >= ?", POPULARITY_THRESHOLD)

        top_genres = dominant_genres(user)
        if top_genres.present?
          genre_filters = top_genres.map { |genre| scope.where("genres LIKE ?", "%#{genre}%") }
          scope = genre_filters.reduce(scope) { |relation, filter| relation.or(filter) }
        end

        scope.limit(limit)
      end

      private

      def seen_movie_ids(user)
        (user.ratings.pluck(:movie_id) + user.diary_entries.pluck(:movie_id)).uniq
      end

      def dominant_genres(user)
        embedding = user.user_embedding.presence || {}
        embedding
          .select { |feature, _| feature.start_with?("genre:") }
          .sort_by { |_, weight| -weight }
          .first(3)
          .map { |feature, _| feature.split(":", 2).last }
      end
    end
  end
end
