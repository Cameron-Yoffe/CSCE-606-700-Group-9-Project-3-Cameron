require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:movie_tags).dependent(:destroy) }
    it { should have_many(:movies).through(:movie_tags) }
  end

  describe 'validations' do
    subject { create(:tag) }

    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:name).case_insensitive }
    it { should validate_length_of(:name).is_at_least(1).is_at_most(50) }
    it { should validate_presence_of(:category) }
  end

  describe 'callbacks' do
    it 'downcases name before save' do
      tag = create(:tag, name: 'SCI-FI')
      expect(tag.reload.name).to eq('sci-fi')
    end
  end

  describe 'scopes' do
    let!(:comedy) { create(:tag, name: 'Comedy', category: 'comedy') }
    let!(:action) { create(:tag, name: 'Action', category: 'action') }
    let!(:subgenre) { create(:tag, name: 'Buddy Cop', category: 'action', parent_category: 'action') }

    it 'finds tags by name case insensitively' do
      expect(Tag.by_name('comedy')).to contain_exactly(comedy)
      expect(Tag.by_name('COMEDY')).to contain_exactly(comedy)
    end

    it 'filters by category' do
      expect(Tag.by_category('action')).to contain_exactly(action, subgenre)
    end

    it 'returns only main categories' do
      expect(Tag.main_categories).to contain_exactly(comedy, action)
    end

    it 'returns subcategories for a parent' do
      expect(Tag.subcategories_for('action')).to contain_exactly(subgenre)
    end
  end
end
