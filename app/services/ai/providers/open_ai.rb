# frozen_string_literal: true

require "openai"

module Ai
  module Providers
    class OpenAi
      DEFAULT_MODEL = "gpt-4o"

      def self.generate(prompt:, system: nil, model: nil, max_tokens: nil)
        api_key = ENV.fetch("OPENAI_API_KEY")
        model ||= DEFAULT_MODEL
        max_tokens ||= Rails.configuration.x.ai.max_tokens || 2000

        client = OpenAI::Client.new(access_token: api_key, request_timeout: request_timeout)
        messages = []
        messages << { role: "system", content: system } if system.present?
        messages << { role: "user", content: prompt }

        response = client.chat(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens,
            temperature: 0.2
          }
        )

        if response.is_a?(Hash) && response["error"].present?
          raise Ai::Client::Error.new("OpenAI error: #{response.dig("error", "message")}", provider: "openai", model: model)
        end

        content = response.dig("choices", 0, "message", "content").to_s
        input_tokens = response.dig("usage", "prompt_tokens").to_i
        output_tokens = response.dig("usage", "completion_tokens").to_i
        tokens_used = response.dig("usage", "total_tokens")
        tokens_used = input_tokens + output_tokens if tokens_used.nil?

        {
          content: content,
          tokens_used: tokens_used,
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          model: response["model"] || model,
          provider: "openai"
        }
      rescue OpenAI::Error => e
        raise Ai::Client::Error.new("OpenAI API error", provider: "openai", model: model, cause: e)
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
        raise Ai::Client::Error.new("OpenAI network error", provider: "openai", model: model, cause: e)
      end

      def self.request_timeout
        Rails.configuration.x.ai.request_timeout || 120
      end
      private_class_method :request_timeout
    end
  end
end
