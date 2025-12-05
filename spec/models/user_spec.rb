require 'rails_helper'

RSpec.describe User, type: :model do
  describe 'associations' do
    it { should have_many(:diary_entries).dependent(:destroy) }
    it { should have_many(:ratings).dependent(:destroy) }
    it { should have_many(:watchlists).dependent(:destroy) }
    it { should have_many(:movies).through(:watchlists) }
    it { should have_many(:favorites).dependent(:destroy) }
    it { should have_many(:top_movies).class_name('Favorite') }
  end

  describe 'validations' do
    subject { build(:user) }

    it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email) }
    it { should allow_value('test@example.com').for(:email) }
    it { should_not allow_value('invalid-email').for(:email) }

    it { should validate_presence_of(:username) }
    it { should validate_uniqueness_of(:username) }

    it { should validate_presence_of(:password) }
    it { should validate_length_of(:first_name).is_at_most(50) }
    it { should validate_length_of(:last_name).is_at_most(50) }
    it { should validate_length_of(:bio).is_at_most(500) }
  end

  describe 'custom username validations' do
    it 'validates username length between 3 and 20' do
      user = build(:user, username: 'ab')
      expect(user.valid?).to be_falsey
      expect(user.errors[:username]).to include('must be between 3 and 20 characters')

      user = build(:user, username: 'a' * 21)
      expect(user.valid?).to be_falsey
      expect(user.errors[:username]).to include('must be between 3 and 20 characters')
    end

    it 'validates username presence' do
      user = build(:user, username: nil)
      expect(user.valid?).to be_falsey
      expect(user.errors[:username]).to include("can't be blank")
    end

    it 'validates username uniqueness' do
      create(:user, username: 'testuser')
      user = build(:user, username: 'testuser')
      expect(user.valid?).to be_falsey
      expect(user.errors[:username]).to include('has already been taken')
    end
  end

  describe 'password validations' do
    it 'requires password for new records' do
      user = build(:user, password: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("can't be blank")
    end

    it 'requires password to be at least 8 characters' do
      user = build(:user, password: 'Short1', password_confirmation: 'Short1')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must be at least 8 characters")
    end

    it 'requires password to include uppercase letter' do
      user = build(:user, password: 'lowercase123', password_confirmation: 'lowercase123')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include at least one uppercase letter, one lowercase letter, and one number")
    end

    it 'requires password to include lowercase letter' do
      user = build(:user, password: 'UPPERCASE123', password_confirmation: 'UPPERCASE123')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include at least one uppercase letter, one lowercase letter, and one number")
    end

    it 'requires password to include number' do
      user = build(:user, password: 'NoNumbers!', password_confirmation: 'NoNumbers!')
      expect(user).not_to be_valid
      expect(user.errors[:password]).to include("must include at least one uppercase letter, one lowercase letter, and one number")
    end

    it 'accepts strong password' do
      user = build(:user, password: 'StrongPass123', password_confirmation: 'StrongPass123')
      expect(user).to be_valid
    end

    it 'requires password confirmation on new records' do
      user = build(:user, password: 'ValidPass123', password_confirmation: nil)
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("can't be blank")
    end

    it 'requires password and confirmation to match' do
      user = build(:user, password: 'ValidPass123', password_confirmation: 'DifferentPass123')
      expect(user).not_to be_valid
      expect(user.errors[:password_confirmation]).to include("doesn't match Password")
    end
  end

  describe 'has_secure_password' do
    it 'encrypts password' do
      user = create(:user, password: 'TestPass123', password_confirmation: 'TestPass123')
      expect(user.password_digest).to_not be_nil
      expect(user.password_digest).to_not eq('TestPass123')
    end

    it 'authenticates with correct password' do
      user = create(:user, password: 'CorrectPass123', password_confirmation: 'CorrectPass123')
      expect(user.authenticate('CorrectPass123')).to eq(user)
    end

    it 'does not authenticate with wrong password' do
      user = create(:user, password: 'CorrectPass123', password_confirmation: 'CorrectPass123')
      expect(user.authenticate('WrongPass123')).to be_falsey
    end
  end

  describe 'email validation' do
    it 'accepts valid email formats' do
      valid_emails = [ 'user@example.com', 'test.user@example.co.uk', 'user+tag@example.com' ]
      valid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).to be_valid, "Expected #{email} to be valid"
      end
    end

    it 'rejects invalid email formats' do
      invalid_emails = [ 'plainaddress', 'user@', '@example.com', 'user @example.com' ]
      invalid_emails.each do |email|
        user = build(:user, email: email)
        expect(user).not_to be_valid, "Expected #{email} to be invalid"
      end
    end

    it 'ensures email uniqueness (case-insensitive via database)' do
      create(:user, email: 'test@example.com')
      duplicate_user = build(:user, email: 'test@example.com')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:email]).to include('has already been taken')
    end
  end

  describe 'username validation' do
    it 'ensures username uniqueness' do
      create(:user, username: 'unique_user')
      duplicate_user = build(:user, username: 'unique_user')
      expect(duplicate_user).not_to be_valid
      expect(duplicate_user.errors[:username]).to include('has already been taken')
    end

    it 'accepts valid username lengths' do
      user = build(:user, username: 'abc')  # minimum
      expect(user).to be_valid
      user = build(:user, username: 'a' * 20)  # maximum
      expect(user).to be_valid
    end

    it 'rejects too short username' do
      user = build(:user, username: 'ab')
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include('must be between 3 and 20 characters')
    end

    it 'rejects too long username' do
      user = build(:user, username: 'a' * 21)
      expect(user).not_to be_valid
      expect(user.errors[:username]).to include('must be between 3 and 20 characters')
    end
  end

  describe 'follow methods' do
    let(:user) { create(:user) }
    let(:other_user) { create(:user) }
    let(:private_user) { create(:user, is_private: true) }

    describe '#followed_by?' do
      it 'returns true when user is followed by other_user' do
        create(:follow, follower: other_user, followed: user, status: 'accepted')
        expect(user.followed_by?(other_user)).to be true
      end

      it 'returns false when user is not followed by other_user' do
        expect(user.followed_by?(other_user)).to be false
      end

      it 'returns false when follow is pending' do
        create(:follow, follower: other_user, followed: user, status: 'pending')
        expect(user.followed_by?(other_user)).to be false
      end
    end

    describe '#follow_status' do
      it 'returns nil when not following' do
        expect(user.follow_status(other_user)).to be_nil
      end

      it 'returns accepted when following accepted' do
        create(:follow, follower: user, followed: other_user, status: 'accepted')
        expect(user.follow_status(other_user)).to eq('accepted')
      end

      it 'returns pending when follow is pending' do
        create(:follow, follower: user, followed: other_user, status: 'pending')
        expect(user.follow_status(other_user)).to eq('pending')
      end
    end

    describe '#unfollow' do
      it 'removes the follow relationship' do
        create(:follow, follower: user, followed: other_user, status: 'accepted')
        expect { user.unfollow(other_user) }.to change { user.active_follows.count }.by(-1)
      end

      it 'returns nil when not following the user' do
        expect(user.unfollow(other_user)).to be_nil
      end
    end
  end

  describe '#recompute_embedding!' do
    let(:user) { create(:user) }

    it 'calls Recommender::UserEmbedding.build_and_persist! with decay true by default' do
      expect(Recommender::UserEmbedding).to receive(:build_and_persist!).with(user, decay: true)
      user.recompute_embedding!
    end

    it 'calls Recommender::UserEmbedding.build_and_persist! with decay false when specified' do
      expect(Recommender::UserEmbedding).to receive(:build_and_persist!).with(user, decay: false)
      user.recompute_embedding!(decay: false)
    end
  end
end
