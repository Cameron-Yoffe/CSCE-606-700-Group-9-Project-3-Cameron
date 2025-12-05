require 'rails_helper'

RSpec.describe "Recommendations", type: :request do
  let(:password) { "SecurePass123" }
  let(:user) { create(:user, password: password, password_confirmation: password) }

  before do
    post sign_in_path, params: { email: user.email, password: password }
  end

  describe "GET /recommendations" do
    it "shows the recommendations page and creates a run if none exists" do
      expect {
        get recommendations_path
      }.to change { RecommendationRun.count }.by(1)

      expect(response).to be_successful
    end

    context "when user has a completed run" do
      let(:movie1) { create(:movie, title: "Recommended Movie 1", director: "Director 1") }
      let(:movie2) { create(:movie, title: "Recommended Movie 2", director: "Director 2") }

      before do
        RecommendationRun.create!(
          user: user,
          status: 'completed',
          completed_at: Time.current,
          movies: [
            { "id" => movie1.id, "title" => "Recommended Movie 1" },
            { "id" => movie2.id, "title" => "Recommended Movie 2" }
          ]
        )
      end

      it "displays recommended movies" do
        get recommendations_path

        expect(response).to be_successful
      end
    end

    context "when user has a failed run" do
      before do
        RecommendationRun.create!(
          user: user,
          status: 'failed',
          error_message: 'Something went wrong'
        )
      end

      it "creates a new run" do
        expect {
          get recommendations_path
        }.to change { RecommendationRun.count }.by(1)
      end
    end

    context "when user has a pending run without job_id" do
      before do
        RecommendationRun.create!(
          user: user,
          status: 'pending',
          job_id: nil
        )
      end

      it "enqueues the job" do
        expect {
          get recommendations_path
        }.to have_enqueued_job(GenerateRecommendationsJob)
      end
    end

    context "when not logged in" do
      before do
        delete logout_path
      end

      it "redirects to sign up" do
        get recommendations_path

        expect(response).to redirect_to(sign_up_path)
      end
    end
  end

  describe "POST /recommendations/refresh" do
    it "creates a new recommendation run" do
      expect {
        post refresh_recommendations_path
      }.to change { RecommendationRun.count }.by(1)
    end

    it "enqueues a GenerateRecommendationsJob" do
      expect {
        post refresh_recommendations_path
      }.to have_enqueued_job(GenerateRecommendationsJob)
    end

    it "returns JSON with run info" do
      post refresh_recommendations_path

      expect(response).to be_successful
      json = JSON.parse(response.body)
      expect(json).to have_key("run_id")
      expect(json).to have_key("status")
      expect(json["status"]).to eq("pending")
    end
  end

  describe "GET /recommendations/status" do
    context "when user has a pending run" do
      let!(:run) { RecommendationRun.create!(user: user, status: 'pending') }

      it "returns pending status as JSON" do
        get recommendations_status_path, params: { run_id: run.id }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("pending")
        expect(json["run_id"]).to eq(run.id)
      end
    end

    context "when user has an in_progress run" do
      let!(:run) { RecommendationRun.create!(user: user, status: 'in_progress') }

      it "returns in_progress status as JSON" do
        get recommendations_status_path, params: { run_id: run.id }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("in_progress")
      end
    end

    context "when user has a completed run" do
      let!(:run) do
        RecommendationRun.create!(
          user: user,
          status: 'completed',
          completed_at: Time.current,
          movies: [ { "title" => "Test Movie" } ]
        )
      end

      it "returns completed status with recommendations" do
        get recommendations_status_path, params: { run_id: run.id }

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["status"]).to eq("completed")
        expect(json["recommendations"]).to be_an(Array)
      end
    end

    context "when run is not found" do
      it "returns 404" do
        get recommendations_status_path, params: { run_id: -1 }

        expect(response).to have_http_status(:not_found)
      end
    end

    context "without run_id param" do
      let!(:run) { RecommendationRun.create!(user: user, status: 'pending') }

      it "returns the latest run" do
        get recommendations_status_path

        expect(response).to be_successful
        json = JSON.parse(response.body)
        expect(json["run_id"]).to eq(run.id)
      end
    end
  end
end
