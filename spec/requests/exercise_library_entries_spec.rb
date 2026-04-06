require "rails_helper"

RSpec.describe "ExerciseLibraryEntries", type: :request do
  let(:user) { create(:user) }
  let!(:profile) { create(:climber_profile, user: user, onboarding_completed: true) }

  before { sign_in user }

  describe "GET /library" do
    it "returns 200" do
      get exercise_library_entries_path
      expect(response).to have_http_status(:ok)
    end

    it "filters by category" do
      create(:exercise_library_entry, category: "strength")
      get exercise_library_entries_path, params: { category: "strength" }
      expect(response).to have_http_status(:ok)
    end

    it "searches by query" do
      create(:exercise_library_entry, name: "Weighted Pull-ups")
      get exercise_library_entries_path, params: { q: "pullup" }
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /library/:slug" do
    it "returns 200" do
      entry = create(:exercise_library_entry)
      get exercise_library_entry_path(entry)
      expect(response).to have_http_status(:ok)
    end
  end
end
