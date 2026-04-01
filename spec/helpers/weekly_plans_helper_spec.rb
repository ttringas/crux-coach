require "rails_helper"

RSpec.describe WeeklyPlansHelper, type: :helper do
  it "counts unique completed exercises by exercise index and set key" do
    session = build(:planned_session,
      exercises: [ {}, {}, {}, {} ],
      exercise_logs: [
        { "exercise_index" => 0, "completed" => true },
        { "exercise_index" => 0, "completed" => true },
        { "set_key" => "2_0", "completed" => true },
        { "exercise_index" => 3, "completed" => false }
      ])

    expect(helper.completed_exercises_count(session)).to eq(2)
  end
end
