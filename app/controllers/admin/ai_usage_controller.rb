# frozen_string_literal: true

module Admin
  class AiUsageController < BaseController
    def index
      today_scope = AiInteraction.where(created_at: Date.current.all_day)

      @total_spend_cents = today_scope.sum(:cost_cents)
      @total_calls = today_scope.count
      @top_users = today_scope
        .joins(:user)
        .group("users.id", "users.email", "users.name")
        .select("users.id, users.email, users.name, COUNT(ai_interactions.id) AS calls, COALESCE(SUM(ai_interactions.cost_cents), 0) AS spend_cents")
        .order("calls DESC")
        .limit(10)
    end
  end
end
