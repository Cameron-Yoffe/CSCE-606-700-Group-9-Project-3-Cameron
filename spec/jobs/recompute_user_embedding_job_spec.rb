require 'rails_helper'

RSpec.describe RecomputeUserEmbeddingJob, type: :job do
  include ActiveJob::TestHelper

  before do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs
  end

  after { clear_enqueued_jobs }

  it 'rebuilds and persists the user embedding' do
    user = create(:user)
    allow(Recommender::UserEmbedding).to receive(:build_and_persist!)

    perform_enqueued_jobs do
      described_class.perform_later(user.id)
    end

    expect(Recommender::UserEmbedding).to have_received(:build_and_persist!).with(user, decay: true)
  end

  it 'safely no-ops when the user is missing' do
    expect { described_class.perform_now(-1) }.not_to raise_error
  end
end
