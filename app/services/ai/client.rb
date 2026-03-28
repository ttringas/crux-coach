# frozen_string_literal: true

require "ostruct"

module Ai
  class Client
    class Error < StandardError
      attr_reader :provider, :model, :cause

      def initialize(message, provider: nil, model: nil, cause: nil)
        super(message)
        @provider = provider
        @model = model
        @cause = cause
      end
    end

    def self.generate(prompt:, system: nil, model: nil, provider: nil, user: nil, interaction_type: nil)
      raise ArgumentError, "user is required for AiInteraction logging" if user.nil?
      raise ArgumentError, "interaction_type is required for AiInteraction logging" if interaction_type.nil?

      provider = (provider || Rails.configuration.x.ai.provider).to_s
      model = model || default_model_for(provider)

      prompt_text = build_prompt_text(system, prompt)
      start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      response_text = nil
      tokens_used = nil
      resolved_provider = provider
      resolved_model = model
      begin
        result = provider_client(provider).generate(prompt: prompt, system: system, model: model)
        response_text = result.fetch(:content)
        tokens_used = result[:tokens_used]
        resolved_provider = result[:provider] || provider
        resolved_model = result[:model] || model

        OpenStruct.new(
          content: response_text,
          tokens_used: tokens_used,
          model: resolved_model,
          provider: resolved_provider,
          duration_ms: elapsed_ms(start_time)
        )
      rescue Error => e
        response_text = "ERROR: #{e.class}: #{e.message}"
        raise
      rescue StandardError => e
        response_text = "ERROR: #{e.class}: #{e.message}"
        raise Error.new("AI provider error", provider: provider, model: model, cause: e)
      ensure
        duration_ms = elapsed_ms(start_time)
        log_interaction(
          user: user,
          interaction_type: interaction_type,
          provider: resolved_provider,
          model: resolved_model,
          prompt: prompt_text,
          response: response_text,
          tokens_used: tokens_used,
          duration_ms: duration_ms
        )
      end
    end

    def self.provider_client(provider)
      case provider.to_s
      when "anthropic"
        Ai::Providers::Anthropic
      when "openai"
        Ai::Providers::OpenAi
      else
        raise Error.new("Unknown AI provider: #{provider}", provider: provider)
      end
    end
    private_class_method :provider_client

    def self.default_model_for(provider)
      models = Rails.configuration.x.ai.models || {}
      models[provider.to_s] || models[provider.to_sym]
    end
    private_class_method :default_model_for

    def self.build_prompt_text(system, prompt)
      return prompt.to_s if system.blank?

      <<~TEXT
        SYSTEM:
        #{system}

        USER:
        #{prompt}
      TEXT
    end
    private_class_method :build_prompt_text

    def self.elapsed_ms(start_time)
      ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round
    end
    private_class_method :elapsed_ms

    def self.log_interaction(user:, interaction_type:, provider:, model:, prompt:, response:, tokens_used:, duration_ms:)
      AiInteraction.create!(
        user: user,
        interaction_type: interaction_type,
        provider: provider,
        model: model,
        prompt: prompt,
        response: response.to_s,
        tokens_used: tokens_used,
        duration_ms: duration_ms
      )
    rescue StandardError => e
      Rails.logger.error("Failed to log AiInteraction: #{e.class} #{e.message}")
    end
    private_class_method :log_interaction
  end
end
