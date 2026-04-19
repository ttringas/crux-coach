# frozen_string_literal: true

module Ai
  class UsageGuard
    PLAN_LIMIT_PER_DAY = 5
    SESSION_LIMIT_PER_DAY = 20
    SESSION_CALIBRATION_LIMIT_PER_DAY = 5
    TOTAL_LIMIT_PER_DAY = 50

    def self.check!(user:, interaction_type:, provider: nil)
      ensure_ai_enabled!
      ensure_api_key!(provider)
      ensure_budget_available!
      ensure_user_limits!(user: user, interaction_type: interaction_type)
    end

    def self.ensure_ai_enabled!
      return if Rails.configuration.x.ai.enabled

      raise Ai::Client::Error.new("AI features are temporarily unavailable. Please try again later.")
    end
    private_class_method :ensure_ai_enabled!

    def self.ensure_api_key!(provider)
      provider = provider.to_s.presence || Rails.configuration.x.ai.provider.to_s

      case provider
      when "anthropic"
        return if ENV["ANTHROPIC_API_KEY"].present?

        raise Ai::Client::Error.new("Anthropic API key is missing. Please configure AI credentials.", provider: provider)
      when "openai"
        return if ENV["OPENAI_API_KEY"].present?

        raise Ai::Client::Error.new("OpenAI API key is missing. Please configure AI credentials.", provider: provider)
      else
        raise Ai::Client::Error.new("Unknown AI provider: #{provider}", provider: provider)
      end
    end
    private_class_method :ensure_api_key!

    def self.ensure_budget_available!
      budget_cents = Rails.configuration.x.ai.daily_budget_cents
      return if budget_cents.nil?

      spend_cents = AiInteraction.where(created_at: Date.current.all_day).sum(:cost_cents)
      return if spend_cents < budget_cents

      raise Ai::Client::Error.new("Daily AI budget exceeded. Please try again tomorrow.")
    end
    private_class_method :ensure_budget_available!

    def self.ensure_user_limits!(user:, interaction_type:)
      today = Date.current.all_day
      total_calls = AiInteraction.where(user: user, created_at: today).count
      if total_calls >= TOTAL_LIMIT_PER_DAY
        raise Ai::Client::Error.new("Daily AI usage limit reached (#{TOTAL_LIMIT_PER_DAY} calls). Please try again tomorrow.")
      end

      case interaction_type.to_sym
      when :plan_generation
        plan_calls = AiInteraction.where(user: user, interaction_type: :plan_generation, created_at: today).count
        if plan_calls >= PLAN_LIMIT_PER_DAY
          raise Ai::Client::Error.new("Daily plan generation limit reached (#{PLAN_LIMIT_PER_DAY}). Please try again tomorrow.")
        end
      when :session_parsing
        parse_calls = AiInteraction.where(user: user, interaction_type: :session_parsing, created_at: today).count
        if parse_calls >= SESSION_LIMIT_PER_DAY
          raise Ai::Client::Error.new("Daily session parsing limit reached (#{SESSION_LIMIT_PER_DAY}). Please try again tomorrow.")
        end
      when :session_calibration
        if calibration_count_today(user) >= SESSION_CALIBRATION_LIMIT_PER_DAY
          raise Ai::Client::Error.new(calibration_limit_message)
        end
      end
    end
    private_class_method :ensure_user_limits!

    def self.calibration_count_today(user)
      AiInteraction.where(user: user, interaction_type: :session_calibration, created_at: Date.current.all_day).count
    end

    def self.calibration_limit_reached?(user)
      calibration_count_today(user) >= SESSION_CALIBRATION_LIMIT_PER_DAY
    end

    def self.calibration_limit_message
      "You've reached today's calibration limit of #{SESSION_CALIBRATION_LIMIT_PER_DAY}. To keep things sustainable for both you and the AI coach, calibrations reset each day — please try again tomorrow."
    end
  end
end
