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
      movie = build(:movie, genres: [{ name: 'Comedy' }, { name: 'Drama' }].to_json)
      expect(movie.genre_names).to eq(%w[Comedy Drama])
    end

    it 'parses comma-separated strings' do
      movie = build(:movie, genres: 'Action, Thriller ,Sci-Fi')
      expect(movie.genre_names).to eq(['Action', 'Thriller', 'Sci-Fi'])
    end

    it 'ignores blank genres' do
      movie = build(:movie, genres: '["Horror", null, ""]')
      expect(movie.genre_names).to eq(['Horror'])
    end

    it 'handles unexpected hash keys gracefully' do
      movie = build(:movie, genres: '[{"label": "Mystery"}]')
      expect(movie.genre_names).to eq([])
    end
  end
end
