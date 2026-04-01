# frozen_string_literal: true

Rails.application.configure do
  config.x.ai.provider = ENV.fetch("AI_PROVIDER", "anthropic")
  config.x.ai.enabled = ENV.fetch("AI_ENABLED", "true").to_s.downcase == "true"
  config.x.ai.models = {
    "anthropic" => ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
    "openai" => ENV.fetch("OPENAI_MODEL", "gpt-4o")
  }
  config.x.ai.request_timeout = ENV.fetch("AI_REQUEST_TIMEOUT", "300").to_i
  config.x.ai.max_tokens = ENV.fetch("AI_MAX_TOKENS", "64000").to_i
  config.x.ai.daily_budget_cents = ENV.fetch("AI_DAILY_BUDGET_CENTS", "1000").to_i
  config.x.ai.pricing = {
    "anthropic" => {
      input_cents_per_million: 300,
      output_cents_per_million: 1500
    },
    "openai" => {
      input_cents_per_million: 50,
      output_cents_per_million: 150
    }
  }
end
