FactoryBot.define do
  factory :weekly_plan do
    association :training_block
    climber_profile { training_block.climber_profile }
    week_number { 1 }
    week_of { Date.current.beginning_of_week(:monday) }
    status { :active }
    ai_generated_plan { {} }
    coach_modified { false }
    coach_notes { "Keep it easy." }
    summary { "Base week." }
  end
end
