namespace :training do
  desc "Seed a backdated training block with fake progress for testing"
  task seed_block: :environment do
    email = ENV["USER_EMAIL"] || "tyler@tylertringas.com"
    user = User.find_by(email: email) || User.first
    unless user
      puts "No user found. Create one first."
      exit 1
    end
    puts "Seeding for user: #{user.email}"

    profile = user.climber_profile || user.create_climber_profile(
      onboarding_completed: true,
      years_climbing: 5,
      training_age_months: 24,
      current_max_boulder_grade: "V7",
      current_max_sport_grade: "5.12a",
      comfortable_boulder_grade: "V5",
      comfortable_sport_grade: "5.11a",
      preferred_disciplines: %w[bouldering board],
      available_equipment: %w[hangboard kilter weights pull_up_bar],
      weekly_training_days: 4,
      session_duration_minutes: 90,
      goals_short_term: "Send V8 by summer",
      goals_long_term: "Climb V10 within 2 years",
      style_strengths: %w[power technique],
      style_weaknesses: %w[endurance flexibility]
    )

    # Clean up existing data
    profile.training_blocks.destroy_all
    puts "Cleared existing training blocks."

    # Create a 6-week training block, starting 3 weeks ago
    block_start = 3.weeks.ago.beginning_of_week(:monday).to_date
    block_end = block_start + 5.weeks + 6.days

    block = profile.training_blocks.create!(
      name: "Power Endurance Phase",
      focus: :power_endurance,
      weeks_planned: 6,
      week_number: 4,
      started_at: block_start,
      ends_at: block_end,
      status: :active,
      overall_focus: "Build power endurance capacity for projecting V7-V8 boulders. Emphasize sustained effort on steep terrain, board training, and hangboard protocols with moderate intensity.",
      ai_reasoning: "Based on the climber's plateau at V7 and strong power base, a power endurance phase will help convert raw strength into sending ability on longer sequences."
    )

    # Define session templates per week
    week_templates = [
      # Week 1 (3 weeks ago) - COMPLETED
      {
        focus: "Volume Base Building",
        summary: "High volume moderate intensity climbing with foundational strength",
        sessions: [
          { day: 0, type: :climbing, title: "Limit Bouldering", intensity: :high, duration: 90, desc: "Work V6-V7 problems focusing on power and movement reading. 5-8 hard attempts with full rest." },
          { day: 1, type: :strength, title: "General Strength Foundation", intensity: :moderate, duration: 60, desc: "Full body strength: deadlifts, pull-ups, core circuit. 3x8 moderate weight." },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "Active recovery, stretching, foam rolling." },
          { day: 3, type: :board, title: "Kilter Board Endurance", intensity: :moderate, duration: 75, desc: "High volume moderate grade climbing on Kilter. 15-20 problems at V3-V4, minimal rest." },
          { day: 4, type: :hangboard, title: "Hangboard Protocol", intensity: :high, duration: 45, desc: "Repeaters: 7s on / 3s off x 6 reps, 3 sets on 20mm. Half crimp and open hand." },
          { day: 5, type: :climbing, title: "Outdoor Bouldering", intensity: :moderate, duration: 120, desc: "Outdoor session at local crag. Work variety of styles." },
          { day: 6, type: :mobility, title: "Mobility & Recovery", intensity: :low, duration: 40, desc: "Yoga flow, hip openers, shoulder mobility, antagonist exercises." }
        ]
      },
      # Week 2 (2 weeks ago) - COMPLETED
      {
        focus: "Progressive Overload",
        summary: "Increase intensity from week 1, introduce board projecting",
        sessions: [
          { day: 0, type: :climbing, title: "Projecting Session", intensity: :high, duration: 90, desc: "Work 2-3 project-level problems (V7-V8). Focus on linking sequences." },
          { day: 1, type: :strength, title: "Climbing-Specific Strength", intensity: :moderate, duration: 60, desc: "Weighted pull-ups, ring rows, core: front lever progressions. 4x6." },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "Rest and recovery." },
          { day: 3, type: :board, title: "Kilter Board Projecting", intensity: :high, duration: 80, desc: "Project-level Kilter problems V5-V6. Work limit moves and sequences." },
          { day: 4, type: :hangboard, title: "Max Hangs", intensity: :max_effort, duration: 45, desc: "Max hangs: 10s on, 3 min rest, 5 sets on 18mm. Add weight as needed." },
          { day: 5, type: :climbing, title: "Volume Climbing", intensity: :moderate, duration: 90, desc: "High volume pyramids: 4xV3, 3xV4, 2xV5, 1xV6." },
          { day: 6, type: :mobility, title: "Active Recovery", intensity: :low, duration: 40, desc: "Light cardio, stretching, antagonist work." }
        ]
      },
      # Week 3 (last week) - PARTIALLY COMPLETED (current user is mid-week 4 this week)
      {
        focus: "Intensity Peak",
        summary: "Peak intensity week before deload. Maximum effort sessions.",
        sessions: [
          { day: 0, type: :climbing, title: "Limit Bouldering", intensity: :max_effort, duration: 90, desc: "Attempt V8 problems. Full commitment, full rest between attempts." },
          { day: 1, type: :strength, title: "Power Training", intensity: :high, duration: 60, desc: "Explosive pull-ups, campus board touches, weighted core." },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "Complete rest." },
          { day: 3, type: :board, title: "Board Power Endurance", intensity: :high, duration: 75, desc: "4x4s on Kilter at V4-V5. Minimal rest between problems in a set." },
          { day: 4, type: :hangboard, title: "Repeaters", intensity: :high, duration: 45, desc: "Repeaters on 18mm: 7/3 x 6 reps x 4 sets. Focus on form." },
          { day: 5, type: :outdoor, title: "Outdoor Session", intensity: :moderate, duration: 120, desc: "Outdoor bouldering, apply training to real rock." },
          { day: 6, type: :mobility, title: "Recovery Session", intensity: :low, duration: 40, desc: "Yoga, stretching, light antagonist work." }
        ]
      },
      # Week 4 (this week) - ACTIVE, some sessions done
      {
        focus: "Deload & Recovery",
        summary: "Planned deload week - reduce volume 40%, maintain intensity on key sessions",
        sessions: [
          { day: 0, type: :climbing, title: "Light Bouldering", intensity: :moderate, duration: 60, desc: "Easy to moderate problems. Focus on technique and movement quality." },
          { day: 1, type: :strength, title: "Maintenance Strength", intensity: :low, duration: 40, desc: "Light strength work: 2x8 at reduced weight. Core focus." },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "Full rest." },
          { day: 3, type: :board, title: "Board Technique Session", intensity: :moderate, duration: 60, desc: "Moderate grade Kilter work focusing on footwork and body position." },
          { day: 4, type: :mobility, title: "Mobility Day", intensity: :low, duration: 45, desc: "Extended mobility and flexibility work." },
          { day: 5, type: :climbing, title: "Fun Climbing", intensity: :moderate, duration: 90, desc: "Climb for fun. No pressure, enjoy the movement." },
          { day: 6, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "Rest and prepare for next phase." }
        ]
      },
      # Week 5 (next week) - OUTLINE ONLY
      {
        focus: "Power Endurance Build",
        summary: "Ramp back up with power endurance focus",
        sessions: [
          { day: 0, type: :climbing, title: "Power Endurance Circuits", intensity: :high, duration: 90, desc: "" },
          { day: 1, type: :strength, title: "Strength Endurance", intensity: :moderate, duration: 60, desc: "" },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "" },
          { day: 3, type: :board, title: "Board Endurance Training", intensity: :high, duration: 75, desc: "" },
          { day: 4, type: :hangboard, title: "Hangboard Repeaters", intensity: :moderate, duration: 45, desc: "" },
          { day: 5, type: :climbing, title: "Volume Session", intensity: :moderate, duration: 90, desc: "" },
          { day: 6, type: :mobility, title: "Recovery & Mobility", intensity: :low, duration: 40, desc: "" }
        ]
      },
      # Week 6 (2 weeks from now) - OUTLINE ONLY
      {
        focus: "Performance Testing",
        summary: "Test phase — attempt projects and benchmark progress",
        sessions: [
          { day: 0, type: :climbing, title: "Project Attempts", intensity: :max_effort, duration: 90, desc: "" },
          { day: 1, type: :strength, title: "Maintenance Strength", intensity: :moderate, duration: 50, desc: "" },
          { day: 2, type: :rest, title: "Rest Day", intensity: :low, duration: 0, desc: "" },
          { day: 3, type: :board, title: "Board Benchmark Session", intensity: :high, duration: 75, desc: "" },
          { day: 4, type: :hangboard, title: "Max Hang Test", intensity: :max_effort, duration: 40, desc: "" },
          { day: 5, type: :climbing, title: "Send Day", intensity: :high, duration: 120, desc: "" },
          { day: 6, type: :rest, title: "Block Complete Rest", intensity: :low, duration: 0, desc: "" }
        ]
      }
    ]

    today = Date.current
    today_dow = (today.wday + 6) % 7  # 0=Monday

    week_templates.each_with_index do |week_data, week_index|
      week_of = block_start + (week_index * 7)

      is_past = (week_of + 6) < today
      is_current = week_of <= today && (week_of + 6) >= today

      wp_status = if is_past
        :completed
      elsif is_current
        :active
      else
        :draft
      end

      wp = profile.weekly_plans.create!(
        training_block: block,
        week_number: week_index + 1,
        week_of: week_of,
        status: wp_status,
        ai_generated_plan: { summary: week_data[:summary], sessions: week_data[:sessions] },
        summary: week_data[:summary],
        week_focus: week_data[:focus]
      )

      week_data[:sessions].each_with_index do |session_data, pos|
        session_status = if is_past
          session_data[:type] == :rest ? :skipped : :completed
        elsif is_current && session_data[:day] < today_dow
          session_data[:type] == :rest ? :skipped : :completed
        elsif is_current && session_data[:day] == today_dow
          :in_progress
        else
          :todo
        end

        ps = wp.planned_sessions.create!(
          day_of_week: session_data[:day],
          session_type: session_data[:type],
          title: session_data[:title],
          description: session_data[:desc],
          estimated_duration_minutes: session_data[:duration],
          intensity: session_data[:intensity],
          exercises: [],
          position: pos,
          status: session_status,
          started_at: session_status.in?([ :completed, :in_progress ]) ? (week_of + session_data[:day]).to_time : nil,
          completed_at: session_status == :completed ? (week_of + session_data[:day]).to_time + session_data[:duration].to_i.minutes : nil,
          perceived_exertion: session_status == :completed ? rand(5..8) : nil,
          energy_level: session_status == :completed ? rand(3..5) : nil,
          finger_soreness: session_status == :completed ? rand(1..3) : nil,
          general_soreness: session_status == :completed ? rand(1..3) : nil
        )

        # Create session logs for completed sessions
        if session_status == :completed && session_data[:type] != :rest
          profile.session_logs.create!(
            planned_session: ps,
            session_type: session_data[:type],
            date: week_of + session_data[:day],
            duration_minutes: session_data[:duration],
            perceived_exertion: ps.perceived_exertion,
            energy_level: ps.energy_level,
            finger_soreness: ps.finger_soreness,
            general_soreness: ps.general_soreness,
            notes: "Completed as planned. Felt good.",
            mood: rand(3..5)
          )
        end
      end

      puts "Created week #{week_index + 1}: #{week_data[:focus]} (#{wp_status})"
    end

    puts "\nTraining block seeded successfully!"
    puts "Block: #{block.name} (#{block.started_at} to #{block.ends_at})"
    puts "Total weekly plans: #{block.weekly_plans.count}"
    puts "Total sessions: #{block.weekly_plans.sum { |wp| wp.planned_sessions.count }}"
    puts "Completed sessions: #{PlannedSession.joins(:weekly_plan).where(weekly_plans: { training_block_id: block.id }).where(status: :completed).count}"
  end
end
