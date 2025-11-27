require 'rails_helper'

RSpec.describe Favorite, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
  end

  describe 'validations' do
    subject { create(:favorite) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:movie_id) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:movie_id).with_message('has already favorited this movie') }
  end
end
