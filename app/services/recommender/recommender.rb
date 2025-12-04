module Recommender
  class Recommender
    class << self
      def recommend_movies_for(user, limit: 20)
        user_vec = user.user_embedding.presence || UserEmbedding.build_and_persist!(user)
        return [] if user_vec.blank?

        candidates = CandidateGenerator.for(user)
        scored = candidates.map do |movie|
          movie_vec = movie.movie_embedding.presence || MovieEmbedding.build_and_persist!(movie)
          [ movie, Similarity.dot(user_vec, movie_vec) ]
        end

        scored
          .select { |_, score| score.positive? }
          .sort_by { |(_, score)| -score }
          .first(limit)
          .map(&:first)
      end
    end
  end
end
