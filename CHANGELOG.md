## v1.0.15.1
- Filters moved into a compact modal overlay from Map and Activities
- Same activity discovery filters preserved with local persistence
- Cleaner top-right header access to filters without occupying screen space

## v1.0.15.0
- Activity discovery filters for today, time of day, category and group size
- Filters apply to both the activities list and the map markers
- Local filter state persists across restarts with a clean empty state when nothing matches

## v1.0.14.0
- Profile onboarding after first login in mock/local mode
- Required onboarding for name, avatar and at least one interest before entering the app
- Profile setup saves locally and still allows later editing from Perfil

## v1.0.13.0
- Editable profile screen in mock/local mode
- Local profile changes persist across restarts
- Profile card now opens edit profile with compact chip-based controls

## v1.0.12.0
- Settings screen simplified and polished for local/mock mode
- Account, preferences and data sections now match the current product state
- Clear local data and sign out remain available with the same behavior

## v1.0.11.2
- Fixed profile encoding fallback after local wipe and relogin
- Sanitized restored profile fields to avoid mojibake in avatar, phone and bio
- Added safe defaults for profile header display text

## v1.0.11.1
- Fixed local data wipe so seed data does not come back after clearing
- Empty states remain empty after logging in again post-wipe
- Added persistent mock seed disabled flag with deterministic wipe logs

## v1.0.11.0
- Consistent beautiful empty states across the app
- No activities, chats, saved, history, feedback and map states now feel intentional
- Shared empty state component with soft CTA where useful

## v1.0.10.0
- Visual cleanup to remove white and gray glow effects
- Darker shared card surfaces across the app
- Profile, feedback, report and auth cards aligned to the night palette

## v1.0.9.0
- Settings screen in mock/local mode
- Local notification and privacy toggles
- Clear local data action with confirmation

## v1.0.8.0
- Saved activities and favorites in local mock mode
- Save toggle from activity detail and map preview
- Guardadas screen with local persistence

## v1.0.7.1
- Profile subpages reuse a consistent back button style
- Mis actividades now returns cleanly to Perfil

## v1.0.7.0
- Mock local reports for activities, users and messages
- Report screen with private moderation reasons
- Duplicate report prevention per target

## v1.0.6.2
- Activities list opens chat directly when already joined or confirmed
- Activities list gets safer bottom padding above the dock
- No extra summary screen when the list already has enough context

## v1.0.6.1
- Creator auto-joins and auto-confirms when creating an activity
- History screen adds a matching back button
- Creator counters stay consistent with activity deletion

## v1.0.6.0
- Activity lifecycle with open, ongoing, finished and archived states
- Creator actions to start and finish activities
- Finished activities move to history and chats become read-only
- Profile now separates active activities from history

## v1.0.5.4
- Final map FAB positioning above the dock
- FAB hidden while the activity preview card is open
- Mint create button kept larger and aligned to the right

## v1.0.5.3
- Map create activity FAB is larger and closer to the dock
- Profile visuals cleaned up to flow directly into actions
- Activity history data remains intact

## v1.0.5.2
- Mint create activity button on the map
- Cleaner compact private feedback cards
- Polished private profile stats

## v1.0.5.1
- Private feedback now shows all confirmed attendees except the current user
- Profile no longer shows feedback metrics
- Private kawaii feedback stays local and private

## v1.0.4
- Activity deletion from chat menu
- One active created activity per user
- Stable local mock persistence

## v1.0.5
- Private kawaii feedback
- Local persistence for private feedback
- Private internal profile stats
