class BenchmarksController < ApplicationController
  def index
    profile = current_climber_profile
    existing = profile.climbing_benchmarks.index_by(&:benchmark_key)

    @grouped_benchmarks = ClimbingBenchmark::CATEGORIES.map do |category|
      definitions = ClimbingBenchmark::BENCHMARK_DEFINITIONS.select { |d| d[:category] == category }
      benchmarks = definitions.map do |defn|
        existing[defn[:key]] || profile.climbing_benchmarks.build(benchmark_key: defn[:key], unit: defn[:unit])
      end
      [category, benchmarks]
    end
  end

  def update
    profile = current_climber_profile
    key = params[:benchmark_key] || params[:id]
    benchmark = profile.climbing_benchmarks.find_or_initialize_by(benchmark_key: key)

    old_value = benchmark.value
    defn = ClimbingBenchmark::DEFINITIONS_BY_KEY[key]
    benchmark.unit ||= defn&.dig(:unit)

    benchmark.assign_attributes(benchmark_params)

    if benchmark.save
      if old_value.present? && old_value != benchmark.value
        benchmark.climbing_benchmark_histories.create!(
          value: old_value,
          tested_at: benchmark.tested_at,
          notes: "Previous value"
        )
      end

      respond_to do |format|
        format.json { render json: { status: "ok", value: benchmark.value, tested_at: benchmark.tested_at } }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "benchmark_#{benchmark.benchmark_key}",
            partial: "benchmarks/benchmark_row",
            locals: { benchmark: benchmark, definition: defn }
          )
        end
        format.html { redirect_to benchmarks_path, notice: "Benchmark updated." }
      end
    else
      respond_to do |format|
        format.json { render json: { status: "error", errors: benchmark.errors.full_messages }, status: :unprocessable_entity }
        format.turbo_stream do
          render turbo_stream: turbo_stream.replace(
            "benchmark_#{benchmark.benchmark_key}",
            partial: "benchmarks/benchmark_row",
            locals: { benchmark: benchmark, definition: defn }
          )
        end
        format.html { redirect_to benchmarks_path, alert: "Could not save benchmark." }
      end
    end
  end

  private

  def benchmark_params
    params.require(:benchmark).permit(:value, :tested_at, :notes)
  end
end
