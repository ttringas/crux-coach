FactoryBot.define do
  factory :training_block do
    association :climber_profile
    name { "Base Building" }
    focus { :base }
    weeks_planned { 4 }
    week_number { 1 }
    started_at { Date.current.beginning_of_week(:monday) }
    ends_at { started_at + 4.weeks }
    status { :active }
    ai_reasoning { "Plan tuned to base phase." }
  end
end
