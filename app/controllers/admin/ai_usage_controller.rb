# frozen_string_literal: true

module Admin
  class AiUsageController < BaseController
    def index
      today_scope = AiInteraction.where(created_at: Date.current.all_day)
      window_scope = AiInteraction.where(created_at: 30.days.ago.beginning_of_day..)

      @total_spend_cents_today = today_scope.sum(:cost_cents)
      @total_calls_today = today_scope.count
      @total_tokens_today = today_scope.sum(:tokens_used)

      @total_spend_cents_window = window_scope.sum(:cost_cents)
      @total_calls_window = window_scope.count
      @total_tokens_window = window_scope.sum(:tokens_used)

      @breakdown_by_type = window_scope
        .group(:interaction_type)
        .pluck(
          Arel.sql("ai_interactions.interaction_type"),
          Arel.sql("COUNT(*)"),
          Arel.sql("COALESCE(SUM(tokens_used), 0)"),
          Arel.sql("COALESCE(SUM(cost_cents), 0)")
        )
        .map do |type_int, calls, tokens, spend|
          {
            type: AiInteraction.interaction_types.key(type_int) || type_int.to_s,
            calls: calls,
            tokens: tokens,
            spend_cents: spend
          }
        end

      @top_users = window_scope
        .joins(:user)
        .group("users.id", "users.email", "users.name")
        .select(<<~SQL)
          users.id,
          users.email,
          users.name,
          COUNT(ai_interactions.id) AS calls,
          COALESCE(SUM(ai_interactions.tokens_used), 0) AS tokens,
          COALESCE(SUM(ai_interactions.cost_cents), 0) AS spend_cents,
          COUNT(*) FILTER (WHERE ai_interactions.interaction_type = #{AiInteraction.interaction_types.fetch(:plan_generation)}) AS plan_calls,
          COUNT(*) FILTER (WHERE ai_interactions.interaction_type = #{AiInteraction.interaction_types.fetch(:session_calibration)}) AS calibration_calls
        SQL
        .order("spend_cents DESC")
        .limit(20)

      @recent_interactions = AiInteraction
        .recent
        .includes(:user)
        .limit(50)
    end
  end
end
