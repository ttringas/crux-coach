require "rails_helper"

RSpec.describe ClimbingBenchmark, type: :model do
  it "is valid with required attributes" do
    benchmark = build(:climbing_benchmark)
    expect(benchmark).to be_valid
  end

  describe "associations" do
    it { is_expected.to belong_to(:climber_profile) }
    it { is_expected.to have_many(:climbing_benchmark_histories).dependent(:destroy) }
  end

  describe "validations" do
    it "requires benchmark_key" do
      benchmark = build(:climbing_benchmark, benchmark_key: nil)
      expect(benchmark).not_to be_valid
    end

    it "enforces unique benchmark_key per climber_profile" do
      profile = create(:climber_profile)
      create(:climbing_benchmark, climber_profile: profile, benchmark_key: "max_pullups")
      duplicate = build(:climbing_benchmark, climber_profile: profile, benchmark_key: "max_pullups")
      expect(duplicate).not_to be_valid
    end

    it "allows same benchmark_key for different profiles" do
      create(:climbing_benchmark, benchmark_key: "max_pullups")
      other = build(:climbing_benchmark, benchmark_key: "max_pullups")
      expect(other).to be_valid
    end
  end

  describe "#definition" do
    it "returns the definition hash for a known key" do
      benchmark = build(:climbing_benchmark, benchmark_key: "max_weighted_hang_20mm")
      expect(benchmark.definition).to be_a(Hash)
      expect(benchmark.definition[:label]).to include("20mm")
    end

    it "returns nil for an unknown key" do
      benchmark = build(:climbing_benchmark, benchmark_key: "unknown_key")
      expect(benchmark.definition).to be_nil
    end
  end

  describe "#label" do
    it "returns the human-readable label for a known key" do
      benchmark = build(:climbing_benchmark, benchmark_key: "max_pullups")
      expect(benchmark.label).to eq("Max Bodyweight Pull-ups")
    end

    it "titleizes unknown keys" do
      benchmark = build(:climbing_benchmark, benchmark_key: "some_custom_thing")
      expect(benchmark.label).to eq("Some Custom Thing")
    end
  end
end
