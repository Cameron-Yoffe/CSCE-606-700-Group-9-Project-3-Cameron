require 'rails_helper'

RSpec.describe Recommender::MovieSerializer do
  describe '.call' do
    let(:movie) do
      create(:movie,
        title: 'Test Movie',
        tmdb_id: 12345,
        release_date: Date.new(2023, 6, 15),
        vote_average: 8.5,
        runtime: 120,
        description: 'A great test movie',
        genres: [ { 'name' => 'Action' }, { 'name' => 'Drama' } ].to_json,
        director: 'Test Director',
        cast: [ { 'name' => 'Actor One' }, { 'name' => 'Actor Two' } ].to_json,
        poster_url: '/test_poster.jpg'
      )
    end

    it 'serializes movie into a hash' do
      result = described_class.call(movie)

      expect(result).to be_a(Hash)
      expect(result[:tmdb_id]).to eq(12345)
      expect(result[:title]).to eq('Test Movie')
      expect(result[:year]).to eq(2023)
      expect(result[:director]).to eq('Test Director')
    end

    it 'handles nil release_date' do
      movie.update!(release_date: nil)

      result = described_class.call(movie)

      expect(result[:year]).to be_nil
    end

    it 'includes cast as array with up to 3 members' do
      movie.update!(cast: [ { 'name' => 'A' }, { 'name' => 'B' }, { 'name' => 'C' }, { 'name' => 'D' } ].to_json)

      result = described_class.call(movie)

      expect(result[:cast]).to be_an(Array)
      expect(result[:cast].length).to eq(3)
    end

    it 'handles nil cast' do
      movie.update!(cast: nil)

      result = described_class.call(movie)

      expect(result[:cast]).to eq([])
    end

    it 'handles comma-separated cast string' do
      movie.update!(cast: 'Actor One, Actor Two, Actor Three')

      result = described_class.call(movie)

      expect(result[:cast]).to contain_exactly('Actor One', 'Actor Two', 'Actor Three')
    end

    it 'includes poster_url' do
      result = described_class.call(movie)

      expect(result[:poster_url]).to be_present
    end

    it 'includes details_path' do
      result = described_class.call(movie)

      expect(result[:details_path]).to eq("/movies/#{movie.tmdb_id}")
    end

    it 'defaults director to Unknown when nil' do
      movie.update!(director: nil)

      result = described_class.call(movie)

      expect(result[:director]).to eq('Unknown')
    end

    it 'uses movie.id as tmdb_id when tmdb_id is nil' do
      movie.update!(tmdb_id: nil)

      result = described_class.call(movie)

      expect(result[:tmdb_id]).to eq(movie.id)
    end
  end
end
