# frozen_string_literal: true

require "openai"

module Ai
  module Providers
    class OpenAi
      DEFAULT_MODEL = "gpt-4o"
      MAX_RETRIES = 3

      def self.generate(prompt:, system: nil, model: nil, max_tokens: nil)
        api_key = ENV.fetch("OPENAI_API_KEY")
        model ||= DEFAULT_MODEL
        max_tokens ||= Rails.configuration.x.ai.max_tokens || 2000

        client = OpenAI::Client.new(access_token: api_key, request_timeout: request_timeout)
        messages = []
        messages << { role: "system", content: system } if system.present?
        messages << { role: "user", content: prompt }

        response = nil
        retries = 0

        loop do
          response = client.chat(
            parameters: {
              model: model,
              messages: messages,
              max_tokens: max_tokens,
              temperature: 0.2
            }
          )

          # Retry on transient errors (rate limits, server errors)
          if response.is_a?(Hash) && response["error"].present?
            error_type = response.dig("error", "type").to_s
            error_code = response.dig("error", "code").to_s
            retryable = error_type.include?("server_error") || error_code == "rate_limit_exceeded"

            if retryable && retries < MAX_RETRIES
              retries += 1
              sleep_time = (2**retries)
              Rails.logger.warn("OpenAI retryable error (#{error_type}), attempt #{retries}/#{MAX_RETRIES}, sleeping #{sleep_time}s")
              sleep(sleep_time)
              next
            end
          end

          break
        end

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
        raise Ai::Client::Error.new("OpenAI API error: #{e.message}", provider: "openai", model: model, cause: e)
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
        raise Ai::Client::Error.new("OpenAI network error: #{e.class.name}", provider: "openai", model: model, cause: e)
      end

      def self.request_timeout
        Rails.configuration.x.ai.request_timeout || 120
      end
      private_class_method :request_timeout
    end
  end
end
