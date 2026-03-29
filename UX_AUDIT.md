# Crux Coach UX Audit — 2026-03-28

## Critical Issues

### 1. Landing Page Not Showing for Signed-Out Users
The landing page (pages#home) should show for unauthenticated users but sign-out via GET doesn't work (Devise requires DELETE). The landing page marketing content needs to be visible.
**Fix:** Ensure sign-out uses DELETE method. Also verify the landing page actually renders for unauthenticated users.

### 2. No Visual Distinction for Today in Week Calendar
The "This Week" calendar strip on the dashboard doesn't highlight today's date. Users can't tell at a glance what day it is.
**Fix:** Add amber accent/ring to today's date card.

### 3. Week Calendar Doesn't Show Session Info
The week calendar just shows day names and numbers. It should show what type of session is planned for each day (icons or colored dots).
**Fix:** Show session type indicators (colored dots or small labels) under each day.

### 4. Form Inputs Lack Focus States
Input fields on onboarding, session logging, and profile forms don't have visible focus rings. Hard to tell which field is active, especially on mobile.
**Fix:** Add `focus:ring-2 focus:ring-amber-500 focus:border-amber-500` to all form inputs.

### 5. No Placeholder Text in Key Inputs
Grade fields, goal textareas, etc. lack helpful placeholder text. Users don't know what format to use for grades.
**Fix:** Add placeholders like "V5", "5.11c", "Send my first V7 by June" etc.

### 6. CTA Buttons Need Hover/Active States
The amber CTA buttons lack hover and active feedback.
**Fix:** Add `hover:bg-amber-400 active:bg-amber-600 transition` to all CTA buttons.

### 7. Session Log Save Button Too Easy to Hit Before Parsing
On the session log page, "Save" is right next to "Parse Session." A user could accidentally save a blank NLP session without parsing first.
**Fix:** Disable Save button when using NLP tab until either parsing is done or raw_input is filled.

## UX Improvements

### 8. Onboarding — Add Skip/Optional Indicators  
Not all fields are required but nothing tells the user what's optional. They might abandon if they think they need everything.
**Fix:** Add "(optional)" labels to non-required fields like height, weight, wingspan.

### 9. Dashboard — Today's Session Card Should Be More Prominent
When there IS a planned session, the card should feel more actionable — bigger, with a clear "Start Session" or "View Details" CTA.
**Fix:** Make the today session card more visually prominent with larger text and a clear action button.

### 10. Dashboard — Show Greeting + Context
The dashboard jumps straight to "Today" with no personal touch. A simple "Good evening, Tyler" with the date would add warmth.
**Fix:** Add time-of-day greeting + date at top of dashboard.

### 11. Weekly Plan — Sessions Should Be Expandable Without Page Nav
Currently clicking "View details" on a session tries to navigate. Should expand inline.
**Fix:** Use Turbo Frames to expand session details inline without page navigation.

### 12. Coach Cards Need Better Visual Hierarchy  
The coach directory cards are text-heavy. Specialties and grades should be easier to scan.
**Fix:** Use badge/pill styling for specialties, cleaner grade display.

### 13. Profile Page — Read-Only View Is Sparse
The profile show page is just text. Should feel more designed — maybe similar card layout to the onboarding review step.
**Fix:** Match the style of onboarding step 6 review cards.

### 14. Progress Page — Empty State Is Minimal
Just says "No data yet." Should encourage the user and suggest actions.
**Fix:** Add illustration/icon, suggest logging first session, link to session log.

### 15. Mobile Nav — Hamburger Menu Needs Better Hit Target
The ☰ hamburger is just a text character. Hard to tap on mobile.
**Fix:** Make it a proper 44x44px tap target with padding.

### 16. Admin Pages Need Nav Links
Admin pages (plans, AI usage) aren't linked from the main nav for admin users.
**Fix:** Add admin section to sidebar when user.admin?.

### 17. Form Checkbox Styling
Checkboxes on equipment/style selection are browser-default. Should match the dark theme.
**Fix:** Style with Tailwind forms plugin or custom checkbox styling.

### 18. Onboarding Step 4 (Injuries) — Empty State
If a user has no injuries, showing one empty injury form card is confusing. Should start empty with just "Add an injury" button.
**Fix:** Start with no injury cards, just the "Add an injury" button.

### 19. Session Log History — Needs Better Empty State
The /logs page with no sessions should encourage logging.
**Fix:** Better empty state with illustration and CTA.

### 20. Overall Typography Consistency
Some headings use text-2xl, some text-lg. Section spacing varies. Needs a consistent rhythm.
**Fix:** Standardize heading sizes: page title = text-2xl, section title = text-lg, card title = text-base font-semibold.

### 21. Loading States for AI Operations
Plan generation takes ~40 seconds. Need better loading UX than just "Generating..."
**Fix:** Add a proper loading spinner/skeleton, progress indicator, and estimated time ("This usually takes 30-60 seconds").

### 22. Mobile — Sign Out Should Be in a Better Location
On mobile, sign out is in the top bar which gets crowded. Should be in the sidebar nav or behind a menu.
**Fix:** Move sign out to bottom of mobile sidebar nav.
