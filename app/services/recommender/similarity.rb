module Recommender
  module Similarity
    module_function

      # Sparse dot product: sum over overlapping features.
      def dot(user_vec, movie_vec)
        return 0.0 if user_vec.blank? || movie_vec.blank?

        smaller, larger = [user_vec, movie_vec].sort_by(&:length)

        smaller.sum do |feature, weight|
          weight * (larger[feature] || 0.0)
        end
      end

    # Cosine similarity for sparse hashes.
    def cosine(user_vec, movie_vec)
      numerator = dot(user_vec, movie_vec)
      denominator = Math.sqrt(magnitude(user_vec) * magnitude(movie_vec))
      return 0.0 if denominator.zero?

      numerator / denominator
    end

    def magnitude(vec)
      vec.values.sum { |v| v * v }
    end
  end
end
