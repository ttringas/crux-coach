require "rails_helper"

RSpec.describe ClimbingBenchmarkHistory, type: :model do
  it "is valid with required attributes" do
    history = build(:climbing_benchmark_history)
    expect(history).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:climbing_benchmark) }
  end
end
