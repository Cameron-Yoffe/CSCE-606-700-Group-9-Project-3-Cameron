# frozen_string_literal: true

require "rails_helper"

RSpec.describe Follow, type: :model do
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }

  describe "associations" do
    it { should belong_to(:follower).class_name("User") }
    it { should belong_to(:followed).class_name("User") }
  end

  describe "validations" do
    subject { build(:follow, follower: follower, followed: followed) }

    it { should validate_presence_of(:follower_id) }
    it { should validate_presence_of(:followed_id) }
    it { should validate_inclusion_of(:status).in_array(Follow::STATUSES) }

    context "uniqueness" do
      before { create(:follow, follower: follower, followed: followed) }

      it "does not allow duplicate follows" do
        duplicate = build(:follow, follower: follower, followed: followed)
        expect(duplicate).not_to be_valid
        expect(duplicate.errors[:follower_id]).to include("is already following this user")
      end
    end

    context "self-follow prevention" do
      it "does not allow users to follow themselves" do
        self_follow = build(:follow, follower: follower, followed: follower)
        expect(self_follow).not_to be_valid
        expect(self_follow.errors[:followed_id]).to include("cannot follow yourself")
      end
    end
  end

  describe "scopes" do
    let!(:accepted_follow) { create(:follow, follower: follower, followed: followed, status: "accepted") }
    let!(:pending_follow) { create(:follow, :pending, follower: create(:user), followed: followed) }

    describe ".accepted" do
      it "returns only accepted follows" do
        expect(Follow.accepted).to include(accepted_follow)
        expect(Follow.accepted).not_to include(pending_follow)
      end
    end

    describe ".pending" do
      it "returns only pending follows" do
        expect(Follow.pending).to include(pending_follow)
        expect(Follow.pending).not_to include(accepted_follow)
      end
    end
  end

  describe "#accept!" do
    let(:pending_follow) { create(:follow, :pending, follower: follower, followed: followed) }

    it "changes status to accepted" do
      expect { pending_follow.accept! }.to change { pending_follow.status }.from("pending").to("accepted")
    end

    it "creates a follow_accepted notification for the follower" do
      expect { pending_follow.accept! }.to change { Notification.where(notification_type: "follow_accepted").count }.by(1)

      notification = Notification.last
      expect(notification.user).to eq(follower)
      expect(notification.notifiable).to eq(pending_follow)
    end
  end

  describe "#reject!" do
    let(:pending_follow) { create(:follow, :pending, follower: follower, followed: followed) }

    it "destroys the follow" do
      pending_follow.reject!
      expect(Follow.exists?(pending_follow.id)).to be false
    end
  end

  describe "callbacks" do
    context "when creating a follow with pending status" do
      it "creates a follow_request notification for the followed user" do
        expect {
          create(:follow, :pending, follower: follower, followed: followed)
        }.to change { Notification.where(notification_type: "follow_request").count }.by(1)

        notification = Notification.last
        expect(notification.user).to eq(followed)
      end
    end

    context "when creating a follow with accepted status" do
      it "creates a new_follower notification for the followed user" do
        expect {
          create(:follow, follower: follower, followed: followed, status: "accepted")
        }.to change { Notification.where(notification_type: "new_follower").count }.by(1)

        notification = Notification.last
        expect(notification.user).to eq(followed)
      end
    end
  end

  describe "#pending?" do
    it "returns true when status is pending" do
      follow = build(:follow, :pending)
      expect(follow.pending?).to be true
    end

    it "returns false when status is accepted" do
      follow = build(:follow, status: "accepted")
      expect(follow.pending?).to be false
    end
  end

  describe "#accepted?" do
    it "returns true when status is accepted" do
      follow = build(:follow, status: "accepted")
      expect(follow.accepted?).to be true
    end

    it "returns false when status is pending" do
      follow = build(:follow, :pending)
      expect(follow.accepted?).to be false
    end
  end
end
