## v1.0.26.1
- Added soft moderation warnings before saving risky activities or sending risky chat messages
- Users can choose to edit or continue, and continuing still creates the internal moderation flag
- The warning flow stays local, private, and non-blocking

## v1.0.26.3
- Added a user-facing safety center in Configuración with blocked users, reporting guidance, tips, and emergency guidance
- Added a moderation flag detail screen with activity and chat context for internal review
- Flags can now be opened from the internal moderation list to inspect surrounding message history or activity text
- Review actions remain local and private, with no backend changes

## v1.0.26.2
- Added a one-time soft conduct reminder before opening an activity chat for the first time
- The reminder is stored locally per activity and only appears once after the user accepts it
- Cleaned up development logs so only the most useful YNOT tags remain in console output
- Moderation flag creation now emits one clear log when a risky keyword is detected
- Added README guidance for filtering YNOT logs in Windows CMD and PowerShell

## v1.0.26.0
- Added local moderation flags for risky keywords found in activity text and chat messages
- Created a private mock-only moderation screen in Configuración for reviewing pending flags
- Moderation flags stay internal, persist locally, and can be marked reviewed or dismissed

## v1.0.25.1
- Main screens now share a compact header with icons only for search, filters and notifications
- Notification access moved into the main header on Mapa, Actividades and Chats for quicker access
- The notifications bell now stays consistent and keeps the unread badge visible across the app

## v1.0.25.0
- Added a local in-app notifications center with unread badge, read state, and persistence after restart
- Notifications now cover chat messages, upcoming activities, attendance changes, activity completion, and feedback availability
- The notifications screen stays private to the current user and respects existing local settings
- Settings now include a local demo generator so notifications can be tested manually without real triggers

## v1.0.24.0
- Activities now keep an exact internal location plus a stable approximate public location for privacy
- Public map and detail views only reveal exact location when allowed by role and timing rules
- Approximate markers stay stable per activity and the UI now shows whether a location is approximate or exact

## v1.0.23.0
- Added a chat participant selector so reports can target organizers, attendees, and chat participants instead of only the organizer
- The report flow now opens the existing report screen for the selected user
- Report history remains hidden from users

## v1.0.22.2
- Removed the user-facing sent reports history screen from settings
- Reports remain internal moderation data and still submit normally
- After sending a report, the app now shows a simple private confirmation message

## v1.0.22.0
- Added a private local screen to review sent reports from Perfil > Configuración
- Each report now shows the target, reason, note, date and local send status
- Users can optionally clear their local report history with confirmation

## v1.0.21.0
- Settings screen now groups account, local data, security and about sections clearly
- Edit profile, blocked users, demo loading and local wipe actions are easier to reach
- Reports stay private and the screen now shows current version and mock/local mode

## v1.0.20.3
- Feedback now shows blocked users for context but disables their rating buttons
- The save feedback flow ignores blocked users and explains when no eligible people remain
- Blocked feedback attempts are rejected in the controller for safety

## v1.0.20.2
- Activity attendee cards were compacted to prevent overflow and keep blocked badges inside the card
- Chat attendee avatars now use icon-only visuals so the header stays clean and readable
- Demo activity strings were sanitized so seeded content keeps proper accents and emoji

## v1.0.20.1
- Blocked users stay visible, but attendee chips now show a compact safety badge
- Chats with blocked participants now warn once per chat unless the user dismisses them permanently
- Blocked messages remain hidden by default with a subtle reveal action

## v1.0.20.0
- Users can now block other users from public profiles or report flows
- Blocked users stay visible in attendee lists and chats, but are marked for safety
- Reporting a user can optionally offer a block confirmation
- A new settings screen lists blocked users and allows unblocking them

## v1.0.19.0
- Public user profiles are now available from activity detail and chat avatars/names
- Profiles show avatar, bio, languages, vibes and interests without exposing private data
- Demo users now have local public profile data so profile taps feel complete in mock mode

## v1.0.18.0
- Attendance actions now adapt to the user state more clearly in activity detail
- The creator is auto-joined and auto-confirmed, and cannot leave their own activity
- Confirmed attendees are shown with a cleaner empty state when only the organizer is present

## v1.0.17.2
- Create and edit activities now use a full-screen location picker instead of an embedded interactive map
- The picker keeps the fixed center pin UX and returns the selected coordinates to the form
- The create/edit form stays compact and no longer fights with vertical scrolling

## v1.0.17.1
- Edit activity now opens from the activity detail screen for organizers
- Create activity screen now works in edit mode with prefilled fields and save changes
- Location picking uses a fixed center pin and the map center becomes the selected point

## v1.0.17.0
- Complete activity detail screen added for Map and Activities entry points
- Detail now shows organizer, attendees, capacity, status and main actions in one place
- Existing local join, leave, delete and chat actions are reused without backend changes

## v1.0.16.4
- Search overlay no longer shows the pink divider under the input
- Input focus is now handled with a subtle border instead of a full-width line
- Tapping outside the search panel keeps dismissing the overlay on Map and Activities

## v1.0.16.3
- Search overlay is now flatter and cleaner with one floating panel and a simple input row
- Results appear directly below the input with dividers instead of nested cards
- Search logic, filters, map centering and selection behavior remain unchanged

## v1.0.16.2
- Map search now shows matching activity results in a compact dropdown while typing
- Tapping a search result centers the map and opens the selected activity card
- Demo activity seed text was sanitized to keep Café, emojis and preview strings readable

## v1.0.16.1
- Activity search moved into a compact overlay below the header
- Search button now sits next to filters and shows an active state
- Added manual demo data loading from settings for local testing

## v1.0.16.0
- Compact activity search added to Map and Activities
- Search combines with existing filters and persists locally
- Empty states now distinguish between filters and search

## v1.0.15.3
- Activities empty-state card now wraps its content instead of stretching toward the footer
- Compact top-aligned empty state keeps the same dark kawaii style
- Filter logic, modal behavior and map layout remain unchanged

## v1.0.15.2
- Map header now keeps the version badge next to the title and moves the filters button to the right
- Activities empty state is now compact and content-sized instead of tall and centered
- Filter modal behavior and persistence remain unchanged

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
