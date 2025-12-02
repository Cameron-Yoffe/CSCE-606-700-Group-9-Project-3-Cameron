require 'rails_helper'

RSpec.describe ApplicationJob, type: :job do
  it "inherits from ActiveJob::Base" do
    expect(described_class.superclass).to eq(ActiveJob::Base)
  end

  it "is configured with the default queue adapter" do
    expect(described_class.queue_adapter).to eq(ActiveJob::Base.queue_adapter)
  end
end
