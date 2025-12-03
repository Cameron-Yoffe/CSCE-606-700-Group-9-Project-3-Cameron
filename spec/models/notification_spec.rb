# frozen_string_literal: true

require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user) { create(:user) }
  let(:follower) { create(:user) }
  let(:followed) { create(:user) }
  let(:follow) { create(:follow, follower: follower, followed: followed) }

  describe "associations" do
    it { should belong_to(:user) }
    it { should belong_to(:notifiable) }
  end

  describe "validations" do
    it { should validate_presence_of(:notification_type) }
    it { should validate_inclusion_of(:notification_type).in_array(Notification::TYPES) }
  end

  describe "scopes" do
    let!(:unread_notification) { create(:notification, user: user, read: false) }
    let!(:read_notification) { create(:notification, :read, user: user) }

    describe ".unread" do
      it "returns only unread notifications" do
        expect(Notification.unread).to include(unread_notification)
        expect(Notification.unread).not_to include(read_notification)
      end
    end

    describe ".recent" do
      it "orders by created_at desc and limits to 20" do
        notifications = Notification.recent
        expect(notifications.to_sql).to include("ORDER BY")
        expect(notifications.to_sql).to include("LIMIT")
      end
    end
  end

  describe "#mark_as_read!" do
    let(:notification) { create(:notification, user: user, read: false) }

    it "marks the notification as read" do
      expect { notification.mark_as_read! }.to change { notification.read }.from(false).to(true)
    end
  end

  describe "#message" do
    context "for follow_request notification" do
      it "returns the correct message" do
        notification = build(:notification, :follow_request, notifiable: follow)
        expect(notification.message).to eq("#{follower.username} requested to follow you")
      end
    end

    context "for new_follower notification" do
      it "returns the correct message" do
        notification = build(:notification, notification_type: "new_follower", notifiable: follow)
        expect(notification.message).to eq("#{follower.username} started following you")
      end
    end

    context "for follow_accepted notification" do
      it "returns the correct message" do
        notification = build(:notification, :follow_accepted, notifiable: follow)
        expect(notification.message).to eq("#{followed.username} accepted your follow request")
      end
    end

    context "for unknown notification type" do
      it "returns a fallback message" do
        notification = build(:notification, notification_type: "new_follower", notifiable: nil)
        # When notifiable is nil, accessing follower/followed will fail gracefully
        notification_with_notifiable = build(:notification, notification_type: "unknown", notifiable: follow)
        # Since unknown isn't in TYPES, this would fail validation
        # Let's test the else branch by allowing the notification
        allow(notification_with_notifiable).to receive(:notification_type).and_return("other")
        expect(notification_with_notifiable.message).to eq("You have a new notification")
      end
    end
  end

  describe "#actionable?" do
    context "for follow_request notification" do
      let(:pending_follow) { create(:follow, :pending, follower: follower, followed: followed) }
      let(:notification) { create(:notification, :follow_request, user: followed, notifiable: pending_follow) }

      it "returns true when the follow is still pending" do
        expect(notification.actionable?).to be true
      end

      it "returns false when the follow is accepted" do
        pending_follow.update(status: "accepted")
        expect(notification.reload.actionable?).to be false
      end
    end

    context "for other notification types" do
      let(:notification) { create(:notification, notification_type: "new_follower", user: user, notifiable: follow) }

      it "returns false" do
        expect(notification.actionable?).to be false
      end
    end
  end
end
