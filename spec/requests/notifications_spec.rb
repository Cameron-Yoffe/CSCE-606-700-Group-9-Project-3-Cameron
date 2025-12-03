# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Notifications", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }
  let(:other_user) { create(:user) }
  let(:follow) { create(:follow, follower: other_user, followed: user) }

  def sign_in(user)
    post sign_in_path, params: { email: user.email, password: password }
    follow_redirect! if response.redirect?
  end

  describe "GET /notifications" do
    before { sign_in(user) }

    # Note: Creating follow also creates a notification for user
    let!(:notification1) { create(:notification, user: user, notifiable: follow, created_at: 1.hour.ago) }
    let!(:notification2) { create(:notification, user: user, notifiable: follow, created_at: 2.hours.ago) }
    let!(:other_notification) { create(:notification, user: other_user, notifiable: follow) }

    it "returns the user's notifications" do
      get "/notifications"
      expect(response).to have_http_status(:ok)
    end

    it "only shows the current user's notifications" do
      get "/notifications"
      expect(assigns(:notifications)).to include(notification1, notification2)
      expect(assigns(:notifications)).not_to include(other_notification)
    end

    it "orders notifications by most recent first" do
      get "/notifications"
      # The follow creates a notification too, so the first one is the most recent
      notifications = assigns(:notifications)
      expect(notifications.first.created_at).to be >= notifications.second.created_at
    end
  end

  describe "PATCH /notifications/:id/mark_as_read" do
    before { sign_in(user) }

    let!(:notification) { create(:notification, user: user, notifiable: follow, read: false) }

    it "marks the notification as read" do
      patch "/notifications/#{notification.id}/mark_as_read"
      expect(notification.reload.read).to be true
    end

    it "redirects back" do
      patch "/notifications/#{notification.id}/mark_as_read"
      expect(response).to have_http_status(:redirect)
    end

    context "when trying to mark another user's notification" do
      let!(:other_notification) { create(:notification, user: other_user, notifiable: follow, read: false) }

      it "returns not found" do
        patch "/notifications/#{other_notification.id}/mark_as_read"
        expect(response).to have_http_status(:not_found)
      end
    end

    context "with JSON format" do
      it "returns success JSON" do
        patch "/notifications/#{notification.id}/mark_as_read", headers: { "Accept" => "application/json" }
        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["read"]).to be true
      end
    end
  end

  describe "PATCH /notifications/mark_all_as_read" do
    before { sign_in(user) }

    let!(:notification1) { create(:notification, user: user, notifiable: follow, read: false) }
    let!(:notification2) { create(:notification, user: user, notifiable: follow, read: false) }
    let!(:other_notification) { create(:notification, user: other_user, notifiable: follow, read: false) }

    it "marks all current user's notifications as read" do
      patch "/notifications/mark_all_as_read"
      expect(notification1.reload.read).to be true
      expect(notification2.reload.read).to be true
    end

    it "does not mark other users' notifications" do
      patch "/notifications/mark_all_as_read"
      expect(other_notification.reload.read).to be false
    end

    it "redirects to notifications" do
      patch "/notifications/mark_all_as_read"
      expect(response).to redirect_to(notifications_path)
    end
  end

  describe "GET /notifications/unread_count" do
    before { sign_in(user) }

    it "returns the correct unread count" do
      # follow creates a notification automatically
      another_follow = create(:follow, follower: create(:user), followed: user)
      # another_follow creates another notification
      read_follow = create(:follow, follower: create(:user), followed: user)
      # read_follow's notification
      user.notifications.last.mark_as_read!

      unread_count = user.notifications.unread.count

      get "/notifications/unread_count"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["count"]).to eq(unread_count)
    end
  end
end
