require 'rails_helper'

RSpec.describe Movie, type: :model do
  describe 'associations' do
    it { should have_many(:diary_entries).dependent(:destroy) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:ratings).dependent(:destroy) }
    it { should have_many(:watchlists).dependent(:destroy) }
    it { should have_many(:users).through(:watchlists) }
    it { should have_many(:movie_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:movie_tags) }
  end

  describe 'validations' do
    subject { create(:movie) }

    it { should validate_presence_of(:title) }
    it { should validate_length_of(:title).is_at_least(1).is_at_most(255) }
    it { should validate_uniqueness_of(:tmdb_id).allow_nil }
    it { should validate_numericality_of(:vote_average).is_greater_than_or_equal_to(0).is_less_than_or_equal_to(10).allow_nil }
    it { should validate_numericality_of(:runtime).is_greater_than_or_equal_to(0).allow_nil }
  end

  describe '#genre_names' do
    it 'parses JSON genre array' do
      movie = build(:movie, genres: [ { name: 'Comedy' }, { name: 'Drama' } ].to_json)
      expect(movie.genre_names).to eq(%w[Comedy Drama])
    end

    it 'parses comma-separated strings' do
      movie = build(:movie, genres: 'Action, Thriller ,Sci-Fi')
      expect(movie.genre_names).to eq([ 'Action', 'Thriller', 'Sci-Fi' ])
    end

    it 'ignores blank genres' do
      movie = build(:movie, genres: '["Horror", null, ""]')
      expect(movie.genre_names).to eq([ 'Horror' ])
    end

    it 'handles unexpected hash keys gracefully' do
      movie = build(:movie, genres: '[{"label": "Mystery"}]')
      expect(movie.genre_names).to eq([])
    end
  end

  describe '#poster_image_url' do
    it 'returns existing poster_url when present' do
      movie = create(:movie, poster_url: 'https://example.com/poster.jpg')

      expect(movie.poster_image_url).to eq('https://example.com/poster.jpg')
    end

    it 'fetches from TMDB when poster_url is nil and tmdb_id present' do
      movie = create(:movie, poster_url: nil, tmdb_id: 550)
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:movie).with(550).and_return({
        'poster_path' => '/new_poster.jpg'
      })

      result = movie.poster_image_url(size: 'w500')

      expect(result).to eq('https://image.tmdb.org/t/p/w500/new_poster.jpg')
    end

    it 'returns nil when no poster_url and no tmdb_id' do
      movie = create(:movie, poster_url: nil, tmdb_id: nil)

      expect(movie.poster_image_url).to be_nil
    end

    it 'handles TMDB errors gracefully' do
      movie = create(:movie, poster_url: nil, tmdb_id: 550)
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:movie).and_raise(Tmdb::Error.new('API error'))

      expect(movie.poster_image_url).to be_nil
    end
  end

  describe '#refresh_poster_url!' do
    let(:movie) { create(:movie, tmdb_id: 550, poster_url: '/old_poster.jpg') }

    it 'fetches poster from TMDB and updates poster_url' do
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:movie).with(550).and_return({
        'poster_path' => '/new_poster.jpg'
      })

      result = movie.refresh_poster_url!

      expect(result).to eq('https://image.tmdb.org/t/p/w500/new_poster.jpg')
      expect(movie.reload.poster_url).to eq('https://image.tmdb.org/t/p/w500/new_poster.jpg')
    end

    it 'returns nil when movie has no tmdb_id' do
      movie.update!(tmdb_id: nil)

      result = movie.refresh_poster_url!

      expect(result).to be_nil
    end

    it 'returns nil when TMDB returns no poster_path' do
      client = instance_double(Tmdb::Client)
      allow(Tmdb::Client).to receive(:new).and_return(client)
      allow(client).to receive(:movie).with(550).and_return({
        'poster_path' => nil
      })

      result = movie.refresh_poster_url!

      expect(result).to be_nil
    end
  end

  describe '#recompute_embedding!' do
    let(:movie) { create(:movie) }

    it 'calls MovieEmbedding.build_and_persist!' do
      expect(Recommender::MovieEmbedding).to receive(:build_and_persist!).with(movie, idf_lookup: nil)

      movie.recompute_embedding!
    end

    it 'passes idf_lookup parameter' do
      idf_lookup = { 'genre_action' => 1.5 }
      expect(Recommender::MovieEmbedding).to receive(:build_and_persist!).with(movie, idf_lookup: idf_lookup)

      movie.recompute_embedding!(idf_lookup: idf_lookup)
    end
  end
end
