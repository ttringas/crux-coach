# frozen_string_literal: true

require "json"

module Ai
  class SessionParser
    def self.call(raw_text:, climber_profile:)
      prompts = Ai::Prompts::SessionParser.build(raw_text: raw_text, climber_profile: climber_profile)

      response = Ai::Client.generate(
        prompt: prompts[:user],
        system: prompts[:system],
        user: climber_profile.user,
        interaction_type: :session_parsing
      )

      parse_json_response(response.content)
    end

    def self.parse_json_response(text)
      JSON.parse(text)
    rescue JSON::ParserError
      extracted = extract_json(text)
      return JSON.parse(extracted) if extracted

      raise Ai::Client::Error, "AI response was not valid JSON"
    end
    private_class_method :parse_json_response

    def self.extract_json(text)
      return nil if text.blank?

      start_index = text.index("{")
      end_index = text.rindex("}")
      return nil if start_index.nil? || end_index.nil? || end_index <= start_index

      text[start_index..end_index]
    end
    private_class_method :extract_json
  end
end
