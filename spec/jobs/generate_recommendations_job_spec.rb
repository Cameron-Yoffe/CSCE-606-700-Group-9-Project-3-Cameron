require 'rails_helper'

RSpec.describe GenerateRecommendationsJob, type: :job do
  let(:user) { create(:user) }

  describe '#perform' do
    let(:recommendation_run) { RecommendationRun.create!(user: user, status: 'pending') }

    before do
      allow(Recommender::Recommender).to receive(:recommend_movies_for).and_return([])
    end

    it 'updates the run to in_progress status' do
      described_class.perform_now(recommendation_run.id)

      # After completion it will be 'completed', so we test by mocking
      allow(Recommender::Recommender).to receive(:recommend_movies_for) do
        expect(recommendation_run.reload.status).to eq('in_progress')
        []
      end

      recommendation_run.update!(status: 'pending')
      described_class.perform_now(recommendation_run.id)
    end

    it 'generates recommendations using the Recommender' do
      expect(Recommender::Recommender).to receive(:recommend_movies_for).with(user, limit: 20).and_return([])

      described_class.perform_now(recommendation_run.id)
    end

    it 'completes the run with serialized recommendations' do
      movie = create(:movie, title: 'Recommended Movie', director: 'Test Director')
      allow(Recommender::Recommender).to receive(:recommend_movies_for).and_return([ movie ])

      described_class.perform_now(recommendation_run.id)

      recommendation_run.reload
      expect(recommendation_run.status).to eq('completed')
      expect(recommendation_run.movies).to be_an(Array)
      expect(recommendation_run.completed_at).to be_present
    end

    it 'returns early when run is not found' do
      expect(Recommender::Recommender).not_to receive(:recommend_movies_for)

      described_class.perform_now(-1)
    end

    context 'when an error occurs' do
      before do
        allow(Recommender::Recommender).to receive(:recommend_movies_for).and_raise(StandardError.new('Pipeline failed'))
      end

      it 'marks the run as failed' do
        expect {
          described_class.perform_now(recommendation_run.id)
        }.to raise_error(StandardError)

        recommendation_run.reload
        expect(recommendation_run.status).to eq('failed')
        expect(recommendation_run.error_message).to include('Pipeline failed')
      end
    end
  end

  describe 'queue configuration' do
    it 'is enqueued in the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end
end
