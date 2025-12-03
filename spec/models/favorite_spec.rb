require 'rails_helper'

RSpec.describe Favorite, type: :model do
  let(:user) { create(:user) }
  let(:movie) { create(:movie) }

  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
  end

  describe 'validations' do
    subject { build(:favorite, user: user, movie: movie) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:movie_id) }

    it 'validates uniqueness of user_id scoped to movie_id' do
      create(:favorite, user: user, movie: movie)
      duplicate = build(:favorite, user: user, movie: movie)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:user_id]).to include('has already favorited this movie')
    end
  end

  describe 'top_position validations' do
    it 'allows top_position to be nil' do
      favorite = build(:favorite, user: user, movie: movie, top_position: nil)
      expect(favorite).to be_valid
    end

    it 'allows top_position between 1 and 5' do
      (1..5).each do |position|
        favorite = build(:favorite, user: user, movie: create(:movie), top_position: position)
        expect(favorite).to be_valid
      end
    end

    it 'rejects top_position less than 1' do
      favorite = build(:favorite, user: user, movie: movie, top_position: 0)
      expect(favorite).not_to be_valid
      expect(favorite.errors[:top_position]).to be_present
    end

    it 'rejects top_position greater than 5' do
      favorite = build(:favorite, user: user, movie: movie, top_position: 6)
      expect(favorite).not_to be_valid
      expect(favorite.errors[:top_position]).to be_present
    end

    it 'ensures top_position is unique per user' do
      create(:favorite, user: user, movie: create(:movie), top_position: 1)
      duplicate = build(:favorite, user: user, movie: movie, top_position: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:top_position]).to include('has already been taken')
    end

    it 'allows same top_position for different users' do
      other_user = create(:user, email: 'other@example.com', username: 'otheruser')
      create(:favorite, user: user, movie: create(:movie), top_position: 1)
      favorite = build(:favorite, user: other_user, movie: movie, top_position: 1)
      expect(favorite).to be_valid
    end
  end

  describe 'scopes' do
    let!(:top_favorite_1) { create(:favorite, user: user, movie: create(:movie), top_position: 1) }
    let!(:top_favorite_3) { create(:favorite, user: user, movie: create(:movie), top_position: 3) }
    let!(:regular_favorite) { create(:favorite, user: user, movie: create(:movie), top_position: nil) }

    describe '.top_movies' do
      it 'returns favorites with top_position in order' do
        result = user.favorites.top_movies
        expect(result).to eq([ top_favorite_1, top_favorite_3 ])
      end

      it 'excludes favorites without top_position' do
        result = user.favorites.top_movies
        expect(result).not_to include(regular_favorite)
      end
    end

    describe '.regular_favorites' do
      it 'returns favorites without top_position' do
        result = user.favorites.regular_favorites
        expect(result).to eq([ regular_favorite ])
      end

      it 'excludes favorites with top_position' do
        result = user.favorites.regular_favorites
        expect(result).not_to include(top_favorite_1)
        expect(result).not_to include(top_favorite_3)
      end
    end
  end
end
