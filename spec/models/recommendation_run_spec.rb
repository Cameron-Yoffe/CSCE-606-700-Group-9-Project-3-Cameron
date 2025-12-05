require 'rails_helper'

RSpec.describe RecommendationRun, type: :model do
  let(:user) { create(:user) }

  describe 'associations' do
    it { should belong_to(:user) }
  end

  describe 'validations' do
    it 'validates status is a valid value' do
      run = described_class.new(user: user, status: 'pending')
      expect(run).to be_valid
    end

    it 'rejects invalid status values' do
      run = described_class.new(user: user, status: 'invalid_status')
      expect(run).not_to be_valid
    end
  end

  describe 'statuses' do
    it 'has pending status' do
      run = described_class.new(user: user, status: 'pending')
      expect(run).to be_valid
      expect(run.pending?).to be true
    end

    it 'has in_progress status' do
      run = described_class.new(user: user, status: 'in_progress')
      expect(run).to be_valid
      expect(run.in_progress?).to be true
    end

    it 'has completed status' do
      run = described_class.new(user: user, status: 'completed')
      expect(run).to be_valid
      expect(run.completed?).to be true
    end

    it 'has failed status' do
      run = described_class.new(user: user, status: 'failed')
      expect(run).to be_valid
      expect(run.failed?).to be true
    end
  end

  describe 'status query methods' do
    it '#pending? returns true for pending status' do
      run = described_class.create!(user: user, status: 'pending')
      expect(run.pending?).to be true
      expect(run.in_progress?).to be false
      expect(run.completed?).to be false
      expect(run.failed?).to be false
    end

    it '#in_progress? returns true for in_progress status' do
      run = described_class.create!(user: user, status: 'in_progress')
      expect(run.pending?).to be false
      expect(run.in_progress?).to be true
    end

    it '#completed? returns true for completed status' do
      run = described_class.create!(user: user, status: 'completed')
      expect(run.completed?).to be true
    end

    it '#failed? returns true for failed status' do
      run = described_class.create!(user: user, status: 'failed')
      expect(run.failed?).to be true
    end
  end

  describe 'scopes' do
    it '.recent_first orders by created_at desc' do
      older_run = described_class.create!(user: user, status: 'completed', created_at: 1.day.ago)
      newer_run = described_class.create!(user: user, status: 'pending', created_at: Time.current)

      results = described_class.recent_first

      expect(results.first).to eq(newer_run)
      expect(results.last).to eq(older_run)
    end
  end

  describe 'STATUSES constant' do
    it 'defines all valid statuses' do
      expect(described_class::STATUSES).to include(
        pending: 'pending',
        in_progress: 'in_progress',
        completed: 'completed',
        failed: 'failed'
      )
    end
  end
end
