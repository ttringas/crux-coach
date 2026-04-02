# Seeds for Crux Coach development

def upsert_user(email:, name:, role:, password:)
  user = User.find_or_initialize_by(email: email)
  user.name = name
  user.role = role
  user.password = password if user.new_record?
  user.save!
  user
end

coach_user = upsert_user(
  email: "coach@cruxcoach.dev",
  name: "Avery Coach",
  role: :coach,
  password: "password123"
)

coach = Coach.find_or_initialize_by(user: coach_user)
coach.assign_attributes(
  bio: "Former comp climber focused on sustainable performance.",
  specialties: [ "power", "endurance", "technique" ],
  years_coaching: 8,
  max_grade_boulder: "V12",
  max_grade_sport: "5.14b",
  rate_per_month: 250,
  accepting_athletes: true
)
coach.save!

climber_one_user = upsert_user(
  email: "climber1@cruxcoach.dev",
  name: "Sam Climber",
  role: :climber,
  password: "password123"
)

climber_two_user = upsert_user(
  email: "climber2@cruxcoach.dev",
  name: "Jordan Climber",
  role: :climber,
  password: "password123"
)

climber_one_profile = ClimberProfile.find_or_initialize_by(user: climber_one_user)
climber_one_profile.assign_attributes(
  height_inches: 70,
  wingspan_inches: 72,
  weight_lbs: 165.5,
  years_climbing: 4,
  training_age_years: 1.5,
  current_max_boulder_grade: "V7",
  current_max_sport_grade: "5.12a",
  comfortable_boulder_grade: "V5",
  comfortable_sport_grade: "5.11b",
  preferred_disciplines: [ "bouldering", "board" ],
  available_equipment: [ "hangboard", "training_board", "weights" ],
  weekly_training_days: 4,
  session_duration_minutes: 90,
  goals_short_term: "Send a V8 on the board and improve finger strength.",
  goals_long_term: "Build power endurance for long boulders.",
  injuries: [],
  style_strengths: [ "power", "compression" ],
  style_weaknesses: [ "endurance", "slab" ],
  additional_context: "Works a 9-5 and trains evenings.",
  onboarding_completed: true
)
climber_one_profile.save!

climber_two_profile = ClimberProfile.find_or_initialize_by(user: climber_two_user)
climber_two_profile.assign_attributes(
  height_inches: 64,
  wingspan_inches: 66,
  weight_lbs: 130.0,
  years_climbing: 2,
  training_age_years: 0.7,
  current_max_boulder_grade: "V5",
  current_max_sport_grade: "5.11a",
  comfortable_boulder_grade: "V4",
  comfortable_sport_grade: "5.10d",
  preferred_disciplines: [ "sport", "outdoor" ],
  available_equipment: [ "hangboard", "pull_up_bar" ],
  weekly_training_days: 3,
  session_duration_minutes: 75,
  goals_short_term: "Increase aerobic endurance for longer routes.",
  goals_long_term: "Redpoint 5.12a outdoors.",
  injuries: [],
  style_strengths: [ "technique", "endurance" ],
  style_weaknesses: [ "power" ],
  additional_context: "Prefers weekend outdoor sessions.",
  onboarding_completed: true
)
climber_two_profile.save!

CoachAssignment.find_or_create_by!(coach: coach, climber_profile: climber_one_profile) do |assignment|
  assignment.status = :active
  assignment.started_at = Time.current
  assignment.coach_notes = "Focus on finger strength and board power."
end

current_week_start = Date.current.beginning_of_week(:monday)

block_one = TrainingBlock.find_or_initialize_by(climber_profile: climber_one_profile, name: "Power Phase 1")
block_one.assign_attributes(
  focus: :power,
  weeks_planned: 4,
  week_number: 1,
  started_at: current_week_start,
  ends_at: current_week_start + 27,
  status: :active,
  ai_reasoning: "Prioritize max strength for upcoming projects."
)
block_one.save!

plan_one = WeeklyPlan.find_or_initialize_by(climber_profile: climber_one_profile, week_of: current_week_start)
plan_one.assign_attributes(
  training_block: block_one,
  week_number: 1,
  status: :active,
  ai_generated_plan: { focus: "power", notes: "Board + hangboard emphasis" },
  coach_modified: true,
  coach_notes: "Added extra mobility session.",
  summary: "Power block week 1"
)
plan_one.save!

PlannedSession.find_or_initialize_by(weekly_plan: plan_one, day_of_week: 1, title: "Board Power + Hangboard") do |session|
  session.session_type = :board
  session.description = "Limit boulders on board, then max hangs."
  session.estimated_duration_minutes = 90
  session.intensity = :high
  session.exercises = [ { name: "Max hangs", sets: 5, duration_seconds: 10, rest_seconds: 180 } ]
end

PlannedSession.find_or_initialize_by(weekly_plan: plan_one, day_of_week: 3, title: "Strength + Mobility") do |session|
  session.session_type = :strength
  session.description = "Pull + core with mobility cooldown."
  session.estimated_duration_minutes = 75
  session.intensity = :moderate
  session.exercises = [ { name: "Weighted pull-ups", sets: 4, reps: 5 } ]
end

block_two = TrainingBlock.find_or_initialize_by(climber_profile: climber_two_profile, name: "Base Endurance")
block_two.assign_attributes(
  focus: :endurance,
  weeks_planned: 6,
  week_number: 2,
  started_at: current_week_start - 7,
  ends_at: current_week_start + 35,
  status: :active,
  ai_reasoning: "Build aerobic base for longer routes."
)
block_two.save!

plan_two = WeeklyPlan.find_or_initialize_by(climber_profile: climber_two_profile, week_of: current_week_start)
plan_two.assign_attributes(
  training_block: block_two,
  week_number: 2,
  status: :active,
  ai_generated_plan: { focus: "endurance", notes: "ARC + easy mileage" },
  coach_modified: false,
  summary: "Base week 2"
)
plan_two.save!

PlannedSession.find_or_initialize_by(weekly_plan: plan_two, day_of_week: 2, title: "ARC Climbing") do |session|
  session.session_type = :climbing
  session.description = "60-75 min continuous easy climbing."
  session.estimated_duration_minutes = 75
  session.intensity = :low
  session.exercises = []
end

PlannedSession.find_or_initialize_by(weekly_plan: plan_two, day_of_week: 5, title: "Outdoor Mileage") do |session|
  session.session_type = :outdoor
  session.description = "Easy routes, focus on volume."
  session.estimated_duration_minutes = 120
  session.intensity = :moderate
  session.exercises = []
end

library_path = ExerciseLibrary::Importer::DEFAULT_PATH
if File.exist?(library_path)
  ExerciseLibrary::Importer.import_from_json!(library_path)
else
  puts "Exercise library seed skipped: #{library_path} not found."
end
