module Recommender
  class UserEmbedding
    ViewingEvent = Struct.new(:movie, :rating, :watched_at)

    class << self
      def build(user, decay: true)
        events = most_recent_viewings(user)
        return {} if events.empty?

        aggregate = Hash.new(0.0)
        total_weight = 0.0

        events.each do |event|
          next if event.movie.nil?

          movie_vec = event.movie.movie_embedding.presence || MovieEmbedding.build(event.movie)
          rating_weight = FeatureConfig.rating_weight(event.rating)
          next if rating_weight <= 0.0

          recency_weight = decay ? FeatureConfig.recency_multiplier(event.watched_at) : 1.0
          weight = rating_weight * recency_weight

          movie_vec.each do |feature, value|
            aggregate[feature] += value * weight
          end

          total_weight += weight
        end

        return {} if total_weight.zero?

        aggregate.transform_values { |value| value / total_weight }
      end

      def build_and_persist!(user, decay: true)
        embedding = build(user, decay: decay)
        user.update!(user_embedding: embedding)
        embedding
      end

      private

      def most_recent_viewings(user)
        events = {}

        user.diary_entries.includes(:movie).find_each do |entry|
          watched_at = entry.watched_date&.to_time || entry.updated_at
          keep_latest_event(events, entry.movie_id, ViewingEvent.new(entry.movie, entry.rating, watched_at))
        end

        user.ratings.includes(:movie).find_each do |rating|
          watched_at = rating.updated_at
          keep_latest_event(events, rating.movie_id, ViewingEvent.new(rating.movie, rating.value, watched_at))
        end

        events.values
      end

      def keep_latest_event(events, movie_id, candidate_event)
        # Prefer the most recent dated interaction (diary watched_at if present,
        # otherwise rating timestamp) so we do not double-count the same movie
        # and we always keep the freshest diary note when multiple exist.
        existing = events[movie_id]
        if existing.nil? || more_recent?(candidate_event, existing)
          events[movie_id] = candidate_event
        end
      end

      def more_recent?(candidate, existing)
        return true if existing.watched_at.nil?
        return false if candidate.watched_at.nil?

        candidate.watched_at > existing.watched_at
      end
    end
  end
end
