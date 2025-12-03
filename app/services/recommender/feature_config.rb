module Recommender
  module FeatureConfig
    # High-level knobs for weighting each entity
    TYPE_WEIGHTS = {
      genre: 1.0,
      director: 1.3,
      cast: 0.8,
      decade: 0.3,
      # keyword: 0.6,
    }.freeze

    # Map 1–5 star ratings to weights. Ratings stored on DiaryEntry/Rating are
    # 1–10; we downsample to a 5-star scale before looking up this table.
    RATING_WEIGHTS = {
      5 => 2.0,
      4 => 1.0,
      3 => 0.3,
      2 => 0.0,
      1 => 0.0,
    }.freeze

    # Treat “seen but unrated” items as a faint signal so they can tilt the profile without changing it too much.
    UNRATED_WEIGHT = 0.2

    # Exponential decay half-life in days
    RECENCY_HALF_LIFE_DAYS = 180.0

    module_function

    def type_weight(type)
      TYPE_WEIGHTS[type.to_sym] || 0.0
    end

    def rating_weight(score)
      return UNRATED_WEIGHT if score.nil?

      stars = ((score.to_f / 2).round).clamp(1, 5)
      RATING_WEIGHTS[stars] || 0.0
    end

    def recency_multiplier(watched_at, now: Time.zone.now)
      return 1.0 unless watched_at

      days_ago = (now - watched_at).to_f / 1.day
      Math.exp(-days_ago / RECENCY_HALF_LIFE_DAYS)
    end
  end
end
