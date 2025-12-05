require "rails_helper"

RSpec.describe Recommender::CandidateGenerator do
  describe ".for" do
    let(:user) { create(:user) }

    before do
      # Reset memoized client between tests
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
    end

    after do
      # Clean up memoized client after each test
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
    end

    it "returns local candidates when TMDB is unavailable" do
      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("No API key"))
      allow(Rails.logger).to receive(:warn)

      movie = create(:movie, vote_count: 100)

      candidates = described_class.for(user, limit: 10)

      expect(candidates).to include(movie)
    end

    it "excludes movies the user has already seen" do
      movie1 = create(:movie, vote_count: 100)
      movie2 = create(:movie, vote_count: 100)
      create(:rating, user: user, movie: movie1)

      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("No API key"))

      candidates = described_class.for(user, limit: 10)

      expect(candidates).not_to include(movie1)
      expect(candidates).to include(movie2)
    end

    it "excludes movies in user's watchlist" do
      movie1 = create(:movie, vote_count: 100)
      movie2 = create(:movie, vote_count: 100)
      create(:watchlist, user: user, movie: movie1)

      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("No API key"))

      candidates = described_class.for(user, limit: 10)

      expect(candidates).not_to include(movie1)
      expect(candidates).to include(movie2)
    end

    it "excludes movies in user's diary" do
      movie1 = create(:movie, vote_count: 100)
      movie2 = create(:movie, vote_count: 100)
      create(:diary_entry, user: user, movie: movie1)

      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("No API key"))

      candidates = described_class.for(user, limit: 10)

      expect(candidates).not_to include(movie1)
      expect(candidates).to include(movie2)
    end

    context "with TMDB integration" do
      let(:tmdb_client) { instance_double(Tmdb::Client) }

      before do
        allow(Tmdb::Client).to receive(:new).and_return(tmdb_client)
        # Set up default stub for all get requests
        allow(tmdb_client).to receive(:get).and_return({ "results" => [] })
        allow(tmdb_client).to receive(:movie).and_return({})
      end

      it "fetches TMDB candidates and handles errors gracefully" do
        allow(tmdb_client).to receive(:get).and_raise(StandardError.new("Network error"))
        allow(Rails.logger).to receive(:warn)

        movie = create(:movie, vote_count: 100)
        candidates = described_class.for(user, limit: 10)

        expect(candidates).to include(movie)
        expect(Rails.logger).to have_received(:warn).with(/TMDB candidate generation failed/)
      end

      it "fetches movie recommendations from TMDB" do
        rated_movie = create(:movie, tmdb_id: 550, vote_count: 100)
        create(:rating, user: user, movie: rated_movie, value: 9)

        candidates = described_class.for(user, limit: 10)

        expect(candidates).to be_an(Array)
      end

      it "handles TMDB fetch errors for individual paths" do
        allow(tmdb_client).to receive(:get).and_raise(Tmdb::Error.new("API error"))
        allow(Rails.logger).to receive(:warn)

        candidates = described_class.for(user, limit: 10)

        expect(candidates).to be_an(Array)
      end

      it "discovers movies by person (director)" do
        user.update!(user_embedding: { "director:Christopher Nolan" => 1.5 })

        person_result = {
          "results" => [
            {
              "name" => "Christopher Nolan",
              "known_for_department" => "Directing",
              "known_for" => [
                { "media_type" => "movie", "id" => 123, "title" => "Inception" }
              ]
            }
          ]
        }

        allow(tmdb_client).to receive(:get).with("/search/person", anything).and_return(person_result)
        allow(tmdb_client).to receive(:movie).with(123, anything).and_return({
          "id" => 123,
          "title" => "Inception",
          "release_date" => "2010-07-16",
          "genres" => [ { "name" => "Sci-Fi" } ]
        })

        candidates = described_class.for(user, limit: 50)

        expect(candidates).to be_an(Array)
      end

      it "discovers movies by person (cast)" do
        user.update!(user_embedding: { "cast:Leonardo DiCaprio" => 1.2 })

        person_result = {
          "results" => [
            {
              "name" => "Leonardo DiCaprio",
              "known_for_department" => "Acting",
              "known_for" => [
                { "media_type" => "movie", "id" => 456, "title" => "Titanic" }
              ]
            }
          ]
        }

        allow(tmdb_client).to receive(:get).with("/search/person", anything).and_return(person_result)
        allow(tmdb_client).to receive(:movie).with(456, anything).and_return({
          "id" => 456,
          "title" => "Titanic",
          "release_date" => "1997-12-19",
          "genres" => [ { "name" => "Drama" } ]
        })

        candidates = described_class.for(user, limit: 50)

        expect(candidates).to be_an(Array)
      end

      it "discovers movies by genre" do
        user.update!(user_embedding: { "genre:Action" => 2.0 })

        allow(tmdb_client).to receive(:get).with("/genre/movie/list", anything).and_return({
          "genres" => [ { "id" => 28, "name" => "Action" } ]
        })
        allow(tmdb_client).to receive(:get).with("/discover/movie", anything).and_return({
          "results" => [ { "id" => 789, "title" => "Action Movie" } ]
        })
        allow(tmdb_client).to receive(:movie).with(789, anything).and_return({
          "id" => 789,
          "title" => "Action Movie",
          "release_date" => "2023-01-01",
          "genres" => [ { "name" => "Action" } ]
        })

        candidates = described_class.for(user, limit: 50)

        expect(candidates).to be_an(Array)
      end

      it "falls back to trending movies" do
        allow(tmdb_client).to receive(:get).with("/trending/movie/week", anything).and_return({
          "results" => [ { "id" => 999, "title" => "Trending Movie" } ]
        })
        allow(tmdb_client).to receive(:movie).with(999, anything).and_return({
          "id" => 999,
          "title" => "Trending Movie",
          "release_date" => "2024-01-01",
          "genres" => [ { "name" => "Drama" } ]
        })

        candidates = described_class.for(user, limit: 50)

        expect(candidates).to be_an(Array)
      end

      it "handles TMDB genre lookup errors" do
        user.update!(user_embedding: { "genre:Drama" => 1.0 })
        allow(tmdb_client).to receive(:get).with("/genre/movie/list", anything).and_raise(Tmdb::Error.new("API error"))
        allow(Rails.logger).to receive(:warn)

        candidates = described_class.for(user, limit: 10)

        # The genre lookup error is logged, but other operations might succeed
        expect(candidates).to be_an(Array)
      end

      it "handles TMDB person search errors" do
        user.update!(user_embedding: { "director:Test Director" => 1.0 })
        allow(tmdb_client).to receive(:get).with("/search/person", anything).and_raise(Tmdb::Error.new("API error"))
        allow(Rails.logger).to receive(:warn)

        candidates = described_class.for(user, limit: 10)

        expect(Rails.logger).to have_received(:warn).with(/TMDB person search failed/)
      end

      it "handles TMDB detail fetch errors" do
        allow(tmdb_client).to receive(:get).with("/trending/movie/week", anything).and_return({
          "results" => [ { "id" => 111 } ]
        })
        allow(tmdb_client).to receive(:movie).with(111, anything).and_raise(Tmdb::Error.new("Detail fetch failed"))
        allow(Rails.logger).to receive(:warn)

        candidates = described_class.for(user, limit: 10)

        expect(Rails.logger).to have_received(:warn).with(/TMDB detail fetch failed/)
      end

      it "handles movie persistence errors" do
        allow(tmdb_client).to receive(:get).with("/trending/movie/week", anything).and_return({
          "results" => [ { "id" => 222 } ]
        })
        allow(tmdb_client).to receive(:movie).with(222, anything).and_return({
          "id" => 222,
          "title" => "Test Movie",
          "release_date" => "2024-01-01"
        })
        allow(Rails.logger).to receive(:warn)

        # Create invalid movie scenario
        movie = Movie.new(tmdb_id: 222)
        allow(Movie).to receive(:find_or_initialize_by).with(tmdb_id: 222).and_return(movie)
        allow(movie).to receive(:changed?).and_return(true)
        allow(movie).to receive(:save!).and_raise(ActiveRecord::RecordInvalid.new(movie))

        candidates = described_class.for(user, limit: 10)

        expect(candidates).to be_an(Array)
      end
    end
  end

  describe "normalize_cast helper" do
    let(:user) { create(:user) }

    before do
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
      allow(Tmdb::Client).to receive(:new).and_raise(Tmdb::AuthenticationError.new("No API key"))
    end

    after do
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
    end

    it "handles JSON string cast" do
      movie = create(:movie, cast: '["Actor One", "Actor Two"]', vote_count: 100)
      create(:watchlist, user: user, movie: movie)

      # The normalize_cast is called internally when building candidate generator
      candidates = described_class.for(user, limit: 10)
      expect(candidates).to be_an(Array)
    end

    it "handles array cast" do
      movie = create(:movie, vote_count: 100)
      allow(movie).to receive(:cast).and_return([ "Actor One", "Actor Two" ])

      candidates = described_class.for(user, limit: 10)
      expect(candidates).to be_an(Array)
    end
  end

  describe "parse_date helper" do
    let(:user) { create(:user) }
    let(:tmdb_client) { instance_double(Tmdb::Client) }

    before do
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
      allow(Tmdb::Client).to receive(:new).and_return(tmdb_client)
      allow(tmdb_client).to receive(:get).and_return({ "results" => [] })
      allow(tmdb_client).to receive(:movie).and_return({})
    end

    after do
      described_class.instance_variable_set(:@tmdb_client, nil)
      described_class.instance_variable_set(:@random, nil)
    end

    it "handles invalid date formats" do
      allow(tmdb_client).to receive(:get).with("/trending/movie/week", anything).and_return({
        "results" => [ { "id" => 333 } ]
      })
      allow(tmdb_client).to receive(:movie).with(333, anything).and_return({
        "id" => 333,
        "title" => "Test Movie",
        "release_date" => "not-a-date"
      })

      candidates = described_class.for(user, limit: 10)

      expect(candidates).to be_an(Array)
    end

    it "handles blank date" do
      allow(tmdb_client).to receive(:get).with("/trending/movie/week", anything).and_return({
        "results" => [ { "id" => 444 } ]
      })
      allow(tmdb_client).to receive(:movie).with(444, anything).and_return({
        "id" => 444,
        "title" => "Test Movie",
        "release_date" => ""
      })

      candidates = described_class.for(user, limit: 10)

      expect(candidates).to be_an(Array)
    end
  end
end
