require 'rails_helper'

RSpec.describe DiaryEntry, type: :model do
  include ActiveJob::TestHelper
  describe 'associations' do
    it { should belong_to(:user) }
    it { should belong_to(:movie) }
  end

  describe 'validations' do
    subject { build(:diary_entry) }

    it { should validate_presence_of(:user_id) }
    it { should validate_presence_of(:movie_id) }
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_least(1).is_at_most(5000) }
    it { should allow_value(5).for(:rating) }
    it { should allow_value(0).for(:rating) }
    it { should allow_value(10).for(:rating) }
    it { should_not allow_value(11).for(:rating) }
    it { should_not allow_value(-1).for(:rating) }
    it { should validate_length_of(:mood).is_at_most(50) }
    it { should validate_presence_of(:watched_date) }
  end

  describe 'custom validations' do
    describe 'watched_date_cannot_be_in_future' do
      it 'is valid when watched_date is today' do
        entry = build(:diary_entry, watched_date: Date.today)
        entry.valid?
        expect(entry.errors[:watched_date]).to be_empty
      end

      it 'is valid when watched_date is in the past' do
        entry = build(:diary_entry, watched_date: 1.day.ago.to_date)
        entry.valid?
        expect(entry.errors[:watched_date]).to be_empty
      end

      it 'is invalid when watched_date is in the future' do
        entry = build(:diary_entry, watched_date: 1.day.from_now.to_date)
        expect(entry.valid?).to be_falsey
        expect(entry.errors[:watched_date]).to include("can't be in the future")
      end
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
        create(:diary_entry, user: user, movie: movie, watched_date: Date.today, content: 'Great movie!')
      end.to have_enqueued_job(RecomputeUserEmbeddingJob).with(user.id)
    end
  end
end
