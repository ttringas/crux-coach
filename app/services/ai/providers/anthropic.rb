# frozen_string_literal: true

require "net/http"
require "json"

module Ai
  module Providers
    class Anthropic
      ENDPOINT = URI("https://api.anthropic.com/v1/messages")
      DEFAULT_MODEL = "claude-sonnet-4-20250514"

      def self.generate(prompt:, system: nil, model: nil, max_tokens: nil)
        api_key = ENV.fetch("ANTHROPIC_API_KEY")
        model ||= DEFAULT_MODEL
        max_tokens ||= self.max_tokens

        request_body = {
          model: model,
          max_tokens: max_tokens,
          stream: false,
          messages: [
            { role: "user", content: prompt }
          ]
        }
        request_body[:system] = system if system.present?

        http = Net::HTTP.new(ENDPOINT.host, ENDPOINT.port)
        http.use_ssl = true
        http.open_timeout = request_timeout
        http.read_timeout = request_timeout

        request = Net::HTTP::Post.new(ENDPOINT)
        request["Content-Type"] = "application/json"
        request["x-api-key"] = api_key
        request["anthropic-version"] = "2023-06-01"
        request.body = JSON.generate(request_body)

        response = http.request(request)
        parsed = JSON.parse(response.body)

        unless response.is_a?(Net::HTTPSuccess)
          error_message = parsed.dig("error", "message") || response.body
          raise Ai::Client::Error.new("Anthropic error: #{error_message}", provider: "anthropic", model: model)
        end

        content = parsed.dig("content", 0, "text").to_s
        input_tokens = parsed.dig("usage", "input_tokens").to_i
        output_tokens = parsed.dig("usage", "output_tokens").to_i
        tokens_used = input_tokens + output_tokens

        {
          content: content,
          tokens_used: tokens_used,
          input_tokens: input_tokens,
          output_tokens: output_tokens,
          model: parsed["model"] || model,
          provider: "anthropic"
        }
      rescue JSON::ParserError => e
        raise Ai::Client::Error.new("Anthropic response parse error", provider: "anthropic", model: model, cause: e)
      rescue Net::OpenTimeout, Net::ReadTimeout, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
        raise Ai::Client::Error.new("Anthropic network error", provider: "anthropic", model: model, cause: e)
      end

      def self.request_timeout
        Rails.configuration.x.ai.request_timeout || 120
      end
      private_class_method :request_timeout

      def self.max_tokens
        Rails.configuration.x.ai.max_tokens || 2000
      end
      private_class_method :max_tokens
    end
  end
end
