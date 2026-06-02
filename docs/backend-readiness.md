# Backend Readiness Audit

**Version:** v1.0.32.0

This document maps the current mock/local implementation in `apps/mobile` to a future Supabase-backed backend. It does **not** change app behavior. The app remains fully local/mock for now.

## Current local state

The app currently stores and reads the following data locally through `SharedPreferences` snapshots and related helpers:

- Users / profile data
- Activities
- Chats and chat messages
- Reports
- Private feedback
- Notifications
- Blocked users
- Saved activities
- Moderation flags
- Attendance responses
- Pre-activity checklist state
- Notification / recommendation / archive preferences
- Search and activity filter state

## Current local models

| Model | File | What it represents today | Main features that depend on it |
| --- | --- | --- | --- |
| `AppUser` | `apps/mobile/lib/src/core/models/app_user.dart` | Local demo user, profile, counts, status, avatar, bio, interests | Auth/bootstrap, Profile, Edit profile, Public profile, onboarding |
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

## Suggested future Supabase tables

The following table names are suggested for migration. They can be adjusted to match existing backend conventions later.

### `profiles`
Stores public and private profile data for users.

Suggested fields:

- `id` uuid, primary key, references `auth.users.id`
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

Depends on:

- Profile
- Edit profile
- Public profile
- Onboarding

### `activities`
Stores activity content, lifecycle, privacy location, and local counts.

Suggested fields:

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

Depends on:

- Map
- Activities list
- Activity detail
- Create/Edit activity
- History
- Saved
- Chat previews
- Upcoming reminders
- Location privacy

### `activity_participants`
Stores per-user activity membership and attendance state.

Suggested fields:

- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `status` text (`joined_pending_confirmation`, `confirmed`, `attended`, `no_show`, `left`, `cancelled`, etc.)
- `is_creator` boolean
- `joined_at` timestamp
- `confirmed_at` timestamp nullable
- `attendance_response` text nullable
- `attendance_response_at` timestamp nullable
- `created_at` timestamp
- `updated_at` timestamp

Depends on:

- Join / leave / confirm flow
- Attendance check
- Feedback gating
- Participant counts
- Chat permissions
- Archived/finished chat state

### `chat_threads`
Stores chat metadata per activity.

Suggested fields:

- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `is_archived_for_user` boolean default false
- `created_at` timestamp
- `updated_at` timestamp

Depends on:

- Chats tab
- Archived chat management
- Chat header status

### `chat_messages`
Stores chat messages.

Suggested fields:

- `id` uuid primary key
- `chat_id` uuid references `chat_threads.id`
- `activity_id` uuid references `activities.id`
- `sender_id` uuid references `profiles.id`
- `content` text
- `created_at` timestamp
- `edited_at` timestamp nullable
- `deleted_at` timestamp nullable
- `moderation_state` text nullable

Depends on:

- Chat
- Chat notifications
- Report message flow
- Moderation flags
- Archived chat read-only behavior

### `moderation_reports`
Stores user-submitted safety reports.

Suggested fields:

- `report_id` uuid primary key
- `reporter_user_id` uuid references `profiles.id`
- `target_type` text (`activity`, `user`, `message`)
- `target_id` uuid/text
- `activity_id` uuid references `activities.id`
- `reason` text
- `note` text nullable
- `created_at` timestamp

Depends on:

- Report activity / user / message
- Safety tooling
- Moderation review workflows

### `private_feedback`
Stores private feedback entries.

Suggested fields:

- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `reviewer_user_id` uuid references `profiles.id`
- `reviewed_user_id` uuid references `profiles.id`
- `selected_feedback` text
- `created_at` timestamp

Depends on:

- Feedback screen
- Feedback gating
- Internal recommendation signals later

### `in_app_notifications`
Stores local/in-app notification feed rows.

Suggested fields:

- `id` uuid primary key
- `user_id` uuid references `profiles.id`
- `type` text
- `activity_id` uuid references `activities.id`
- `title` text
- `body` text
- `is_read` boolean
- `dedupe_key` text unique per user
- `created_at` timestamp
- `read_at` timestamp nullable

Depends on:

- Notifications screen
- Bell badge
- Activity reminders
- Chat message alerts
- Activity finished / feedback available

### `blocked_users`
Stores block relationships.

Suggested fields:

- `id` uuid primary key
- `blocker_user_id` uuid references `profiles.id`
- `blocked_user_id` uuid references `profiles.id`
- `created_at` timestamp
- `reason` text nullable

Depends on:

- Block user flow
- Attendee labels
- Chat message masking
- Public profile / safety behavior
- Feedback restrictions

### `saved_activities`
Stores saves/favorites.

Suggested fields:

- `id` uuid primary key
- `user_id` uuid references `profiles.id`
- `activity_id` uuid references `activities.id`
- `created_at` timestamp

Depends on:

- Saved activities screen
- Map / activity cards save actions
- Share / detail flows that expose save state

### `moderation_flags`
Stores internal keyword / risk flags for review.

Suggested fields:

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

Depends on:

- Moderation internal screen
- Flag detail screen
- Soft moderation warning
- Risky content detection

### `user_settings`
Stores preference toggles and privacy options.

Suggested fields:

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

Depends on:

- Settings / Preferences
- Notification gating
- Discovery badges
- Archived chats visibility
- Location privacy explainer

### `attendance_responses`
Optional separate table if attendance is split from `activity_participants`.

Suggested fields:

- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `response` text (`attended`, `no_show`, `unknown`)
- `created_at` timestamp

Depends on:

- Post-activity attendance prompt
- Feedback gating

### `pre_activity_checklist`
Optional separate table if checklist is split from `activity_participants`.

Suggested fields:

- `id` uuid primary key
- `activity_id` uuid references `activities.id`
- `user_id` uuid references `profiles.id`
- `item_key` text
- `checked` boolean
- `created_at` timestamp
- `updated_at` timestamp

Depends on:

- Pre-activity checklist
- Activity detail / chat header checklist

## Relationships

- `profiles.id` -> parent for almost every user-owned record
- `activities.creator_id` -> `profiles.id`
- `activity_participants.activity_id` -> `activities.id`
- `activity_participants.user_id` -> `profiles.id`
- `chat_threads.activity_id` -> `activities.id`
- `chat_messages.chat_id` -> `chat_threads.id`
- `chat_messages.activity_id` -> `activities.id`
- `chat_messages.sender_id` -> `profiles.id`
- `moderation_reports.reporter_user_id` -> `profiles.id`
- `moderation_reports.activity_id` -> `activities.id`
- `private_feedback.activity_id` -> `activities.id`
- `private_feedback.reviewer_user_id` -> `profiles.id`
- `private_feedback.reviewed_user_id` -> `profiles.id`
- `in_app_notifications.user_id` -> `profiles.id`
- `in_app_notifications.activity_id` -> `activities.id`
- `blocked_users.blocker_user_id` -> `profiles.id`
- `blocked_users.blocked_user_id` -> `profiles.id`
- `saved_activities.user_id` -> `profiles.id`
- `saved_activities.activity_id` -> `activities.id`
- `moderation_flags.activity_id` -> `activities.id`
- `moderation_flags.user_id` -> `profiles.id`

## Suggested migration order

1. `auth.users` + `profiles`
2. `activities`
3. `activity_participants`
4. `chat_threads`
5. `chat_messages`
6. `saved_activities`
7. `blocked_users`
8. `user_settings`
9. `in_app_notifications`
10. `moderation_reports`
11. `moderation_flags`
12. `private_feedback`
13. `attendance_responses`
14. `pre_activity_checklist`

## Notes for the migration

- Keep the mock/local snapshot format working until the backend is fully ready.
- Migrate one feature at a time, starting with profile, activities, and participants.
- Chat should come after activities and participants, because it depends on both.
- Moderation, reports, feedback, and notifications can be migrated later without changing the UI contract.
- The current app already sanitizes old mojibake and local demo data, so backend data should preserve that same safe-display behavior.
