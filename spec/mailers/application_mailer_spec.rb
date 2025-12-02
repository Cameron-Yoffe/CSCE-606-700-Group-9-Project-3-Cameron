require 'rails_helper'

RSpec.describe ApplicationMailer, type: :mailer do
  it "uses the default from address" do
    expect(described_class.default[:from]).to eq("from@example.com")
  end

  it "inherits the mailer layout" do
    expect(described_class.default[:template_path]).to be_nil
  end
end
