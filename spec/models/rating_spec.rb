require 'rails_helper'

RSpec.describe Rating, type: :model do
  include ActiveJob::TestHelper
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
  end

  describe 'validations' do
    subject { create(:rating) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:movie_id) }
    it { should validate_presence_of(:value) }
    it { should validate_inclusion_of(:value).in_range(1..10) }
    it { should validate_length_of(:review).is_at_most(5000) }
    it { should validate_uniqueness_of(:user_id).scoped_to(:movie_id).with_message('can only have one rating per movie') }
  end

  describe 'review' do
    it 'allows blank reviews' do
      rating = build(:rating, review: '', user: create(:user), movie: create(:movie))
      expect(rating).to be_valid
    end
  end

  describe 'callbacks' do
    before do
      ActiveJob::Base.queue_adapter = :test
      clear_enqueued_jobs
    end

    after { clear_enqueued_jobs }

    it 'enqueues embedding recomputation after commit' do
      user = create(:user)
      movie = create(:movie)

      expect do
        create(:rating, user: user, movie: movie, value: 8)
      end.to have_enqueued_job(RecomputeUserEmbeddingJob).with(user.id)
    end
  end
end
