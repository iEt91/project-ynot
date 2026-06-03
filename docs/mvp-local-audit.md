# MVP Local Final Audit

Version: `v1.0.36.0`

This document audits the current mock/local MVP state before moving toward a backend or Supabase migration. It does not change app behavior.

## 1) Current local coverage checklist

- [x] Auth demo
- [x] Profile onboarding
- [x] Profile editing
- [x] Map discovery
- [x] Activity creation
- [x] Activity edit
- [x] Activity delete
- [x] Full-screen location picker
- [x] Join activity
- [x] Confirm attendance
- [x] Leave activity
- [x] Active chat
- [x] Archived chat
- [x] Feedback
- [x] Reports
- [x] Blocking
- [x] Moderation mock
- [x] Notifications
- [x] Preferences
- [x] History cleanup
- [x] Saved activities cleanup

## 2) Local state map

### Where data lives today

- `AppController` owns the live in-memory app state.
- `LocalMockStore` persists the full mock snapshot to `SharedPreferences`.
- `LocalSessionStore` keeps the local client session and the seed-disable flag after wipe.

### Current local data types

- `AppUser`
- `Activity`
- `ChatMessage`
- `PrivateFeedbackEntry`
- `ModerationReport`
- `BlockedUserEntry`
- `InAppNotification`
- `ModerationFlag`
- `AttendanceResponse`
- `AppSettings`
- `ActivityDiscoveryFilters`
- `PreActivityChecklist`
- hidden archived chat ids
- hidden history ids
- saved activity ids
- reminder sent keys
- notification read state

## 3) Future Supabase tables

These are the suggested backend tables for a later migration.

### `profiles`

- Purpose: store user identity and public profile data.
- Fields:
  - `id`
  - `phone_masked`
  - `nickname`
  - `avatar_emoji`
  - `photo_url`
  - `bio`
  - `languages`
  - `vibes`
  - `interests`
  - `status`
  - `profile_complete`
  - `created_activity_count`
  - `attending_activity_count`
  - timestamps
- Relationships:
  - parent for activities, participants, messages, feedback, reports, blocks, notifications, moderation, settings
- Indexes:
  - primary key on `id`
  - optional index on `nickname`
  - optional GIN indexes on `languages`, `vibes`, `interests`
- RLS / security:
  - user can read and update own profile
  - public reads should expose only safe profile fields
  - phone stays private

### `activities`

- Purpose: core activity record and discovery data.
- Fields:
  - `id`
  - `creator_id`
  - `creator_label`
  - `activity_type`
  - `visibility`
  - `title`
  - `description`
  - `category`
  - `vibe`
  - `zone`
  - `status`
  - `real_lat`
  - `real_lng`
  - `display_lat`
  - `display_lng`
  - `location_privacy_radius_m`
  - `exact_location_unlock_at`
  - `start_time`
  - `end_time`
  - `max_people`
  - `confirmed_count`
  - `pending_count`
  - `last_message_preview`
  - `last_message_at`
  - `unread_message_count`
  - timestamps
- Relationships:
  - parent for participants, chats, messages, saved items, feedback, reports, notifications, moderation flags
- Indexes:
  - `creator_id`
  - `status`
  - `start_time`
  - `category`
  - `zone`
  - `(status, start_time)`
- RLS / security:
  - creator can manage own activity
  - public reads only for allowed fields
  - exact location must stay protected until unlock rules allow it

### `activity_participants`

- Purpose: user participation state per activity.
- Fields:
  - `id`
  - `activity_id`
  - `user_id`
  - `status`
  - `is_creator`
  - `joined_at`
  - `confirmed_at`
  - `attendance_response`
  - `attendance_response_at`
  - `last_read_at`
  - `chat_unread_count`
  - `is_archived_for_user`
  - timestamps
- Relationships:
  - links users to activities
- Indexes:
  - unique `(activity_id, user_id)`
  - `user_id`
  - `activity_id`
  - `(activity_id, status)`
- RLS / security:
  - user reads own participation row
  - creator reads activity participants
  - per-user archive/read state is private to the owner

### `chat_threads`

- Purpose: chat container for each activity.
- Fields:
  - `id`
  - `activity_id`
  - timestamps
- Relationships:
  - one thread per activity
- Indexes:
  - unique `activity_id`
- RLS / security:
  - only visible to activity participants and creator

### `chat_thread_members`

- Purpose: per-user chat state.
- Fields:
  - `id`
  - `chat_id`
  - `activity_id`
  - `user_id`
  - `is_archived_for_user`
  - `hidden_from_chats_tab`
  - `last_read_at`
  - `unread_count`
  - `muted`
  - timestamps
- Relationships:
  - links users to a chat thread
- Indexes:
  - unique `(chat_id, user_id)`
  - `user_id`
  - `activity_id`
- RLS / security:
  - user can manage own row
  - creator and participants can read the thread

### `chat_messages`

- Purpose: individual chat messages.
- Fields:
  - `id`
  - `chat_id`
  - `activity_id`
  - `sender_id`
  - `content`
  - `created_at`
  - optional read/delivery metadata
- Relationships:
  - belongs to chat thread and activity
- Indexes:
  - `chat_id`
  - `activity_id`
  - `(chat_id, created_at)`
  - `sender_id`
- RLS / security:
  - participants can read/write while chat is active
  - archived chats become read-only

### `saved_activities`

- Purpose: local favorites / saved items.
- Fields:
  - `id`
  - `user_id`
  - `activity_id`
  - timestamps
- Relationships:
  - belongs to user and activity
- Indexes:
  - unique `(user_id, activity_id)`
  - `user_id`
  - `activity_id`
- RLS / security:
  - user can only read/write own saved rows

### `private_feedback`

- Purpose: internal private feedback entries.
- Fields:
  - `id`
  - `activity_id`
  - `reviewer_user_id`
  - `reviewed_user_id`
  - `selected_feedback`
  - `created_at`
- Relationships:
  - ties reviewer, reviewed user, and activity
- Indexes:
  - unique `(activity_id, reviewer_user_id, reviewed_user_id)`
  - `activity_id`
  - `reviewed_user_id`
  - `reviewer_user_id`
- RLS / security:
  - review entries should stay private
  - user can create only their own feedback

### `moderation_reports`

- Purpose: user-submitted reports for moderation.
- Fields:
  - `id`
  - `reporter_user_id`
  - `target_type`
  - `target_id`
  - `activity_id`
  - `reason`
  - `note`
  - `created_at`
- Relationships:
  - reporter, target, and activity
- Indexes:
  - unique `(reporter_user_id, target_type, target_id)`
  - `activity_id`
  - `reporter_user_id`
  - `(target_type, target_id)`
- RLS / security:
  - user can submit own report only
  - reports remain internal

### `blocked_users`

- Purpose: user-managed block list.
- Fields:
  - `id`
  - `user_id`
  - `blocked_user_id`
  - `created_at`
- Relationships:
  - user-to-user safety record
- Indexes:
  - unique `(user_id, blocked_user_id)`
  - `user_id`
  - `blocked_user_id`
- RLS / security:
  - user can only manage own block list

### `in_app_notifications`

- Purpose: local notification center rows.
- Fields:
  - `id`
  - `user_id`
  - `activity_id`
  - `type`
  - `title`
  - `body`
  - `is_read`
  - `created_at`
  - `read_at`
  - `dedupe_key`
- Relationships:
  - belongs to user and optionally activity
- Indexes:
  - `user_id`
  - `activity_id`
  - `is_read`
  - unique `dedupe_key` per user
- RLS / security:
  - user sees only own notifications

### `moderation_flags`

- Purpose: internal keyword / AI moderation review queue.
- Fields:
  - `id`
  - `source_type`
  - `source_id`
  - `activity_id`
  - `user_id`
  - `keyword`
  - `category`
  - `text_snippet`
  - `status`
  - `ai_risk_score`
  - `ai_risk_label`
  - `ai_summary`
  - `manually_reviewed_by`
  - `reviewed_at`
  - `created_at`
  - `dedupe_key`
- Relationships:
  - points to source content and author
- Indexes:
  - `status`
  - `activity_id`
  - `user_id`
  - unique `dedupe_key`
- RLS / security:
  - internal only
  - not visible to normal users

### `user_settings`

- Purpose: local preferences and discovery controls.
- Fields:
  - `user_id`
  - `receive_notifications`
  - `chat_messages_notifications`
  - `activity_starting_soon_notifications`
  - `recommended_activities_notifications`
  - `search_radius_km`
  - `mock_current_location_key`
  - `show_recommendations`
  - `show_saved_highlights`
  - `show_archived_chats`
  - `mute_all_chats`
  - `hide_precise_location_until_unlock`
  - `personalized_recommendations`
  - timestamps
- Relationships:
  - one row per user
- Indexes:
  - unique `user_id`
- RLS / security:
  - user can only read/write own settings

## 4) Migration order recommendation

1. users/profiles
2. activities
3. participants
4. chats/messages
5. saved activities
6. feedback
7. reports/moderation
8. notifications
9. preferences

## 5) Risks before Supabase migration

- The app currently assumes local state is the source of truth, so backend writes must not replace the local fallback until the module is fully verified.
- We previously had issues when a backend path blocked boot; keep the app usable in mock mode even if backend calls fail.
- Activity lifecycle, attendance, feedback, and chat all depend on each other; migrate one module at a time and validate each step.
- Preserve the local seed/wipe behavior and make sure demo mode still works without network access.
- Keep exact location private until the same unlock rules are mirrored in the backend.
- Do not expose moderation or report data to normal users during migration.
- Keep local snapshot persistence and session restoration until the backend replacement is complete.

## 6) Features safe to keep local for now

- Demo auth flow
- Local profile onboarding/editing
- Activity discovery filters and search
- Mock location radius testing
- Saved activities cleanup
- Personal history cleanup
- Archived chat visibility toggles
- Local notifications and notification management
- Attendance prompts and feedback gating
- Safety center and internal moderation tools
- Blocking and report submission flow

## 7) Features that need backend later

- Real authentication and account recovery
- Cross-device profile sync
- Shared activity persistence across multiple devices
- Real chat delivery and unread sync
- Server-side reports and moderation review queue
- Cross-device notifications
- Reliable attendance/feedback consistency across clients
- True public profile discovery from a shared database

## 8) Manual QA checklist before each major backend change

Use this checklist before every migration step:

1. Open the app in mock mode and verify it still boots.
2. Log in with the demo code `000000`.
3. Complete onboarding if the profile is incomplete.
4. Create an activity and confirm it appears in Map and Activities.
5. Edit the activity and verify the same item updates.
6. Open the activity detail, join it, confirm attendance, and open chat.
7. Send messages and verify they remain visible after returning to Chats.
8. Finish an activity and verify history, archived chat, feedback gating, and attendance prompts.
9. Save and unsave an activity.
10. Hide one activity from history and remove one saved activity locally.
11. Block a user and verify the safety labels and warnings remain correct.
12. Create a moderation flag with a risky word and confirm the moderation screen still works.
13. Generate demo notifications and confirm the notification badge and list still behave.
14. Change preferences and restart the app to confirm persistence.
15. Run `flutter analyze` and `flutter test`.

## 9) Final note

The MVP is still intentionally local/mock. The safest path to Supabase is to migrate one data module at a time, keep the local fallback alive, and commit/tag after each successful module migration.
