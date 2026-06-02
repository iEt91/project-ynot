# Backend Readiness Audit

Version: `v1.0.32.0`

This document audits the current mock/local implementation in `apps/mobile` and maps it to a future Supabase migration path. It does **not** change app behavior. The app stays fully local/mock for now.

## A) Current local state overview

The app currently keeps almost all product state inside a single local snapshot managed by `AppController` and persisted through `LocalMockStore`. Session/login state and the seed-disable wipe flag live in `LocalSessionStore`.

| Data type | Current local owner | Where it currently lives | Notes |
| --- | --- | --- | --- |
| Users / demo session | `AppController`, `LocalSessionStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_session_store.dart` | Demo login, current user, local session restore, wipe flag |
| Public profiles | `AppController` | `apps/mobile/lib/src/core/state/app_controller.dart` + `AppUser` | Public profile screen uses the same local user model |
| Activities | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Includes lifecycle, exact/approximate location, counts, saved state, previews |
| Activity participants | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Join/confirm/leave/attendance responses and per-user activity state |
| Chats | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Active chats, archived chats, unread counts, per-user visibility |
| Messages | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Stored per activity/chat, read-only after finish |
| Saved activities | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Local favorites / saved list |
| Feedback | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Private feedback entries and gating |
| Reports | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Internal moderation data only |
| Blocked users | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Block list, labels, chat masking, safety warnings |
| Notifications | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Local in-app notification center and unread badge |
| Moderation flags | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Keyword-based internal moderation flags and review state |
| Settings / preferences | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Notification toggles, discovery toggles, privacy toggles |
| Attendance checks | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Post-activity attendance prompt and feedback gating |
| Archived chats | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Per-user hidden archived chats and read-only archive behavior |
| Search / filters | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Discovery search query and filters persist locally |
| Pre-activity checklist | `AppController`, `LocalMockStore` | `apps/mobile/lib/src/core/state/app_controller.dart`, `apps/mobile/lib/src/core/data/local_mock_store.dart` | Per-user, per-activity checklist state |

## Current local models

| Model | File | What it represents today | Main features that depend on it |
| --- | --- | --- | --- |
| `AppUser` | `apps/mobile/lib/src/core/models/app_user.dart` | Local demo user, public profile, counts, status, avatar, bio, interests | Auth/bootstrap, Profile, Edit profile, Public profile, onboarding |
| `Activity` | `apps/mobile/lib/src/core/models/activity.dart` | Activity content, lifecycle, privacy location, counts, chat previews, feedback targets | Map, Activities, Activity detail, Create/Edit, History, Saved, Chat |
| `ChatMessage` | `apps/mobile/lib/src/core/models/chat_message.dart` | Local chat message with sender metadata | Chat, archived chats, notifications, report flow, moderation |
| `ModerationReport` | `apps/mobile/lib/src/core/models/moderation_report.dart` | Internal moderation report submitted by users | Report flow, moderation review, safety tooling |
| `PrivateFeedbackEntry` | `apps/mobile/lib/src/core/models/private_feedback.dart` | Private feedback per reviewer/reviewed/activity | Feedback screen, profile-safe stats, recommendations later |
| `InAppNotification` | `apps/mobile/lib/src/core/models/in_app_notification.dart` | Local in-app notification center entry | Notifications screen, bell badge, reminder triggers |
| `BlockedUserEntry` | `apps/mobile/lib/src/core/models/blocked_user.dart` | Local block list entry | Blocking UI, attendee labels, chat hiding, report/user safety |
| `ModerationFlag` | `apps/mobile/lib/src/core/models/moderation_flag.dart` | Internal keyword moderation flag | Internal moderation screen, flag detail, review workflow |
| `AttendanceResponse` | `apps/mobile/lib/src/core/models/attendance_response.dart` | Post-activity attendance answer | Attendance prompt, feedback gating, history/chat/archive |
| `AppSettings` | `apps/mobile/lib/src/core/models/app_settings.dart` | Local preferences and feature toggles | Settings, notifications, recommendations, archived chats, privacy toggles |
| `ActivityFilters` | `apps/mobile/lib/src/core/models/activity_filters.dart` | Search/filter state for discovery | Map, Activities |
| `PreActivityChecklist` | `apps/mobile/lib/src/core/models/pre_activity_checklist.dart` | User/activity checklist state | Activity detail, chat header checklist |
| `ReportableParticipant` | `apps/mobile/lib/src/core/models/reportable_participant.dart` | Candidate people for report target selection | Chat report selector, activity detail report flow |

## B) Future Supabase tables

Below is a suggested table set for the future backend. Table names can change later, but the relationships and responsibilities should remain similar.

### `profiles`

Purpose:
- Public/private user profile data.

Fields:
- `id` uuid primary key, references `auth.users.id`
- `phone_masked` text
- `nickname` text
- `avatar_emoji` text
- `photo_url` text nullable
- `bio` text
- `languages` text[]
- `vibes` text[]
- `interests` text[]
- `status` text
- `profile_complete` boolean
- `created_activity_count` integer
- `attending_activity_count` integer
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- Parent row for almost every user-owned entity.
- Referenced by activities, participants, messages, reports, feedback, blocks, notifications, moderation flags, settings.

Indexes needed:
- primary key on `id`
- optional index on `nickname` for public profile lookup
- optional GIN indexes on `languages`, `vibes`, `interests` if search or discovery filters move server-side later

RLS / security notes:
- User can read and update their own row.
- Public profile access should expose only safe fields, either through a view or a restricted policy.
- Keep phone data private; never expose `phone_masked` to other users.

### `activities`

Purpose:
- Core activity record with lifecycle, time, location, and discovery metadata.

Fields:
- `id` uuid/text primary key
- `creator_id` uuid references `profiles.id`
- `creator_label` text
- `activity_type` text
- `visibility` text
- `title` text
- `description` text
- `category` text
- `vibe` text
- `zone` text
- `status` text
- `real_lat` double precision
- `real_lng` double precision
- `display_lat` double precision
- `display_lng` double precision
- `location_privacy_radius_m` integer
- `exact_location_unlock_at` timestamp
- `start_time` timestamp
- `end_time` timestamp
- `max_people` integer
- `confirmed_count` integer
- `pending_count` integer
- `last_message_preview` text
- `last_message_at` timestamp nullable
- `unread_message_count` integer
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- Parent for participants, chats, messages, saved activities, reports, feedback, notifications, moderation flags.

Indexes needed:
- `creator_id`
- `status`
- `start_time`
- `category`
- `zone`
- combined index on `(status, start_time)` for discovery and reminders

RLS / security notes:
- Public read should be limited to safe fields for discoverable/open activities.
- Creator can insert/update/delete their own activity.
- Exact location must stay protected until the privacy rule allows it.
- If the backend exposes exact/approximate location separately, use a secure view or RPC for the exact one.

### `activity_participants`

Purpose:
- Per-user participation state for an activity.

Fields:
- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `status` text (`joined_pending_confirmation`, `confirmed`, `attended`, `no_show`, `left`, `cancelled`, etc.)
- `is_creator` boolean
- `joined_at` timestamp
- `confirmed_at` timestamp nullable
- `attendance_response` text nullable
- `attendance_response_at` timestamp nullable
- `last_read_at` timestamp nullable
- `chat_unread_count` integer default 0
- `is_archived_for_user` boolean default false
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- Connects users to activities.
- Feeds participant counts, attendance prompts, chat visibility, archived chat state, and feedback eligibility.

Indexes needed:
- unique index on `(activity_id, user_id)`
- index on `user_id`
- index on `activity_id`
- index on `(activity_id, status)`

RLS / security notes:
- Users can read their own membership rows.
- Activity creators can read/manage participant rows for their activity.
- Per-user archive/read state should only be writable by the row owner.

### `chat_threads`

Purpose:
- Activity chat container and thread-level metadata.

Fields:
- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- One thread per activity.
- Parent for chat messages and per-user chat thread state.

Indexes needed:
- unique index on `activity_id`

RLS / security notes:
- Only participants/creator should access the thread.
- Archived/read-only behavior should be derived from activity status and per-user state, not from deleting thread rows.

### `chat_thread_members`

Purpose:
- Per-user chat state, including archived visibility and unread count.

Fields:
- `id` uuid primary key
- `chat_id` uuid references `chat_threads.id`
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `is_archived_for_user` boolean default false
- `hidden_from_chats_tab` boolean default false
- `last_read_at` timestamp nullable
- `unread_count` integer default 0
- `muted` boolean default false
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- Joins users to a chat thread for visibility, archive, and unread state.

Indexes needed:
- unique index on `(chat_id, user_id)`
- index on `user_id`
- index on `(user_id, hidden_from_chats_tab)`
- index on `activity_id`

RLS / security notes:
- Only the row owner should update archive/read/mute state.
- Participants and creators can read their own thread membership row.

### `chat_messages`

Purpose:
- Chat message history.

Fields:
- `id` uuid primary key
- `chat_id` uuid references `chat_threads.id`
- `activity_id` uuid references `activities.id`
- `sender_id` uuid references `profiles.id`
- `content` text
- `created_at` timestamp
- `edited_at` timestamp nullable
- `deleted_at` timestamp nullable
- `moderation_state` text nullable

Relationships:
- Parent for report-message flow, moderation flags, unread counts, and archived chat history.

Indexes needed:
- index on `(chat_id, created_at)`
- index on `activity_id`
- index on `sender_id`

RLS / security notes:
- Only chat participants should read messages.
- Only the sender or a moderation role/service role should edit/delete or flag moderation state.
- Old messages must remain accessible for moderation even if the chat is archived for the current user.

### `saved_activities`

Purpose:
- User favorites / saved activities.

Fields:
- `id` uuid primary key
- `user_id` uuid references `profiles.id`
- `activity_id` uuid references `activities.id`
- `created_at` timestamp

Relationships:
- Maps a user to a saved activity.

Indexes needed:
- unique index on `(user_id, activity_id)`
- index on `user_id`
- index on `activity_id`

RLS / security notes:
- Users can only create/read/delete their own saves.

### `private_feedback`

Purpose:
- Private internal feedback about another attendee.

Fields:
- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `reviewer_user_id` uuid references `profiles.id`
- `reviewed_user_id` uuid references `profiles.id`
- `selected_feedback` text
- `created_at` timestamp

Relationships:
- Uses activity participants and attendance responses for gating.

Indexes needed:
- unique index on `(activity_id, reviewer_user_id, reviewed_user_id)`
- index on `activity_id`
- index on `reviewed_user_id`
- index on `reviewer_user_id`

RLS / security notes:
- Users can create only their own feedback rows.
- Users should not see a public feedback history.
- Aggregated/private internal use only.

### `moderation_reports`

Purpose:
- User-submitted moderation reports for activities, users, and messages.

Fields:
- `report_id` uuid primary key
- `reporter_user_id` uuid references `profiles.id`
- `target_type` text (`activity`, `user`, `message`)
- `target_id` uuid/text
- `activity_id` uuid references `activities.id`
- `reason` text
- `note` text nullable
- `created_at` timestamp

Relationships:
- Links to reported activity, user, or message.

Indexes needed:
- unique index on `(reporter_user_id, target_type, target_id)` to prevent duplicates
- index on `activity_id`
- index on `(target_type, target_id)`
- index on `reporter_user_id`
- index on `created_at`

RLS / security notes:
- Users can create reports and read only their own submitted rows if needed.
- Moderation staff/service role should read the full table.
- Keep report data internal; do not expose it in the user UI.

### `blocked_users`

Purpose:
- Block relationships between users.

Fields:
- `id` uuid primary key
- `blocker_user_id` uuid references `profiles.id`
- `blocked_user_id` uuid references `profiles.id`
- `reason` text nullable
- `created_at` timestamp

Relationships:
- A block can affect chat display, attendee labels, report flows, and safety warnings.

Indexes needed:
- unique index on `(blocker_user_id, blocked_user_id)`
- index on `blocker_user_id`
- index on `blocked_user_id`

RLS / security notes:
- Users can create/delete only their own block rows.
- Other users should not read someone else’s block list.
- Keep the block list internal to the owner except for safety checks in application logic.

### `in_app_notifications`

Purpose:
- Local-style notification feed and badge state.

Fields:
- `id` uuid primary key
- `user_id` uuid references `profiles.id`
- `type` text
- `activity_id` uuid references `activities.id`
- `title` text
- `body` text
- `is_read` boolean
- `dedupe_key` text
- `created_at` timestamp
- `read_at` timestamp nullable

Relationships:
- Tied to user, optionally to an activity.

Indexes needed:
- unique index on `(user_id, dedupe_key)`
- index on `(user_id, is_read)`
- index on `(user_id, created_at)`
- index on `activity_id`

RLS / security notes:
- Users can read/update only their own notifications.
- Notification generation should still be controlled by preference toggles.

### `moderation_flags`

Purpose:
- Internal keyword/risk flags for moderation review.

Fields:
- `flag_id` uuid primary key
- `source_type` text (`activity`, `message`)
- `source_id` uuid/text
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `keyword` text
- `category` text
- `text_snippet` text
- `status` text (`pending`, `reviewed`, `dismissed`)
- `created_at` timestamp
- `ai_risk_score` numeric nullable
- `ai_risk_label` text nullable
- `ai_summary` text nullable
- `manually_reviewed_by` uuid nullable
- `reviewed_at` timestamp nullable

Relationships:
- Tied to an activity and the user/content that triggered the flag.

Indexes needed:
- unique or partial unique index on dedupe key / source pair to avoid duplicates
- index on `status`
- index on `activity_id`
- index on `source_type`
- index on `category`
- index on `created_at`

RLS / security notes:
- Hidden from normal users.
- Read/write for moderation service role or internal staff only.

### `user_settings`

Purpose:
- User preferences and toggles.

Fields:
- `user_id` uuid references `profiles.id`
- `receive_notifications` boolean
- `chat_messages_notifications` boolean
- `activity_starting_soon_notifications` boolean
- `show_recommendations` boolean
- `show_saved_highlights` boolean
- `show_archived_chats` boolean
- `hide_precise_location_until_unlock` boolean
- `personalized_recommendations` boolean
- `language` text
- `theme` text
- `updated_at` timestamp

Relationships:
- One row per user.

Indexes needed:
- unique index on `user_id`

RLS / security notes:
- Users can only read and update their own settings.

### `attendance_responses`

Purpose:
- Post-activity attendance answers.

Fields:
- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `response` text (`attended`, `no_show`, `unknown`)
- `created_at` timestamp

Relationships:
- Used by feedback gating and activity history.

Indexes needed:
- unique index on `(activity_id, user_id)`
- index on `activity_id`
- index on `user_id`
- index on `response`

RLS / security notes:
- Users can create/update their own attendance response.
- Activity creators may need aggregate read access for internal checks.

### `pre_activity_checklists`

Purpose:
- Per-user checklist items before an activity starts.

Fields:
- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `item_key` text
- `checked` boolean
- `created_at` timestamp
- `updated_at` timestamp

Relationships:
- Tied to a user and an activity.

Indexes needed:
- unique index on `(activity_id, user_id, item_key)`
- index on `user_id`
- index on `activity_id`

RLS / security notes:
- Users can only read/write their own checklist rows.

## C) Migration order recommendation

Recommended migration order:

1. users / profiles
2. activities
3. participants
4. chats / messages
5. saved activities
6. feedback
7. reports / moderation
8. notifications
9. preferences

Suggested practical sequence:

1. `profiles`
2. `activities`
3. `activity_participants`
4. `chat_threads`
5. `chat_thread_members`
6. `chat_messages`
7. `saved_activities`
8. `private_feedback`
9. `moderation_reports`
10. `blocked_users`
11. `in_app_notifications`
12. `moderation_flags`
13. `user_settings`
14. `attendance_responses`
15. `pre_activity_checklists`

## D) Risk notes

- The previous Supabase attempt broke when the app expected remote state and RPC/schema pieces that were not aligned yet. The profile/bootstrap path hit missing backend functions or missing schema cache state, so the mock app and remote backend drifted apart.
- Avoid repeating that by keeping the current local snapshot as the source of truth until one module is fully verified.
- Keep a mock-mode fallback alive during every migration step.
- Migrate one module at a time, starting with profiles and activities, then participants, then chat.
- Commit and tag after each module so rollback stays simple.
- Do not move moderation, reporting, feedback, notifications, or block logic into Supabase until the core activity and profile tables are stable.
- Keep exact-location privacy logic and archived-chat behavior consistent with the current local app before migrating those pieces.

## Recommended backend rollout strategy

1. Add tables and RLS for `profiles` and `activities`.
2. Add `activity_participants` and `chat_threads`.
3. Add `chat_thread_members` and `chat_messages`.
4. Add `saved_activities`, `user_settings`, and `attendance_responses`.
5. Add `private_feedback`, `moderation_reports`, `blocked_users`, `in_app_notifications`, and `moderation_flags`.
6. Keep the local snapshot adapter until the app can read from Supabase without changing the UI contract.
