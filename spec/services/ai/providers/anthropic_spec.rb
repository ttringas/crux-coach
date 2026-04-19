require "rails_helper"

RSpec.describe Ai::Providers::Anthropic do
  let(:api_key) { "sk-ant-test-key" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("ANTHROPIC_API_KEY").and_return(api_key)
    Rails.configuration.x.ai.request_timeout = 30
    Rails.configuration.x.ai.max_tokens = 2000
  end

  describe ".generate" do
    let(:success_body) do
      {
        "content" => [{ "type" => "text", "text" => "Hello from Claude" }],
        "model" => "claude-sonnet-4-20250514",
        "usage" => { "input_tokens" => 50, "output_tokens" => 25 }
      }.to_json
    end

    it "makes a correct API call and returns parsed response" do
      mock_response = instance_double(Net::HTTPOK, body: success_body, is_a?: true)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).with("api.anthropic.com", 443).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=).with(true)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).and_return(mock_response)

      result = described_class.generate(prompt: "Hello", system: "You are helpful")

      expect(result[:content]).to eq("Hello from Claude")
      expect(result[:tokens_used]).to eq(75)
      expect(result[:input_tokens]).to eq(50)
      expect(result[:output_tokens]).to eq(25)
      expect(result[:provider]).to eq("anthropic")
      expect(result[:model]).to eq("claude-sonnet-4-20250514")
    end

    it "includes system prompt in request when provided" do
      mock_response = instance_double(Net::HTTPOK, body: success_body)
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)

      captured_request = nil
      allow(mock_http).to receive(:request) do |req|
        captured_request = req
        mock_response
      end

      described_class.generate(prompt: "Hello", system: "Be concise")

      body = JSON.parse(captured_request.body)
      expect(body["system"]).to eq("Be concise")
      expect(body["messages"]).to eq([{ "role" => "user", "content" => "Hello" }])
    end

    it "raises Ai::Client::Error on API error response" do
      error_body = { "error" => { "message" => "Rate limited" } }.to_json
      mock_response = instance_double(Net::HTTPTooManyRequests, body: error_body, code: "400")
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(false)

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).and_return(mock_response)

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /Rate limited/)
    end

    it "raises Ai::Client::Error on network timeout" do
      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).and_raise(Net::ReadTimeout)

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /network error/)
    end

    it "raises Ai::Client::Error on JSON parse error" do
      mock_response = instance_double(Net::HTTPOK, body: "not json")
      allow(mock_response).to receive(:is_a?).with(Net::HTTPSuccess).and_return(true)

      mock_http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:new).and_return(mock_http)
      allow(mock_http).to receive(:use_ssl=)
      allow(mock_http).to receive(:open_timeout=)
      allow(mock_http).to receive(:read_timeout=)
      allow(mock_http).to receive(:request).and_return(mock_response)

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /parse error/)
    end
  end
end
