require "rails_helper"

RSpec.describe Ai::Providers::OpenAi do
  let(:api_key) { "sk-openai-test-key" }

  before do
    allow(ENV).to receive(:fetch).and_call_original
    allow(ENV).to receive(:fetch).with("OPENAI_API_KEY").and_return(api_key)
    Rails.configuration.x.ai.request_timeout = 30
    Rails.configuration.x.ai.max_tokens = 2000
  end

  describe ".generate" do
    let(:success_response) do
      {
        "choices" => [
          { "message" => { "content" => "Hello from GPT" } }
        ],
        "model" => "gpt-4o",
        "usage" => {
          "prompt_tokens" => 40,
          "completion_tokens" => 20,
          "total_tokens" => 60
        }
      }
    end

    let(:mock_client) { instance_double(OpenAI::Client) }

    before do
      allow(OpenAI::Client).to receive(:new).and_return(mock_client)
    end

    it "makes a correct API call and returns parsed response" do
      allow(mock_client).to receive(:chat).and_return(success_response)

      result = described_class.generate(prompt: "Hello", system: "Be helpful")

      expect(result[:content]).to eq("Hello from GPT")
      expect(result[:tokens_used]).to eq(60)
      expect(result[:input_tokens]).to eq(40)
      expect(result[:output_tokens]).to eq(20)
      expect(result[:provider]).to eq("openai")
      expect(result[:model]).to eq("gpt-4o")

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(
          model: "gpt-4o",
          messages: [
            { role: "system", content: "Be helpful" },
            { role: "user", content: "Hello" }
          ],
          max_tokens: 2000,
          temperature: 0.2
        )
      )
    end

    it "omits system message when system is nil" do
      allow(mock_client).to receive(:chat).and_return(success_response)

      described_class.generate(prompt: "Hello", system: nil)

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(
          messages: [{ role: "user", content: "Hello" }]
        )
      )
    end

    it "raises Ai::Client::Error on API error response" do
      error_response = { "error" => { "message" => "Insufficient quota" } }
      allow(mock_client).to receive(:chat).and_return(error_response)

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /Insufficient quota/)
    end

    it "raises Ai::Client::Error on OpenAI::Error" do
      allow(mock_client).to receive(:chat).and_raise(OpenAI::Error.new("Connection failed"))

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /OpenAI API error/)
    end

    it "raises Ai::Client::Error on network timeout" do
      allow(mock_client).to receive(:chat).and_raise(Net::ReadTimeout)

      expect {
        described_class.generate(prompt: "Hello")
      }.to raise_error(Ai::Client::Error, /network error/)
    end

    it "uses custom model when provided" do
      allow(mock_client).to receive(:chat).and_return(success_response)

      described_class.generate(prompt: "Hello", model: "gpt-4o-mini")

      expect(mock_client).to have_received(:chat).with(
        parameters: hash_including(model: "gpt-4o-mini")
      )
    end
  end
end
