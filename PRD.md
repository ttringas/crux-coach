# Crux Coach — Product Requirements Document (v1)

_Working name — TBD. "Sponsored with love by Brooklyn Uprising."_

## Overview

Adaptive AI climbing training app with optional human coach layer. Generates personalized weekly training plans based on climber profile, goals, injuries, and session history. Coaches can optionally review/tweak plans and provide video feedback (video review deferred to v2).

## Core Decisions

- **Gym agnostic** — no gym-specific features in v1. BK UP integration layered later.
- **Standalone brand** — separate from BK UP, "sponsored with love by Brooklyn Uprising"
- **AI-first, coach-optional** — AI generates full plans autonomously. Coaches are an upgrade layer who can tweak/override.
- **Free for now** — full app free. Monetization (freemium + coach rev-share) added later.
- **Rails 8 + Hotwire + Tailwind + Postgres** — same stack as bkup-app
- **Web-first** — Rails responsive web app. iOS planned for later.
- **Multi-provider AI** — abstract AI calls behind a provider layer (Anthropic, OpenAI, etc.)

## Tech Stack

- Ruby on Rails 8
- Hotwire (Turbo + Stimulus)
- Tailwind CSS
- PostgreSQL
- Solid Queue (background jobs)
- Multi-provider AI service layer (Anthropic Claude, OpenAI GPT, etc.)
- Devise or similar for auth (email + password for now, magic link later)
- RSpec + system tests

## Data Model

### Users
- email, password (Devise)
- role: climber | coach | admin
- name, avatar

### ClimberProfile (belongs_to :user)
- height, wingspan, weight (all optional)
- years_climbing
- training_age_months
- current_max_boulder_grade
- current_max_sport_grade
- comfortable_boulder_grade (onsight/flash level)
- comfortable_sport_grade
- preferred_disciplines (array: bouldering, sport, trad, outdoor, board)
- available_equipment (array: hangboard, campus_board, kilter, moonboard, tension, weights, pull_up_bar, rings, etc.)
- weekly_training_days (integer)
- session_duration_minutes (typical)
- goals_short_term (text — free form, AI parses)
- goals_long_term (text)
- injuries (jsonb array: [{area, severity, notes, date_started, still_active}])
- style_strengths (array: power, endurance, technique, flexibility, compression, slab, steep, coordination)
- style_weaknesses (array: same options)
- additional_context (text — anything else the AI should know)

### Coach (belongs_to :user)
- bio
- specialties (array)
- years_coaching
- max_grade_boulder
- max_grade_sport
- rate_per_month (decimal, nullable — for future monetization)
- accepting_athletes (boolean)
- athlete_count (integer, counter cache)

### CoachAssignment (belongs_to :coach, belongs_to :climber_profile)
- status: active | paused | ended
- started_at, ended_at
- coach_notes (text)

### TrainingBlock
- belongs_to :climber_profile
- name (e.g. "Power Phase", "Base Building")
- focus (enum: power, power_endurance, endurance, technique, base, deload, project)
- weeks_planned (integer)
- week_number (current week in block)
- started_at, ends_at
- status: active | completed | abandoned
- ai_reasoning (text — why this block was chosen)

### WeeklyPlan
- belongs_to :training_block
- belongs_to :climber_profile
- week_number
- week_of (date — Monday of the week)
- status: draft | active | completed
- ai_generated_plan (jsonb — full structured plan)
- coach_modified (boolean)
- coach_notes (text)
- summary (text — human readable)

### PlannedSession
- belongs_to :weekly_plan
- day_of_week (integer 0-6)
- session_type (enum: climbing, board, hangboard, strength, cardio, mobility, rest, outdoor)
- title (string — e.g. "Power Bouldering + Hangboard")
- description (text — detailed session plan)
- estimated_duration_minutes
- intensity (enum: low, moderate, high, max)
- exercises (jsonb — structured list of exercises/sets/reps/rest)

### SessionLog
- belongs_to :climber_profile
- belongs_to :planned_session (nullable — can log unplanned sessions)
- session_type (same enum as PlannedSession)
- date
- duration_minutes
- perceived_exertion (1-10 scale)
- energy_level (1-5)
- skin_condition (1-5, for finger skin)
- finger_soreness (1-5)
- general_soreness (1-5)
- mood (1-5)
- notes (text — free form)
- raw_input (text — original voice/text input before structuring)
- structured_data (jsonb — AI-parsed structured session data)
- climbs_logged (jsonb array: [{grade, style, attempts, sent, flash, notes}])
- exercises_logged (jsonb array: [{name, sets, reps, weight, duration, notes}])

### AiInteraction (for debugging/audit)
- belongs_to :user
- interaction_type (enum: plan_generation, session_parsing, profile_analysis, coach_suggestion)
- provider (string — anthropic, openai, etc.)
- model (string)
- prompt (text)
- response (text)
- tokens_used (integer)
- duration_ms (integer)
- cost_cents (integer, nullable)

## Key Features — MVP

### 1. Onboarding Flow
Multi-step form that builds ClimberProfile:
- Step 1: Basics (name, climbing experience, current level)
- Step 2: Goals (short term, long term, target grades)
- Step 3: Available equipment & training schedule
- Step 4: Injuries & limitations
- Step 5: Style preferences & additional context
- Step 6: AI generates first training block + weekly plan

Should feel conversational and quick (< 5 min). Skip-able fields where possible.

### 2. Dashboard (Home)
- Today's planned session (if any)
- This week's plan overview
- Recent session logs
- Quick log button
- Current training block status
- Streak / consistency indicator (subtle, not gamified)

### 3. Weekly Plan View
- Calendar-style week view
- Each day shows planned session with type icon, title, intensity
- Click to expand full session details
- Status indicators (completed, skipped, modified)
- "Generate Next Week" button
- Coach notes (if coach is assigned)

### 4. Session Logging
**Two input modes:**

**A. Natural Language Input (primary)**
Text area where climber describes their session in plain language:
> "Did about 90 minutes of bouldering at the gym. Worked on some V5s and V6s, sent two V5s and fell on the crux of a V6 project like 8 times. Fingers feel ok but my left shoulder is a little tweaky. Also did 20 min of hangboard — 3 sets of 10 sec half crimp on 20mm."

AI parses this into structured data, shows the structured version for confirmation/edit.

**B. Structured Form (secondary)**
Traditional form with fields for exercises, grades, attempts, etc. For users who prefer manual entry.

Both modes should support:
- Climbing sessions (grades, attempts, sends)
- Board sessions (Kilter, Moon, Tension — grades, attempts)
- Hangboard protocols
- Strength training (exercises, sets, reps, weight)
- Cardio
- Mobility/stretching
- Mixed sessions

### 5. AI Plan Generation
The core AI feature. Given:
- Full climber profile
- Training history (all past session logs)
- Current training block and phase
- Recent sessions and reported soreness/energy
- Coach notes/modifications (if any)

Generate:
- Next week's daily plan
- Session-level detail (exercises, sets, reps, rest, climbing focus)
- Brief reasoning for the plan choices
- Adjustments based on missed sessions or reported issues

The AI should:
- Respect injury constraints
- Auto-deload when compliance drops or soreness spikes
- Vary stimulus appropriately
- Include climbing AND non-climbing training
- Be specific enough to follow but flexible enough to adapt

### 6. Coach Dashboard
For users with role: coach:
- List of assigned athletes
- View athlete's profile, history, current plan
- Edit/override weekly plans before delivery
- Add notes and context
- "AI Draft" button — generates plan, coach reviews before athlete sees it
- Flag concerns (overtraining, injury risk)

### 7. Coach Directory & Assignment
- Browse available coaches (public profiles)
- Request coaching
- Coach accepts/declines
- Simple assignment — one active coach per climber

### 8. Profile & Settings
- Edit climber profile anytime
- Update injuries
- Change training preferences
- View AI interaction history (optional transparency)

### 9. Progress View
- Session frequency over time
- Grade progression (self-reported)
- Training volume trends
- Consistency metrics
- Soreness/energy trends

## AI Service Architecture

```
app/services/ai/
  client.rb          — abstract base, handles provider routing
  providers/
    anthropic.rb     — Claude API
    openai.rb        — GPT API
  prompts/
    plan_generator.rb     — weekly plan generation prompt builder
    session_parser.rb     — natural language → structured session
    profile_analyzer.rb   — analyze profile for plan context
    coach_assistant.rb    — help coaches with suggestions
  plan_generator.rb  — orchestrates plan generation
  session_parser.rb  — orchestrates session parsing
```

Provider selection via ENV or config — easy to swap/test different models.

## Design Direction

- Clean, understated, serious
- Dark mode default (climbers train evening)
- Monochrome with selective accent color (amber or teal)
- Strong typography, information-dense but not cluttered
- No gamification theater — no confetti, no "you crushed it!" language
- Feels like a training notebook, not a wellness app
- Mobile-responsive from day one (most logging happens on phone)

## Pages / Routes

```
/ — Landing page (marketing)
/signup — Registration
/onboarding — Multi-step profile setup
/dashboard — Home / today view
/plan — Current week plan
/plan/:id — Historical week plan
/log/new — New session log
/log/:id — View session log
/logs — Session history
/progress — Progress dashboard
/profile — Edit profile
/coaches — Coach directory
/coach/dashboard — Coach home (coach role)
/coach/athletes/:id — View athlete (coach role)
/coach/athletes/:id/plan — Edit athlete plan (coach role)
/settings — Account settings
```

## Non-Functional Requirements

- Full RSpec test suite (models, services, requests, system tests)
- Responsive design (mobile-first)
- Fast page loads (Hotwire, minimal JS)
- AI calls are background jobs (don't block UI)
- Secure API key storage (Rails credentials)
- Seeds file with sample data for development

## What's Explicitly NOT in v1

- Video upload/review
- Real-time voice input (text only for now)
- iOS native app
- Gym-specific features / route catalogs
- Payment processing
- Social features / community feed
- Wearable integrations
- Board app integrations (API-level)

## Name Ideas (TBD)
- Crux Coach
- SendPlan
- ProjectBoard
- Beta Coach
- The Crux
- Crimp (taken?)
