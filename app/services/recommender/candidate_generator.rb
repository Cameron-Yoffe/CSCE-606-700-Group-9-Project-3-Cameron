module Recommender
  class CandidateGenerator
    POPULARITY_THRESHOLD = 25
    CANDIDATE_LIMIT = 200
    TMDB_CANDIDATE_LIMIT = 120

    class << self
      def for(user, limit: CANDIDATE_LIMIT)
        seen_ids = seen_movie_ids(user)
        seen_tmdb_ids = seen_tmdb_ids(user)

        local_candidates = local_scope(user, exclude_ids: seen_ids, limit: limit)
        tmdb_candidates = tmdb_candidates_for(user, exclude_tmdb_ids: seen_tmdb_ids, limit: TMDB_CANDIDATE_LIMIT)

        (local_candidates + tmdb_candidates)
          .reject { |movie| seen_ids.include?(movie.id) || seen_tmdb_ids.include?(movie.tmdb_id) }
          .uniq { |movie| movie.tmdb_id || movie.id }
          .shuffle(random: random)
          .first(limit)
      end

      private

      def random
        @random ||= Random.new
      end

      def local_scope(user, exclude_ids:, limit:)
        scope = Movie.where.not(id: exclude_ids)
        scope = scope.where("vote_count >= ?", POPULARITY_THRESHOLD)

        top_genres = dominant_genres(user)
        if top_genres.present?
          genre_filters = top_genres.map { |genre| scope.where("genres LIKE ?", "%#{genre}%") }
          scope = genre_filters.reduce(scope) { |relation, filter| relation.or(filter) }
        end

        scope.limit(limit)
      end

      def seen_movie_ids(user)
        (user.ratings.pluck(:movie_id) + user.diary_entries.pluck(:movie_id) + user.watchlists.pluck(:movie_id)).compact.uniq
      end

      def seen_tmdb_ids(user)
        rating_tmdb_ids = user.ratings.joins(:movie).pluck("movies.tmdb_id")
        diary_tmdb_ids = user.diary_entries.joins(:movie).pluck("movies.tmdb_id")
        watchlist_tmdb_ids = user.watchlists.joins(:movie).pluck("movies.tmdb_id")

        (rating_tmdb_ids + diary_tmdb_ids + watchlist_tmdb_ids).compact.uniq
      end

      def dominant_genres(user)
        embedding = user.user_embedding.presence || {}
        embedding
          .select { |feature, _| feature.start_with?("genre:") }
          .sort_by { |_, weight| -weight }
          .first(3)
          .map { |feature, _| feature.split(":", 2).last }
      end

      def tmdb_candidates_for(user, exclude_tmdb_ids:, limit: TMDB_CANDIDATE_LIMIT)
        client = tmdb_client
        return [] unless client

        results = []
        results.concat(tmdb_movie_recommendations(user, client))
        results.concat(tmdb_person_discoveries(user, client, role: :director))
        results.concat(tmdb_person_discoveries(user, client, role: :cast))
        results.concat(tmdb_genre_discoveries(user, client))
        results.concat(tmdb_trending_fallback(client))

        results
          .compact
          .reject { |movie| exclude_tmdb_ids.include?(movie.tmdb_id) }
          .uniq { |movie| movie.tmdb_id || movie.id }
          .shuffle(random: random)
          .first(limit)
      rescue StandardError => error
        Rails.logger&.warn("TMDB candidate generation failed: #{error.message}")
        []
      end

      def tmdb_client
        @tmdb_client ||= Tmdb::Client.new
      rescue Tmdb::Error => error
        Rails.logger&.warn("TMDB unavailable for candidate generation: #{error.message}")
        nil
      end

      def tmdb_movie_recommendations(user, client)
        seed_ids = preferred_tmdb_movie_ids(user).shuffle(random: random)
        return [] if seed_ids.empty?

        seed_ids.flat_map do |tmdb_id|
          fetch_tmdb_collection(client, "/movie/#{tmdb_id}/recommendations") +
            fetch_tmdb_collection(client, "/movie/#{tmdb_id}/similar")
        end
          .lazy
          .map { |result| upsert_tmdb_movie(result, client: client) }
          .take(60)
          .force
      end

      def tmdb_person_discoveries(user, client, role: :cast)
        names = top_feature_names(user, type: role).shuffle(random: random).first(5)
        return [] if names.empty?

        names.flat_map do |name|
          search_tmdb_person(client, name, role: role)&.flat_map do |person|
            Array(person["known_for"]).filter_map do |work|
              next unless work["media_type"] == "movie"
              upsert_tmdb_movie(work, client: client)
            end
          end
        end.compact
      end

      def tmdb_genre_discoveries(user, client)
        genres = dominant_genres(user)
        return [] if genres.empty?

        ids = tmdb_genre_ids(client, genres)
        return [] if ids.empty?

        query = {
          with_genres: ids.join(","),
          sort_by: "vote_average.desc",
          include_adult: false,
          "vote_count.gte" => POPULARITY_THRESHOLD
        }

        fetch_tmdb_collection(client, "/discover/movie", query: query)
          .map { |result| upsert_tmdb_movie(result, client: client) }
      end

      def tmdb_trending_fallback(client)
        fetch_tmdb_collection(client, "/trending/movie/week")
          .map { |result| upsert_tmdb_movie(result, client: client) }
      end

      def fetch_tmdb_collection(client, path, query: {})
        response = client.get(path, query)
        Array(response["results"])
      rescue Tmdb::Error => error
        Rails.logger&.warn("TMDB fetch failed for #{path}: #{error.message}")
        []
      end

      def upsert_tmdb_movie(result, client:)
        return if result.blank?

        tmdb_id = result["id"] || result[:id]
        return unless tmdb_id

        detail = fetch_tmdb_detail(client, tmdb_id)
        return unless detail.present?

        movie = Movie.find_or_initialize_by(tmdb_id: tmdb_id)
        movie.title ||= detail["title"] || detail["name"]
        movie.release_date ||= parse_date(detail["release_date"])
        movie.poster_url ||= tmdb_image(detail["poster_path"])
        movie.backdrop_url ||= tmdb_image(detail["backdrop_path"], size: "w780")
        movie.vote_average ||= detail["vote_average"]
        movie.vote_count ||= detail["vote_count"]
        movie.runtime ||= detail["runtime"]
        movie.genres ||= detail["genres"]&.map { |genre| genre["name"] }
        movie.director ||= extract_director(detail)

        new_cast = extract_cast(detail)
        movie.cast = new_cast if new_cast.present? && !cast_present?(movie.cast)
        movie.save! if movie.changed?
        movie
      rescue ActiveRecord::RecordInvalid => error
        Rails.logger&.warn("Could not persist TMDB movie #{tmdb_id}: #{error.message}")
        nil
      end

      def fetch_tmdb_detail(client, tmdb_id)
        client.movie(tmdb_id, append_to_response: "credits")
      rescue Tmdb::Error => error
        Rails.logger&.warn("TMDB detail fetch failed for #{tmdb_id}: #{error.message}")
        nil
      end

      def tmdb_image(path, size: "w342")
        return nil unless path.present?

        "https://image.tmdb.org/t/p/#{size}#{path}"
      end

      def parse_date(value)
        return if value.blank?

        Date.parse(value)
      rescue Date::Error
        nil
      end

      def extract_director(detail)
        Array(detail.dig("credits", "crew")).find { |crew| crew["job"] == "Director" }&.[]("name")
      end

      def extract_cast(detail)
        Array(detail.dig("credits", "cast")).first(5).map { |member| member["name"] }
      end

      def cast_present?(raw_cast)
        normalized_cast = normalize_cast(raw_cast)
        normalized_cast.compact_blank.any?
      end

      def normalize_cast(raw_cast)
        case raw_cast
        when String
          JSON.parse(raw_cast)
        when Array
          raw_cast
        else
          []
        end
      rescue JSON::ParserError
        raw_cast.to_s.split(",").map(&:strip)
      end

      def tmdb_genre_ids(client, genres)
        response = client.get("/genre/movie/list")
        lookup = Array(response["genres"]).index_by { |genre| genre["name"] }
        genres.filter_map { |genre_name| lookup[genre_name]&.[]("id") }
      rescue Tmdb::Error => error
        Rails.logger&.warn("TMDB genre lookup failed: #{error.message}")
        []
      end

      def top_feature_names(user, type:)
        embedding = user.user_embedding.presence || {}
        embedding
          .select { |feature, _| feature.start_with?("#{type}:") }
          .sort_by { |_, weight| -weight }
          .map { |feature, _| feature.split(":", 2).last }
      end

      def preferred_tmdb_movie_ids(user)
        rated_movies = user.ratings.includes(:movie).order(value: :desc).limit(10).map(&:movie)
        diary_movies = user.diary_entries.includes(:movie).order(rating: :desc).limit(10).map(&:movie)

        (rated_movies + diary_movies)
          .compact
          .map(&:tmdb_id)
          .compact
          .uniq
      end

      def search_tmdb_person(client, name, role: nil)
        response = client.get("/search/person", { query: name, include_adult: false })
        Array(response["results"]).select do |person|
          next true unless role

          case role
          when :director
            person["known_for_department"] == "Directing"
          when :cast
            person["known_for_department"] == "Acting"
          else
            true
          end
        end
      rescue Tmdb::Error => error
        Rails.logger&.warn("TMDB person search failed for #{name}: #{error.message}")
        []
      end
    end
  end
end
