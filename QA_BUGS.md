# Crux Coach QA Bug Report — E2E Smoke Test
**Date:** April 1, 2026
**Tester:** Burt (automated QA via browser)
**Environment:** Production — https://train.bkup.nyc
**Test Account:** burt@cruxcoach.dev

---

## Critical Bugs

### BUG-001: 502 Bad Gateway during initial plan generation (onboarding)
- **Description:** After completing onboarding Step 6 and clicking "Generate My First Plan", the server returns a 502 Bad Gateway error from Cloudflare. The plan actually generates successfully in the background, but the user sees a crash page and has to manually navigate to /dashboard.
- **Page/URL:** https://train.bkup.nyc/onboarding/6
- **Console Error:** `Failed to load resource: the server responded with a status of 502 ()`
- **Impact:** New users will think the app crashed and may abandon. The plan does generate, but the UX is broken.
- **Severity:** CRITICAL
- **Notes:** Likely a timeout issue — the generation request takes 30-60 seconds, and either Cloudflare or the reverse proxy (Caddy/Coolify) times out before the response completes. Need to either: (a) make generation async with polling, or (b) increase proxy timeout.

### BUG-002: Stimulus controller error — `saveSet` method undefined
- **Description:** Every exercise checkbox click on the session detail page throws: `Error invoking action "change->exercise-log#saveSet" - references undefined method "saveSet"`. This fires for EVERY checkbox interaction. The Stimulus controller `exercise-log` references a `saveSet` action that doesn't exist.
- **Page/URL:** https://train.bkup.nyc/plan/6/session/22 (and /24, etc.)
- **Console Error:** `Error: Action "change->exercise-log#saveSet" references undefined method "saveSet"` (fired 20+ times)
- **Impact:** Individual set completions may not be persisting via AJAX. The session still saves on "Complete Session" click, but live-saving of checkbox state appears broken.
- **Severity:** CRITICAL
- **Notes:** The `exercise_log_controller.js` Stimulus controller needs a `saveSet()` method added, or the action binding in the view template needs to be updated to match the actual method name.

---

## High Severity Bugs

### BUG-003: Benchmarks page returns 404
- **Description:** Navigating to /benchmarks returns a Rails 404 page. There is no benchmarks feature accessible anywhere in the app — not in the nav, not on the profile page, not as a standalone route.
- **Page/URL:** https://train.bkup.nyc/benchmarks
- **Impact:** The benchmarks feature (max weighted hang, max pullups, indoor boulder max, bodyweight) cannot be tested. This is a planned feature that hasn't been deployed.
- **Severity:** HIGH (feature missing entirely)

### BUG-004: Natural language session logging feature missing
- **Description:** Routes /sessions, /sessions/new both return 404. The "Fast Logging" feature advertised on the landing page ("Natural language capture or manual detail for every session") doesn't exist. Session logging is only possible through the plan session detail page (checkbox-based).
- **Page/URL:** https://train.bkup.nyc/sessions/new, https://train.bkup.nyc/sessions
- **Impact:** Users who want to log ad-hoc sessions (not tied to a specific planned session) have no way to do so. The landing page promises natural language logging that doesn't exist.
- **Severity:** HIGH (advertised feature missing)

### BUG-005: Exercise completion count is wrong on weekly plan
- **Description:** Completed sessions show incorrect exercise counts: "11/4 exercises done" and "14/4 exercises done". The numerator counts total checked items (including individual sets), but the denominator only counts exercise groups. Should be consistent — either count exercises (7/7) or count all items including sets (7/7 or 10/10).
- **Page/URL:** https://train.bkup.nyc/plan (weekly view)
- **Impact:** Confusing data display — "11/4" suggests more items were done than existed.
- **Severity:** HIGH

### BUG-006: Training Block week number shows dash instead of number
- **Description:** On the dashboard, the Training Block card shows "Week - of 4" instead of "Week 1 of 4" (or the appropriate week number). The week number is missing/null.
- **Page/URL:** https://train.bkup.nyc/dashboard
- **Impact:** Users can't tell which week of their training block they're in.
- **Severity:** HIGH

---

## Medium Severity Bugs

### BUG-007: favicon.ico returns 404
- **Description:** The favicon is missing, causing a 404 error on every page load.
- **Page/URL:** https://train.bkup.nyc/favicon.ico
- **Console Error:** `Failed to load resource: the server responded with a status of 404 ()`
- **Severity:** MEDIUM
- **Notes:** Easy fix — add a favicon.

### BUG-008: Coaches page is empty with no useful empty state
- **Description:** The Coaches page shows "Browse available coaches and specialties." with nothing below it. No empty state message, no "coming soon", no CTA to learn more.
- **Page/URL:** https://train.bkup.nyc/coaches
- **Impact:** Users clicking "Coaches" in the nav see a blank page with no explanation.
- **Severity:** MEDIUM

### BUG-009: Grade History shows dashes in Progress page
- **Description:** The Grade History section on the Progress page shows "Apr 01 -" for both completed sessions. No grade data is captured, despite the sessions involving climbing at specific grades.
- **Page/URL:** https://train.bkup.nyc/progress
- **Impact:** Grade progression tracking doesn't work because the session logging flow doesn't capture grade data.
- **Severity:** MEDIUM

### BUG-010: Empty injury form shows on Profile Edit page even when no injuries exist
- **Description:** The profile edit page shows an empty injury form (Area, Severity, Notes fields) with a "Remove" link, even though the user never added any injuries during onboarding.
- **Page/URL:** https://train.bkup.nyc/profile/edit
- **Impact:** Minor confusion — user might think they need to fill in injury data.
- **Severity:** MEDIUM

---

## Low Severity / UX Observations

### OBS-001: No way to select specific training days
- **Description:** Onboarding Step 3 only asks for "Training days per week" (a number) but doesn't let you pick WHICH days (e.g., Mon/Wed/Fri/Sat). The additional context textarea is the only workaround.
- **Page/URL:** https://train.bkup.nyc/onboarding/3
- **Severity:** LOW (UX improvement)

### OBS-002: "Watch demo" links point to generic exercises
- **Description:** The "Watch demo" links on session exercises point to library entries that may not exactly match the prescribed exercise. E.g., "Power intervals" on the Kilter Board session links to "aerobic-endurance-intervals" in the library.
- **Page/URL:** Session detail pages
- **Severity:** LOW (content accuracy)

### OBS-003: Session dates on dashboard all show "Apr 01"
- **Description:** Both logged sessions (Monday hangboard and Wednesday board) show "Apr 01, 2026" as the date on the dashboard's Recent Sessions. The Monday session should show Mar 30.
- **Page/URL:** https://train.bkup.nyc/dashboard
- **Severity:** LOW (sessions were logged on Apr 01 so this may be correct behavior — showing log date vs. planned date)

### OBS-004: No calendar view exists
- **Description:** There is no dedicated calendar view of the training plan. The Plan page shows a weekly list view, but no month/calendar grid view. This was referenced in the test plan but doesn't exist in the app.
- **Severity:** LOW (feature not yet built)

### OBS-005: No training blocks list/management page
- **Description:** There's no page to view all training blocks, create new ones, or manage existing blocks. The only training block was auto-generated during onboarding. The "Generate Next Week" button on the Plan page is the only way to extend the plan.
- **Severity:** LOW (feature not yet built)

### OBS-006: Onboarding defaults could be smarter
- **Description:** Step 1 pre-fills Years climbing: 4, Training age: 18, Height: 70, etc. These seem arbitrary. Consider either leaving them blank or making them more sensible defaults.
- **Severity:** LOW

---

## Summary

### What Worked Well ✅
1. **Landing page** — Clean, professional, clear value prop
2. **Signup flow** — Smooth, fast, no issues
3. **Onboarding wizard** — 6-step flow is well-structured, all data saves correctly
4. **Plan generation** — AI generates excellent, detailed weekly plans with appropriate exercise variety
5. **Session detail pages** — Comprehensive exercise prescriptions with sets, reps, rest times, YouTube demo links
6. **Exercise library** — Extensive, well-organized with video demos and tags
7. **Session timer** — Works correctly, tracks duration
8. **Session completion flow** — Checkbox-based logging works (despite console errors)
9. **Progress page** — Shows sessions per week chart and volume trends
10. **Profile edit** — All fields persist correctly
11. **Dark theme UI** — Consistent, polished, climbing-appropriate aesthetic

### What's Broken/Missing 🚨
1. **502 crash on first plan generation** — Critical UX break for new users
2. **Stimulus saveSet method undefined** — Console error on every checkbox click
3. **Benchmarks feature** — 404, not deployed
4. **Natural language session logging** — 404, not deployed
5. **Exercise count display bug** — Shows wrong numbers (11/4, 14/4)
6. **Week number missing** — Dashboard shows "Week - of 4"
7. **No calendar view, no training blocks management, no standalone session logging**

### Overall Assessment
The core loop (signup → onboard → generate plan → view sessions → log sessions) **works end-to-end** despite the 502 hiccup. The AI-generated training plans are impressive and the exercise library is well-curated. The main issues are: (1) the 502 timeout on generation needs an async fix, (2) several planned features (benchmarks, NL logging, calendar) aren't deployed yet, and (3) the Stimulus controller error needs fixing. The app is in solid MVP shape for the core planning/logging workflow.
