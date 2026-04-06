require "rails_helper"

RSpec.describe "Benchmarks", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /benchmarks" do
    it "returns 200" do
      get benchmarks_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /benchmarks/:id" do
    it "creates a benchmark via JSON and returns JSON response" do
      patch benchmark_path("max_weighted_hang_20mm"),
        params: { benchmark_key: "max_weighted_hang_20mm", benchmark: { value: "50", tested_at: Date.current.to_s } },
        headers: { "Accept" => "application/json" }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)
      expect(json["status"]).to eq("ok")
      expect(json["value"]).to eq("50")
    end

    it "responds with turbo_stream" do
      patch benchmark_path("max_weighted_hang_20mm"),
        params: { benchmark_key: "max_weighted_hang_20mm", benchmark: { value: "50", tested_at: Date.current.to_s } },
        headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html")
    end
  end
end
