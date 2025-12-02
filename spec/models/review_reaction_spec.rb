require 'rails_helper'

RSpec.describe ReviewReaction, type: :model do
  subject(:reaction) { build(:review_reaction) }

  it { is_expected.to belong_to(:rating).required }
  it { is_expected.to belong_to(:user).required }
  it { is_expected.to validate_presence_of(:emoji) }

  it "validates emoji inclusion" do
    reaction.emoji = "🚀"
    expect(reaction).not_to be_valid
    expect(reaction.errors[:emoji]).to include("is not allowed")
  end

  it "enforces uniqueness per user, rating, and emoji" do
    existing = create(:review_reaction)
    duplicate = build(:review_reaction, user: existing.user, rating: existing.rating, emoji: existing.emoji)

    expect(duplicate).not_to be_valid
    expect(duplicate.errors[:user_id]).to include("can only react once per emoji per review")
  end
end
