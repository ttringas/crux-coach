# AI Climbing Coach App Market Research + Product Spec

_Date: 2026-03-28_

## Executive Summary

There is a real product opportunity here, but the opportunity is narrower and more specific than “AI for climbing.” The market already has:

1. **serious climbing training brands** (Lattice, Crimpd, TrainingBeta, Eric Hörst-style content),
2. **digital board ecosystems** (MoonBoard, Kilter Board, Tension Board),
3. **social/logging apps** (KAYA, MyClimb, assorted training logs), and
4. **AI-ish fitness products** in mainstream strength/wearables (Future, Tempo, Tonal, WHOOP Coach).

What does **not** yet exist in a convincing way is a product that combines:
- persistent climbing-specific athlete memory,
- structured coaching logic,
- usable video analysis with visual overlays,
- gym-native route and board data,
- and a long-lived performance dataset that compounds over time.

That is the wedge. Not “a chatbot that knows heel hooks.”

The strongest version of this product is a **serious training system for climbers** with three interlocking loops:
1. **Plan**: adaptive weekly programming based on goals, constraints, and recent load.
2. **Observe**: analyze climbing videos, session outcomes, route attempts, and board performance.
3. **Compound**: the app gets more useful as it accumulates user-specific and gym-specific data.

For BK UP specifically, there is an additional strategic advantage: a gym can generate proprietary data around route inventory, style taxonomy, setter intent, spray wall usage, board performance, and community video. That creates a real moat if the product is built as a gym-integrated coaching system first and a generic consumer app second.

My blunt take: **video analysis is promising but should not be oversold in v1**. Today’s pose-estimation stack is good enough for coarse biomechanical and sequencing signals, but not good enough to reliably infer nuanced climbing technique or intent without lots of domain-specific labeling and strong UX guardrails. The moat is not raw CV alone. The moat is the combination of **domain model + structured logs + gym integrations + accumulated user history + selective video analysis.**

---

## 1. Competitive Landscape

## Market map

The market breaks into five clusters:

### A. Coaching-first climbing products
- Lattice Training
- Crimpd (Lattice)
- TrainingBeta
- Eric Hörst digital products / self-coached content
- individual remote coaches / PDF plans

### B. Board ecosystems
- MoonBoard
- Kilter Board
- Tension Board / Tension Board 2

### C. Social + climbing log + beta products
- KAYA
- MyClimb
- gym apps and route-tracking products

### D. General AI / connected-fitness coaching products
- Future
- Tempo
- Tonal
- WHOOP Coach / WHOOP ecosystem

### E. Emerging AI sports-analysis products adjacent to climbing
- AI golf swing analyzers
- running form analyzers
- tennis stroke analysis tools
- generic pose-analysis stacks and sport-specific startups

The key insight is that climbers already stitch together multiple tools:
- a training source (Lattice / Crimpd / TrainingBeta / coach)
- a board app (Moon/Kilter/Tension)
- a social/logging app (KAYA or Notes / spreadsheet / Notion / paper)
- video replay from iPhone camera roll

There is no dominant product that unifies all four in a way serious climbers would trust.

---

## Competitive profiles

## 1) Lattice Training
- **URL:** https://latticetraining.com
- **Pricing model:** mix of free assessments, paid plans, coaching, courses, and hardware. Site currently shows a remote climbing assessment at **$30** and promotes a free trial for LatticePlans. Market anecdotes suggest higher-ticket recurring coaching tiers well above commodity app pricing.
- **What it does:** remote assessments, customized training plans, coaching, training education, hardware, and now a more integrated app/plan experience.
- **Tech approach:** hybrid of **sports-science branding + structured training logic + human coaches + proprietary assessment models**. Not pure AI; more “intelligent training system” layered over coach workflows.
- **Strengths:**
  - strongest brand in serious climbing training
  - credibility with high-end climbers
  - strong content engine and educational trust
  - compounding dataset from assessments and coached athletes
  - productized ladder from free → low-ticket → premium coaching
- **Weaknesses:**
  - historically fragmented product surface (coaching, Crimpd, assessments, shop)
  - can feel prescriptive and training-centric rather than gym-native or community-native
  - premium offers are expensive relative to what many climbers will sustain
  - still not obviously a “daily operating system” for all climbing life
- **Traction / revenue clues:** no public revenue I could verify cleanly in-source here, but brand strength is clearly high; testimonial stack includes marquee climbers and years of market presence.
- **Takeaway:** Lattice is the incumbent for **seriousness and authority**. Any BK UP product should avoid trying to out-Lattice Lattice on generic training science alone.

## 2) Crimpd (by Lattice)
- **URL:** https://www.crimpd.com
- **Pricing model:** free base plus paid upgrade/subscription for more advanced planning and tracking features.
- **What it does:** workout library, structured sessions, training plans, tracking, scheduling, exercise demos, templates for climbing-specific off-wall and on-wall training.
- **Tech approach:** largely **structured library + templated plans + logging**, with Lattice methodology behind it. More software product than coach marketplace.
- **Strengths:**
  - probably the cleanest “training utility” in climbing
  - strong reputation for useful workouts without fluff
  - clear value even for self-coached climbers
  - lower-friction entry point than premium coaching
- **Weaknesses:**
  - feels like a workout planner/tracker more than a full coach
  - weak moat if reduced to a library + calendar + timer
  - not inherently social or gym-integrated
  - not video-analysis-led
- **Traction clues:** lots of positive public user commentary; long-standing adoption among climbers as a practical training app.
- **Takeaway:** Crimpd proves climbers will pay for **serious, unsexy utility software** if it saves cognitive load.

## 3) TrainingBeta
- **URL:** https://www.trainingbeta.com
- **Pricing model:** paid training programs, coaching, nutrition offerings, injury protocols, courses/content.
- **What it does:** training blog, podcast, coaching, route/bouldering programs, nutrition, mindset, rehab/injury content.
- **Tech approach:** **content/media funnel + coaching + digital products**. More educational brand than software platform.
- **Strengths:**
  - wide trust surface via content and podcast
  - broader lifestyle coverage than pure training apps
  - accessible for self-coached climbers
- **Weaknesses:**
  - feels like a content business with products, not a compounding software system
  - likely lower daily engagement than a habit-forming app
  - limited defensibility if content is the core asset
- **Traction clues:** longevity and breadth are strong; public podcast/content footprint suggests durable niche authority.
- **Takeaway:** This validates demand for **guidance and education**, but not necessarily for a software moat.

## 4) Eric Hörst / training-manual style digital products
- **URL:** authoritative content/books/programs associated with Eric Hörst; modern web presence varies by product
- **Pricing model:** books, ebooks, courses, plans, educational content
- **What it does:** classic climbing training frameworks, periodization ideas, finger strength, technique, mental training
- **Tech approach:** **expert-authored static methodology**
- **Strengths:**
  - deep trust from legacy audience
  - excellent for serious self-coached climbers
  - timeless training frameworks
- **Weaknesses:**
  - static, not adaptive
  - little data flywheel
  - no real-time feedback or habit engine
- **Takeaway:** useful benchmark for philosophical positioning: serious, craft-respecting, non-gimmicky.

## 5) MoonBoard
- **URL:** https://moonclimbing.com/moonboard
- **Pricing model:** hardware ecosystem plus app/software access around the board
- **What it does:** standardized benchmark board, community problems, logging, ranking, repeatable training environment
- **Tech approach:** **hardware + problem database + standardized benchmarking**
- **Strengths:**
  - global standardization
  - strong signal quality: repeats on known problems mean something
  - powerful training loop for strong climbers
  - sticky because hardware and community reinforce each other
- **Weaknesses:**
  - narrow use case; not a general coaching platform
  - technique insight is limited to performance data and community content
  - can become grade-chasing and skin/tendon-hostile if used badly
- **Takeaway:** the real value is not the app UI; it is the **standardized environment and benchmark dataset**.

## 6) Kilter Board
- **URL:** Kilter ecosystem / Setter Closet info pages; hardware and app are part of a combined system
- **Pricing model:** hardware-heavy. Public pricing references indicate a 7’x10’ hardware+LED package starting around **$5,000** for Fullride hardware or **$7,500** for OG hardware, with total bundle costs much higher once frames, panels, mats, shipping, and install are included.
- **What it does:** adjustable, illuminated training board with community problems and broad gym adoption.
- **Tech approach:** **hardware + app + crowdsourced problem database + angle-adjusted utility**
- **Strengths:**
  - broad appeal from moderate climbers to crushers
  - highly gym-friendly
  - huge practical engagement because it is fun and measurable
  - better accessibility than MoonBoard for many users
- **Weaknesses:**
  - still mostly a board ecosystem, not a full coaching product
  - community data is useful but noisy
  - focus is problem discovery/performance, not skill diagnosis
- **Takeaway:** Kilter demonstrates how a product becomes sticky when it is embedded in physical gym infrastructure.

## 7) Tension Board / Tension Board 2
- **URL:** https://tensionclimbing.com/products/tension-board-2
- **Pricing model:** hardware + optional LED system. Public page currently shows a TB2 configuration at roughly **$15,152** for one package, excluding wall/panels/hardware details.
- **What it does:** board climbing with dense hold sets, app-linked lighting/options, community problems.
- **Tech approach:** **hardware + problem database + standardized training environment**
- **Strengths:**
  - serious training credibility
  - strong appeal for stronger climbers and board aficionados
  - again, high signal from standardized terrain
- **Weaknesses:**
  - niche compared with a full gym-life product
  - not beginner-friendly as a primary wedge
- **Takeaway:** all board apps show the same thing: **standardized environments generate better training data than freeform gym climbing.**

## 8) KAYA
- **URL:** https://kayaclimb.com/
- **Pricing model:** appears to use a freemium/community model with gym and guide relationships; exact current consumer pricing was not clearly exposed in fetched source.
- **What it does:** beta videos, offline GPS guides, gym route updates, progression tracking, social features, community comments, biometrics-aware beta discovery.
- **Tech approach:** **community content + social graph + route database + gym partnerships**
- **Strengths:**
  - strongest current climbing app on community/media side
  - huge beta-video corpus (site claims over **1 million beta videos**)
  - meaningful gym footprint (site claims **300+ gyms** and over **300k outdoor climbs**)
  - creates habit loop through route discovery, updates, and social interaction
- **Weaknesses:**
  - social/beta utility is not the same as deep coaching
  - signal quality of user videos/comments can be uneven
  - hard to become a trusted training authority from a community-first base
- **Takeaway:** KAYA is probably the most important non-Lattice competitor because it owns attention and user-generated climbing media. If BK UP wants a dataset moat, this is the nearest analog.

## 9) MyClimb
- **URL:** product visibility appears primarily app-store/app channels
- **Pricing model:** typical mobile climbing app freemium/subscription pattern
- **What it does:** training logs, hangboard/strength tracking, session planning, progress tracking; generally aimed at self-coached climbers.
- **Tech approach:** **logbook + timers + progress tracking**
- **Strengths:**
  - useful for dedicated self-trackers
  - lower complexity than community products
  - can become a “single-user utility knife”
- **Weaknesses:**
  - limited brand power relative to Lattice/KAYA
  - low moat if feature set is mostly tracking
  - usually weak on social proof and gym integrations
- **Takeaway:** there are plenty of “pretty solid climbing utility apps,” but they rarely escape utility status.

## 10) Future
- **URL:** https://future.co/
- **Pricing model:** premium recurring subscription with coaching. Precise current price not clearly exposed in fetched pages, but historically premium. Company messaging now emphasizes adaptive personalized plans and data-driven coaching.
- **What it does:** personalized training plans, coach interaction, adaptation to schedule/equipment, Apple Health and biometric data integration.
- **Tech approach:** increasingly **AI-supported coaching + human coach layer + data integrations**
- **Strengths:**
  - excellent product framing around personal adaptation
  - solves “what should I do today?” better than content businesses
  - human accountability remains a premium differentiator
- **Weaknesses:**
  - expensive
  - broad fitness means less domain depth than a category-specific product
  - scaling quality of coaching is operationally hard
- **Traction clues:** public funding reports indicate roughly **$110M** raised across rounds.
- **Takeaway:** Future shows that users will pay a lot when the product feels like a **real adaptive system**, not a workout library.

## 11) Tempo
- **URL:** https://tempo.fit/
- **Pricing model:** AI personal training at **$39/month**, with hardware bundles from roughly **$11+/month** or more depending on setup; marketed as low as **$50/month** bundled.
- **What it does:** AI-guided training, equipment integration, real-time feedback, progress tracking, body composition scanning, virtual coaching.
- **Tech approach:** **camera/computer-vision + connected hardware + subscription programming**
- **Strengths:**
  - product shows how real-time guidance feels more tangible when tied to equipment
  - clear monetization stack: software + hardware + coaching
  - body-scanning / progress metrics help justify subscription
- **Weaknesses:**
  - hardware burden narrows TAM
  - consumer smart-fitness market has been volatile and hype-prone
- **Takeaway:** proof that CV + connected environment can feel magical when the task is constrained. Climbing is less constrained, so UX must be more modest.

## 12) Tonal
- **URL:** https://tonal.com/
- **Pricing model:** premium hardware plus membership
- **What it does:** adaptive digital resistance, workout delivery, progress tracking, advanced lifting modes, household personalization
- **Tech approach:** **sensor-rich hardware + adaptive programming + software coaching**
- **Strengths:**
  - extremely strong perception of “smart strength training system”
  - clear feedback loop because resistance can be controlled automatically
  - the machine is both measurement and intervention
- **Weaknesses:**
  - hardware dependency
  - not portable, not low-cost
  - brittle if people churn after novelty wears off
- **Takeaway:** Tonal’s magic comes from owning the execution environment. For climbing, BK UP can partially replicate this by owning the gym environment and route data.

## 13) WHOOP / WHOOP Coach
- **URL:** https://www.whoop.com/us/en/membership/
- **Pricing model:** membership tiers; public page currently shows entry tier at **$149/year** promotional / **$199** list for WHOOP One, including personalized coaching and device.
- **What it does:** sleep, strain, recovery, heart-rate zones, coaching, broader health/performance insights.
- **Tech approach:** **wearable biometrics + coaching layer + analytics platform**
- **Strengths:**
  - always-on data capture
  - strong language around coaching and readiness
  - durable habit loop from daily health metrics
- **Weaknesses:**
  - domain-general, not climbing-specific
  - coaching is only as good as its ability to map generic metrics to actual training decisions
- **Takeaway:** WHOOP is a reminder that persistent data exhaust creates stickiness even when advice quality is imperfect.

---

## What current competitors leave open

The white space is not “training plans for climbers.” That is crowded enough.

The white space is:
- **climbing-specific persistent memory** across sessions, injuries, boards, routes, and goals,
- **video attached to structured session data**,
- **gym-native data integrations** (set catalog, route metadata, spray wall inventory, board inventory, setter tags),
- **a coaching engine that adapts weekly**, and
- **a UX that is visual and operational, not chat-centric**.

In other words: a climbing OS, not a climbing content library.

---

## 2. Video Analysis Technology: What Is Actually Possible Today

## Baseline pose-estimation stack

### MediaPipe / BlazePose
- 33 body landmarks
- real-time performance on modern mobile devices / web / desktop
- supports smoothing and segmentation
- optimized for live single-person tracking
- relatively practical for mobile-first productization

**What it is good at:**
- rough body positioning
- center of mass approximation
- identifying gross changes in posture
- joint-angle trends
- timing / phase segmentation
- drawing overlays users can understand

**What it is bad at:**
- precise contact inference on holds
- occluded limbs on overhangs
- subtle shoulder/hip rotations under twisting load
- nuanced grip recognition
- robust 3D understanding from random single-camera gym videos

### ML Kit Pose Detection
- also 33 landmarks
- practical on-device mobile implementation
- usable at real-time frame rates on modern phones
- includes z-ish coordinate estimates and confidence scores

This is suitable for lightweight mobile capture workflows, but not enough by itself for “elite climbing technique diagnosis.”

### OpenPose
- more expansive and flexible, including multi-person body/hand/face/foot keypoints
- still very useful for research/prototyping and desktop workflows
- heavier operationally than modern mobile-first stacks

OpenPose is better if you want more exhaustive keypoints or offline processing pipelines, but it is less obviously the pragmatic consumer mobile choice in 2026.

### MoveNet / TensorFlow ecosystem
- very practical for fast pose inference
- commonly used in applied sports-analysis demos and products
- useful for prototype pipelines and edge inference

---

## What pose estimation can do for climbing right now

### Feasible today
1. **Detect body landmarks over time** from a single climbing video.
2. **Segment an attempt into phases**:
   - setup / start
   - initiation
   - mid-sequence movement
   - crux hesitation/fall point
   - finish / top-out / drop-off
3. **Compute coarse features**:
   - hip distance from wall estimate (very rough)
   - left/right asymmetry
   - arm bend vs straight-arm usage patterns
   - stance width
   - cadence / pause timing
   - center-of-mass path smoothness
   - reach length and hip extension moments
   - lower-body engagement heuristics
4. **Generate visual overlays**:
   - skeleton
   - angle traces
   - highlighted pause moments
   - before/after comparison between attempts
5. **Compare attempts by same climber on same climb**:
   - fewer unnecessary readjustments
   - smoother timing
   - reduced “deadpoint panic” movements
   - better rest positioning

### Hard but plausible with domain labeling
1. **Classify broad movement patterns**:
   - cutting feet
   - flagging vs not flagging
   - high step attempt
   - hip turn / drop-knee-ish shapes
   - dynamic vs static execution
2. **Identify probable inefficiency clusters**:
   - overgripping / overpulling heuristics
   - too many hand readjustments
   - poor lower-body usage
   - low commitment through crux
3. **Create climb-style-aware feedback** if route metadata exists:
   - compression vs tension line
   - steep power vs slab balance
   - coordination move vs static sequence

### Still genuinely hard
1. **Reliable hold-contact detection** from ordinary user video.
2. **High-confidence foot placement analysis** on crowded walls.
3. **Understanding intent** (“you should have turned your hip earlier”) without route context.
4. **Generalizing across all gym lighting, camera angles, wall angles, and occlusions.**
5. **Automatically giving elite-level movement coaching** without a large labeled climbing dataset.

Climbing is a nasty CV domain because:
- limbs get occluded,
- walls are overhung,
- holds are cluttered and multi-colored,
- the camera angle is often terrible,
- technique depends on hold quality and route intent,
- and “correct” movement is highly context-sensitive.

Bruh, the computer can tell someone’s elbow angle. It cannot magically know whether the setter intended an inside flag to set up the next cross move unless you feed it much richer context.

---

## Relevant adjacent categories

## Golf swing analysis
Golf is the closest analog in one sense: there are relatively constrained movement phases and huge user willingness to film themselves.

Current AI golf products typically do:
- pose extraction from video,
- swing phase segmentation,
- comparison against pro/expert references,
- visual overlays,
- a few interpretable metrics,
- and simple coaching cues.

The lesson from golf is important: **the winning UX is not “open-ended AI insight.”** It is:
- capture,
- detect key moments,
- show overlays,
- produce 2-5 useful cues,
- let users compare over time.

## Running-form analysis
Running apps can estimate:
- cadence,
- stride symmetry,
- trunk lean,
- knee alignment,
- contact patterns.

This works because running has repetitive motion and a relatively stable viewpoint. Climbing is far more non-repetitive, so you should expect much lower confidence and narrower advice categories.

## Tennis / baseball / throwing apps
These tools often succeed when they:
- constrain camera placement,
- focus on one stroke/task,
- define a small set of metrics,
- and avoid pretending to understand the whole sport.

That is a big clue for climbing product design: **analyze specific scenarios, not all climbing in general.**

Examples of tractable early modules:
- overhang board climbing from fixed camera angles
- spray wall attempts at BK UP with known route geometry
- repeated attempts on same boulder
- start-position setup
- pacing and rest timing on longer circuits

---

## Research / domain-specific climbing CV opportunity

I did not find evidence that a dominant commercial climbing-CV stack already owns this category. That is good news and bad news.

Good news:
- open field
- chance to define the category
- little obvious incumbent on true video-coach UX

Bad news:
- likely because it is genuinely hard
- domain datasets are probably sparse and messy
- lots of product risk hiding inside model evaluation

The main unlock will likely require **BK UP-generated data** rather than generic public internet data:
- fixed camera positions in known gym zones
- route metadata linked to attempts
- opt-in user profiles and grade history
- repeated attempts across the same problems
- tagged feedback from setters/coaches

This is how you move from generic pose estimation to useful climbing coaching.

---

## What would it take to analyze a climbing video and give useful feedback?

## Minimal viable pipeline
1. User uploads or records video.
2. App asks for context:
   - indoor/outdoor
   - route/problem ID if known
   - grade
   - send / fall / flash / project
   - what feedback they want (technique / pacing / body positioning / route reading)
3. Pose model extracts landmarks.
4. Video pipeline identifies key frames and movement phases.
5. Optional wall/route metadata is attached.
6. Heuristic engine + LLM explanation layer generates:
   - 3-5 observations,
   - confidence labels,
   - annotated overlay frames,
   - one concrete drill or retry cue.

## Better pipeline
Add:
- hold map / route geometry,
- known wall angle,
- repeated attempts,
- user anthropometrics,
- prior session history,
- benchmark examples from similar climbers,
- optional coach/setter labels.

## Best-in-class but expensive pipeline
Add:
- fixed gym cameras,
- multi-view capture in key areas,
- route CAD / hold coordinates,
- custom fine-tuned models for hold interaction and movement classification,
- human-in-the-loop labeling,
- large structured training dataset.

The punchline: **useful feedback is possible before “solved climbing vision” exists**, but only if the product is disciplined about scope and confidence.

---

## 3. Product Spec: The Ideal AI Climbing Coach App

## Product thesis

### This is not “ChatGPT but for climbing”

A real product must have five things ChatGPT does not naturally have:

#### 1. Persistent athlete model
The system should remember:
- climbing history
- goals by horizon (4 weeks, season, year)
- current max and sustainable grade
- injury history and tissue sensitivity
- available equipment and facility access
- home wall / hangboard / board access
- time budget
- preferred disciplines (bouldering, sport, board, outdoor projecting)
- style profile (power, tension, compression, slab, coordination, etc.)
- fatigue/recovery signals

Without this, the app is just a clever answer box.

#### 2. Structured program engine
The app must generate and adapt actual training weeks, not merely give advice. That means:
- periodized blocks
- weekly plan generation
- session templates
- deload logic
- missed-session recovery logic
- injury-aware substitutions
- progression/regression rules

#### 3. Video analysis with visual output
Text advice alone is too abstract. The product must show:
- annotated clips
- body overlays
- freeze frames
- “compare attempt A vs B”
- cues tied to precise timestamps

#### 4. Environment integrations
The product gets much better when it knows the environment:
- BK UP route catalog
- setter tags / intended beta / style tags
- spray wall inventory and saved problems
- board inventory and angle setups
- class schedule / gym events / training blocks

#### 5. Compounding dataset and lock-in
Every session should make the system better for the user:
- sends/logs/videos over time
- benchmark trends
- repeat attempts
- route-type performance
- injury and workload patterns
- community clips from similar climbers

That accumulated context is what a general LLM does not have.

---

## Product principles

1. **Serious, not gamified.**
2. **Visual before verbal.**
3. **Structured before conversational.**
4. **Useful under uncertainty.** Never fake confidence.
5. **Gym-native.** The best version is integrated with a real physical climbing environment.
6. **Respect the craft.** The product should feel like a training notebook built by killers, not a dopamine slot machine.

---

## Core user jobs to be done

### Serious intermediate climber
“Tell me what to do this week, help me see why I keep failing on this style, and show me if I’m actually improving.”

### Ambitious gym member
“Turn my random sessions into a coherent practice.”

### Returning climber / injury-managed climber
“Keep me training intelligently without doing dumb macho nonsense.”

### Coach / setter / gym operator
“Help members train with intention and engage more deeply with our routes and boards.”

---

## Core product modules

## A. Athlete Profile
Fields:
- height, wingspan, bodyweight optional
- training age
- years climbing
- indoor vs outdoor split
- current max / flash / project levels
- preferred terrain
- injury history
- risk flags (A2 tweaks, elbows, shoulders)
- available gear/facilities
- weekly time budget
- target goals

Derived fields:
- experience band
- workload tolerance estimate
- style strengths/weaknesses
- recovery sensitivity
- plan compliance score

## B. Adaptive Training Plan Engine
Outputs:
- 4-8 week block
- weekly plan
- today’s session
- substitutions if equipment/time changes
- auto-adjustments after missed sessions
- taper / project-week modes

Rules:
- maintain session intent even when exercise changes
- never stack high finger load recklessly
- adapt around soreness/injury flags
- bias toward consistency over perfect adherence

## C. Session Logging
Log types:
- climbing session
- board session
- hangboard / finger strength
- strength & conditioning
- mobility / prehab
- outdoor projecting day
- rehab block

Inputs:
- perceived exertion
- grade spread
- number of attempts
- route/problem IDs
- successes/fails
- video attachments
- notes
- skin / finger / elbow status

## D. Video Analysis
Modes:
1. **Quick Attempt Review** — upload one clip, get timestamped observations.
2. **Attempt Comparison** — compare two burns on same problem.
3. **Progress Review** — compare clips over weeks/months.
4. **Coach Review Queue** — optional human overlay later.

Outputs:
- keyframes with overlays
- likely inefficiency tags
- confidence-rated cues
- one retry experiment
- related drill or practice focus

## E. Gym Integration Layer
For BK UP:
- route catalog
- style tags per problem
- wall angle / zone
- setter notes / intended movement ideas
- new set notifications
- spray wall saved circuits/problems
- board inventory and benchmark links

This is huge. It lets the product connect performance to terrain rather than giving generic advice.

## F. Progress Dashboard
Views:
- training consistency
- grade trends by style
- board performance
- projected readiness
- injury risk / load trend
- technique trend snapshots
- route-type weaknesses

## G. Community / Social Layer
Not generic social feed brain rot. Focused utility only:
- beta clips tied to actual climbs
- compare with climbers of similar size/style/grade
- gym cohorts / training groups
- setter’s notes
- coach comments
- “show me how 5 people of similar morphology did this move”

This is where network effects can become real.

---

## Phased roadmap

## MVP (4–6 weeks)

### Goal
Ship a credible product that proves climbers want a structured coaching workflow from BK UP / standalone web app.

### Scope
- onboarding + athlete profile
- goal setting
- weekly plan generator
- daily session cards
- manual session logging
- video upload for simple review
- lightweight annotated feedback using off-the-shelf pose estimation + heuristics + LLM explanation
- basic progress dashboard
- BK UP-specific route logging if route data is accessible

### What the MVP should *not* try to do
- real-time live coaching during climbs
- elite-grade movement diagnosis
- automated hold detection at scale
- broad social feed
- complex wearable integrations
- perfect periodization science

### MVP success criteria
- users complete onboarding
- at least 3 sessions logged in first 2 weeks
- video review gets repeated use
- users say “this actually helps me structure training”
- BK UP members engage more with route catalog / spray wall / board

### Best MVP wedge
A surprisingly strong MVP could be:
- **profile + adaptive weekly plan + route/session log + attempt comparison video review**

That is enough to feel product-y without overpromising frontier CV.

---

## V1 (3 months)

### Additions
- richer plan adaptation based on compliance and soreness
- route-style taxonomy
- BK UP route database integration
- board session import/logging
- benchmark testing protocols
- coach dashboard / optional human review
- compare against similar climbers
- drill library linked to detected issues
- better progress dashboards
- push notifications tied to actual plan state, not generic engagement spam

### V1 outcome
The product starts feeling like a **true climbing training operating system**.

---

## V2 (6 months)

### Moat features
- fixed-camera gym zones for higher-quality analysis
- spray wall / route geometry integration
- route-aware movement analysis
- personalized benchmark models by morphology + style
- BK UP member cohorts and internal leaderboards that are actually meaningful
- human+AI coaching marketplace / upsell
- auto-generated “next best session” and “project readiness” scoring
- aggregated anonymous style-difficulty insights from BK UP route data
- API / white-label gym platform for other climbing gyms

### V2 outcome
This becomes hard to copy because the moat is now:
- proprietary gym data
- proprietary labeled attempt/video data
- structured athlete histories
- community clips + route context
- gym distribution

---

## UI/UX concepts

## Principle: the app should feel like a cockpit, not a chatbot

Chat can exist, but should be subordinate. The primary UX should be:
- dashboards
- cards
- timelines
- overlays
- comparisons
- structured flows

If the main experience is a text box, the product will feel generic and low-trust.

## Main screens

### 1. Home / Today
Shows:
- today’s recommended session
- readiness / fatigue check-in
- recent progress snapshot
- quick actions: Log Session, Review Attempt, View Week

Why it matters:
- removes planning overhead
- makes the product operational, not inspirational

### 2. Week Plan / Calendar
Shows:
- training block
- scheduled sessions
- completed vs missed
- substitutions if time/equipment changes
- load balance across the week

Why it matters:
- climbers need to see tradeoffs across the week
- a calendar makes coaching tangible

### 3. Session Logger
Should be highly visual and fast.
Inputs might include:
- terrain / facility / board
- route/problem picks
- success/failure
- number of attempts
- notes
- pain/soreness sliders
- video attachments

The logger should feel closer to **Strong / Strava / Whoop logging discipline** than a diary.

### 4. Video Review Screen
This is a flagship differentiator.

Workflow:
- upload clip
- choose climb / route / attempt type
- choose feedback mode
- app processes and returns:
  - scrubber timeline
  - highlighted timestamps
  - overlay frames
  - side-by-side attempt compare
  - concise observations with confidence labels
  - suggested retry cue / drill

This is fundamentally different from an LLM chat because the user is interacting with **their own media and structured analysis**, not asking generic questions.

### 5. Progress Dashboard
Should emphasize:
- compliance trend
- grade trend by style
- board benchmarks
- finger load and recovery
- identified technical patterns over time
- “what changed?” summaries

### 6. Route / Gym Screen (BK UP mode)
Shows:
- current sets
- route style tags
- save to session plan
- see beta clips
- compare with similar climbers
- setter notes / purpose of problem

This is a monster differentiator if BK UP owns the route metadata.

### 7. Technique Library / Drill Index
Organized by:
- movement issue
- terrain/style
- body awareness cue
- drill progression

Should feel like a serious reference library, not TikTok tips.

---

## Example UX loop

1. User opens app Monday.
2. App says: today is power-endurance board session + shoulder prehab, adjusted because you skipped Friday.
3. User does session, logs Kilter and two gym circuits.
4. Uploads a failed project clip.
5. App highlights two long pauses and a hip-square position before fall.
6. It suggests: “On next attempt, commit earlier to right hip turn and reduce extra hand readjustment before move 5.”
7. It links one drill and rewrites Wednesday technique focus.

That feels like a product. Not a bot.

---

## Tech stack recommendations

## Platform strategy

### Short answer
- **Start with mobile-first app + web admin/backoffice**
- If resources are tight: **React Native / Expo for consumer app, web dashboard for coaches/admin/gym ops**

### Why not web-only?
For a consumer climbing product, mobile matters because:
- logging happens in the gym
- video capture/upload happens on phone
- board/gym use is mobile-native
- notifications and habit loops matter

### Why still build web?
- coach tools
- route/gym management
- analytics
- internal labeling tools
- faster backoffice operations

## Suggested stack

### Frontend
- **React Native / Expo** for iOS + Android
- **Next.js** for web admin / landing / coach tools

### Backend
- **Postgres** for structured user / session / route / plan data
- **Supabase** or standard Postgres + auth/storage if moving fast
- object storage for videos (S3 or Supabase Storage)
- background jobs for video processing and plan generation

### AI / ML layers
1. **LLM layer**
   - for explanation, summarization, plan writing, coach tone, adaptive reasoning
   - never the source of truth for biomechanics or load calculations
2. **Rules engine**
   - for training safety, plan adaptation, progression logic
3. **Pose-estimation pipeline**
   - MediaPipe / MoveNet / ML Kit for MVP
   - server-side deeper processing optional
4. **Feature extraction layer**
   - landmarks → movement features / timestamps / heuristics
5. **Retrieval / domain memory layer**
   - athlete profile, past sessions, route data, drills, benchmark examples

### Data model essentials
- users
- goals
- injuries / risk flags
- facilities / equipment
- training blocks
- planned sessions
- completed sessions
- routes/problems
- attempts
- videos
- extracted video features
- drills / content atoms
- gym metadata
- coach annotations

### Estimated complexity

#### Easy-ish
- onboarding
- logging
- weekly plan generator
- dashboards
- drill library

#### Medium
- adaptive programming engine
- BK UP route integration
- board logging import / mapping
- confidence-rated feedback system

#### Hard
- robust climbing video analysis
- route-aware coaching
- hold-level CV
- generalized feedback from arbitrary phone videos
- cross-gym data normalization

The hard part is not “calling an LLM.” It’s building a trustworthy system where structured data and video actually improve recommendations.

---

## Business model

## Consumer pricing idea

### Free
- profile
- limited session logging
- limited plan preview
- 1-2 video reviews per month
- BK UP route browser if member

### Plus: $19–29/month
- full logging
- adaptive weekly plans
- full progress dashboard
- more video reviews
- drill library
- board / benchmark tracking

### Pro / Coach: $49–99/month
- advanced analytics
- more video reviews
- compare mode
- coach review queue
- premium planning modes
- maybe monthly human coach check-in

### BK UP member bundle
Several options:
1. **Included basic tier** with gym membership, upsell to premium.
2. **Discounted premium** for members.
3. **Board / spray wall / route integration as members-only advantage.**

My instinct: include enough with membership that it feels like BK UP has a real training system, then upsell deeper coaching/video features.

## Gym-side monetization
Longer-term, the bigger business may be B2B2C:
- license to gyms
- route catalog + member coaching layer
- setter analytics
- benchmark / community features
- white-label or co-branded deployment

That could become much more durable than a pure consumer app.

## Revenue path
1. BK UP internal proof-of-concept and distribution channel
2. premium BK UP member upsells
3. standalone consumer subscriptions
4. human coaching / premium review upsells
5. gym SaaS / licensing

This fits Tyler’s background well: start niche, own the workflow, then expand from a real wedge instead of chasing VC-fueled fitness fantasyland.

---

## Moat / differentiation

## What ChatGPT cannot easily replicate

A user can ask ChatGPT for climbing advice today. That is not a business.

What ChatGPT cannot replicate without the product is:
- long-lived athlete memory tied to training data
- session logs and load history
- structured weekly planning engine
- attached video overlays and comparisons
- gym-specific route metadata
- community benchmark clips from similar climbers
- board and route performance histories
- trust built from repeated interaction with a constrained domain model

## Defensible moats

### 1. Data moat
Over time you accumulate:
- user histories
- attempt libraries
- labeled movement issues
- route-style metadata
- board outcomes
- recovery/compliance patterns

### 2. Gym integration moat
If BK UP data model is embedded in the product:
- route catalog
- setter tags
- spray wall geometry
- member history on problems
- internal video corpus

Then a generic AI cannot just copy-paste that.

### 3. Community moat
Not all social is equal. The highest-value social layer is:
- beta from similar climbers
- route-linked video examples
- setter intent notes
- team / crew accountability

### 4. Workflow moat
If users rely on the app for:
- deciding what to do today,
- logging what happened,
- reviewing attempts,
- and measuring progress,
then the product becomes infrastructure.

### 5. Philosophy moat
If the product feels like it truly respects climbing as a craft, it can attract serious users alienated by generic gamified fitness UX.

---

## 4. Tyler’s “Neoclassical” Angle

This is more important than it sounds. The product should not feel like a Silicon Valley toy sprayed onto climbing.

## What “neoclassical climbing” should mean in software

### 1. Respect for skill over spectacle
The app should prioritize:
- movement quality
- session intention
- progression through practice
- honest feedback
- craft and discipline

Not:
- empty streaks
- fake badges everywhere
- “AI coach says you crushed it king 🔥” nonsense

### 2. Understated, high-trust design
The UI should feel:
- clean
- quiet
- editorial
- technical but human
- more field notebook / training log than gamified wellness app

Think:
- monochrome with selective accent color
- strong typography
- route diagrams and overlays
- dense but elegant information

### 3. Serious language
Tone should be:
- direct
- precise
- encouraging without hype
- transparent about confidence and uncertainty

Example:
- Good: “You paused twice before committing to the crux move; compare hip position at 0:14 and 0:17.”
- Bad: “Your AI coach noticed room for optimization! Let’s unlock your climbing potential 🚀”

Kill it with fire.

### 4. Training over engagement theater
Every feature should answer one question: does this help someone become a better climber?

If not, it probably does not belong.

### 5. Human judgment remains honorable
The product should leave room for:
- coach input
- setter notes
- personal reflection
- disagreement with the machine

A neoclassical product should not pretend the algorithm is a guru.

---

## Strategic recommendation

If I were shaping this as a founder, I would frame it as:

> **A serious climbing training system that combines adaptive programming, gym-native logging, and practical video review.**

Not:
- AI climbing companion
- Chat coach for climbers
- social fitness app
- generic climbing tracker

## Best initial wedge

For BK UP + standalone product validation, the sharpest first version is probably:

### “Plan + Log + Review”
- adaptive weekly plan
- dead-simple session logging
- route-aware BK UP integration
- attempt video review with overlays and timestamped cues

Why this wedge works:
- immediately useful
- differentiated enough
- feasible with today’s tech
- compounds data fast
- aligned with BK UP brand

## What to delay
- fully autonomous technique diagnosis
- real-time live coaching on wall
- sprawling social feed
- general outdoor route-guide ambitions
- hardware-heavy moonshot features too early

## Product risk to watch carefully

The biggest risk is false magic: promising AI technique analysis beyond what the system can reliably do. The correct posture is:
- modest claims,
- constrained use cases,
- obvious visual evidence,
- confidence labels,
- and a humanly plausible training model.

Done right, that builds trust.
Done wrong, it becomes climbing astrology with prettier UI.

---

## Bottom line

There is a real company here if the product is built around:
- persistent athlete context,
- structured training logic,
- practical video overlays,
- BK UP environment data,
- and a craft-respecting product philosophy.

The opportunity is strongest if it starts as **the software embodiment of BK UP’s philosophy** and only later expands outward.

That creates a product with a point of view, a data advantage, and a believable moat.

Not just “LLM wrapper, but make it crimpy.”
