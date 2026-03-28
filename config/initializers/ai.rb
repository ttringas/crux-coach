# frozen_string_literal: true

Rails.application.configure do
  config.x.ai.provider = ENV.fetch("AI_PROVIDER", "anthropic")
  config.x.ai.models = {
    "anthropic" => ENV.fetch("ANTHROPIC_MODEL", "claude-sonnet-4-20250514"),
    "openai" => ENV.fetch("OPENAI_MODEL", "gpt-4o")
  }
  config.x.ai.request_timeout = ENV.fetch("AI_REQUEST_TIMEOUT", "120").to_i
  config.x.ai.max_tokens = ENV.fetch("AI_MAX_TOKENS", "2000").to_i
end
