require 'rails_helper'

RSpec.describe Watchlist, type: :model do
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
  end

  describe 'validations' do
    subject { create(:watchlist) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:movie_id) }
    it { should validate_presence_of(:status) }
    it { should validate_inclusion_of(:status).in_array(%w[to_watch watching watched]) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:movie_id).with_message('can only have one entry per movie') }
  end
end
