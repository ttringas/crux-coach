# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_03_28_234834) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "ai_interactions", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "interaction_type", null: false
    t.string "provider"
    t.string "model"
    t.text "prompt"
    t.text "response"
    t.integer "tokens_used"
    t.integer "duration_ms"
    t.integer "cost_cents"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["interaction_type"], name: "index_ai_interactions_on_interaction_type"
    t.index ["user_id", "interaction_type"], name: "index_ai_interactions_on_user_id_and_interaction_type"
    t.index ["user_id"], name: "index_ai_interactions_on_user_id"
  end

  create_table "climber_profiles", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.integer "height_inches"
    t.integer "wingspan_inches"
    t.decimal "weight_lbs", precision: 6, scale: 2
    t.integer "years_climbing"
    t.integer "training_age_months"
    t.string "current_max_boulder_grade"
    t.string "current_max_sport_grade"
    t.string "comfortable_boulder_grade"
    t.string "comfortable_sport_grade"
    t.text "preferred_disciplines", default: [], null: false, array: true
    t.text "available_equipment", default: [], null: false, array: true
    t.integer "weekly_training_days"
    t.integer "session_duration_minutes"
    t.text "goals_short_term"
    t.text "goals_long_term"
    t.jsonb "injuries", default: [], null: false
    t.text "style_strengths", default: [], null: false, array: true
    t.text "style_weaknesses", default: [], null: false, array: true
    t.text "additional_context"
    t.boolean "onboarding_completed", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["user_id"], name: "index_climber_profiles_on_user_id", unique: true
  end

  create_table "coach_assignments", force: :cascade do |t|
    t.bigint "coach_id", null: false
    t.bigint "climber_profile_id", null: false
    t.integer "status", default: 0, null: false
    t.datetime "started_at"
    t.datetime "ended_at"
    t.text "coach_notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climber_profile_id", "status"], name: "index_coach_assignments_on_climber_profile_id_and_status"
    t.index ["climber_profile_id"], name: "index_coach_assignments_on_climber_profile_id"
    t.index ["coach_id", "status"], name: "index_coach_assignments_on_coach_id_and_status"
    t.index ["coach_id"], name: "index_coach_assignments_on_coach_id"
    t.index ["status"], name: "index_coach_assignments_on_status"
  end

  create_table "coaches", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.text "bio"
    t.text "specialties", default: [], null: false, array: true
    t.integer "years_coaching"
    t.string "max_grade_boulder"
    t.string "max_grade_sport"
    t.decimal "rate_per_month", precision: 8, scale: 2
    t.boolean "accepting_athletes", default: true, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["accepting_athletes"], name: "index_coaches_on_accepting_athletes"
    t.index ["user_id"], name: "index_coaches_on_user_id", unique: true
  end

  create_table "planned_sessions", force: :cascade do |t|
    t.bigint "weekly_plan_id", null: false
    t.integer "day_of_week", null: false
    t.integer "session_type", null: false
    t.string "title"
    t.text "description"
    t.integer "estimated_duration_minutes"
    t.integer "intensity", null: false
    t.jsonb "exercises", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["session_type"], name: "index_planned_sessions_on_session_type"
    t.index ["weekly_plan_id", "day_of_week"], name: "index_planned_sessions_on_weekly_plan_id_and_day_of_week"
    t.index ["weekly_plan_id"], name: "index_planned_sessions_on_weekly_plan_id"
  end

  create_table "session_logs", force: :cascade do |t|
    t.bigint "climber_profile_id", null: false
    t.bigint "planned_session_id"
    t.integer "session_type", null: false
    t.date "date", null: false
    t.integer "duration_minutes"
    t.integer "perceived_exertion"
    t.integer "energy_level"
    t.integer "skin_condition"
    t.integer "finger_soreness"
    t.integer "general_soreness"
    t.integer "mood"
    t.text "notes"
    t.text "raw_input"
    t.jsonb "structured_data", default: {}, null: false
    t.jsonb "climbs_logged", default: [], null: false
    t.jsonb "exercises_logged", default: [], null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climber_profile_id", "date"], name: "index_session_logs_on_climber_profile_id_and_date"
    t.index ["climber_profile_id"], name: "index_session_logs_on_climber_profile_id"
    t.index ["date"], name: "index_session_logs_on_date"
    t.index ["planned_session_id"], name: "index_session_logs_on_planned_session_id"
    t.index ["session_type"], name: "index_session_logs_on_session_type"
  end

  create_table "training_blocks", force: :cascade do |t|
    t.bigint "climber_profile_id", null: false
    t.string "name"
    t.integer "focus", null: false
    t.integer "weeks_planned"
    t.integer "week_number"
    t.date "started_at"
    t.date "ends_at"
    t.integer "status", default: 0, null: false
    t.text "ai_reasoning"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climber_profile_id", "status"], name: "index_training_blocks_on_climber_profile_id_and_status"
    t.index ["climber_profile_id"], name: "index_training_blocks_on_climber_profile_id"
    t.index ["focus"], name: "index_training_blocks_on_focus"
    t.index ["status"], name: "index_training_blocks_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.string "name"
    t.integer "role", default: 0, null: false
    t.string "avatar"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "weekly_plans", force: :cascade do |t|
    t.bigint "training_block_id", null: false
    t.bigint "climber_profile_id", null: false
    t.integer "week_number"
    t.date "week_of"
    t.integer "status", default: 0, null: false
    t.jsonb "ai_generated_plan", default: {}, null: false
    t.boolean "coach_modified", default: false, null: false
    t.text "coach_notes"
    t.text "summary"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["climber_profile_id", "week_of"], name: "index_weekly_plans_on_climber_profile_id_and_week_of", unique: true
    t.index ["climber_profile_id"], name: "index_weekly_plans_on_climber_profile_id"
    t.index ["status"], name: "index_weekly_plans_on_status"
    t.index ["training_block_id"], name: "index_weekly_plans_on_training_block_id"
    t.index ["week_of"], name: "index_weekly_plans_on_week_of"
  end

  add_foreign_key "ai_interactions", "users"
  add_foreign_key "climber_profiles", "users"
  add_foreign_key "coach_assignments", "climber_profiles"
  add_foreign_key "coach_assignments", "coaches"
  add_foreign_key "coaches", "users"
  add_foreign_key "planned_sessions", "weekly_plans"
  add_foreign_key "session_logs", "climber_profiles"
  add_foreign_key "session_logs", "planned_sessions"
  add_foreign_key "training_blocks", "climber_profiles"
  add_foreign_key "weekly_plans", "climber_profiles"
  add_foreign_key "weekly_plans", "training_blocks"
end
