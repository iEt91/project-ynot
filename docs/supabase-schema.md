# Supabase Schema Draft

This document describes the future Supabase schema draft for Ynot.
It is documentation only. It does not connect Flutter to Supabase yet and it
does not change the current mock/local behavior.

## 1. Table overview

### `profiles`
- Purpose: user identity and public profile data.
- Key fields:
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
  - counters for created and attended activities
- Relationships:
  - Primary user profile table.
  - Referenced by activities, participants, messages, feedback, reports,
    blocked users, notifications, moderation flags, and preferences.
- Notes:
  - This is the public-facing profile layer for later backend work.

### `user_preferences`
- Purpose: local-style user settings that will later live in Supabase.
- Key fields:
  - notification toggles
  - discovery settings
  - privacy toggles
  - chat visibility settings
  - mock location key
- Relationships:
  - One row per profile.
- Notes:
  - Mirrors current mock/local preferences.

### `activities`
- Purpose: activity lifecycle, discovery, and location metadata.
- Key fields:
  - creator identity and label
  - title, description, category, vibe, zone
  - lifecycle `status`
  - exact and approximate coordinates
  - capacity and counts
  - chat summary fields
  - location privacy unlock time
- Relationships:
  - Created by a profile.
  - Parent record for participants, chat, saved activities, feedback, reports,
    notifications, and moderation flags.
- Notes:
  - Approximate location remains a first-class field for privacy.

### `activity_participants`
- Purpose: per-user participation, attendance, and per-user chat state.
- Key fields:
  - `activity_id`
  - `user_id`
  - creator flag
  - join/confirm timestamps
  - attendance response and timestamp
  - per-user chat unread state
  - archived-for-user state
  - mute state
- Relationships:
  - Many-to-many bridge between profiles and activities.
- Notes:
  - Also covers archived-chat visibility per user in the MVP schema draft.

### `chats`
- Purpose: one chat container per activity.
- Key fields:
  - `activity_id`
  - `status`
  - read-only timestamp
  - archived timestamp
- Relationships:
  - One chat per activity.
  - Parent of `chat_messages`.
- Notes:
  - Archived and read-only states stay separate from activity lifecycle.

### `chat_messages`
- Purpose: message history for activity chats.
- Key fields:
  - `chat_id`
  - `activity_id`
  - `sender_id`
  - `content`
  - `sender_name`
  - `sender_emoji`
  - moderation state
  - soft delete timestamp
- Relationships:
  - Belongs to a chat.
  - Belongs to an activity.
  - Sent by a profile.
- Notes:
  - Designed so later backend moderation can hide or label messages.

### `saved_activities`
- Purpose: per-user saved/favorites list.
- Key fields:
  - `user_id`
  - `activity_id`
- Relationships:
  - Many-to-many bridge between profiles and activities.
- Notes:
  - Used by Guardadas.

### `feedback`
- Purpose: private feedback between participants after activities.
- Key fields:
  - `activity_id`
  - `reviewer_user_id`
  - `reviewed_user_id`
  - selected feedback value
- Relationships:
  - Links two profiles through an activity.
- Notes:
  - One feedback entry per reviewer/reviewed/activity.

### `reports`
- Purpose: internal moderation reports.
- Key fields:
  - reporter
  - target type and target id
  - activity reference
  - reason and optional note
  - report status and resolution timestamps
- Relationships:
  - Reporter is a profile.
  - Target can be a user, activity, or message.
- Notes:
  - Remains internal. No user-facing report history in the product.

### `blocked_users`
- Purpose: local block list for safety behavior.
- Key fields:
  - blocker user
  - blocked user
- Relationships:
  - Two profile references.
- Notes:
  - Used by attendee labels, chat hiding, and join warnings.

### `notifications`
- Purpose: local notification inbox in the future backend.
- Key fields:
  - user
  - optional activity
  - notification type
  - title/body
  - read state
  - dedupe key
- Relationships:
  - Belongs to a profile and optionally an activity.
- Notes:
  - Supports in-app notifications before any push migration.

### `moderation_flags`
- Purpose: internal keyword-based moderation flags.
- Key fields:
  - source type and source id
  - activity
  - user
  - keyword, category, text snippet
  - status
  - dedupe key
  - AI-ready review fields
- Relationships:
  - Belongs to an activity and a profile.
- Notes:
  - Draft keeps the AI fields extensible for later moderation work.

## 2. Relationships summary

- `profiles` is the root identity table.
- `activities.creator_id` points to `profiles.id`.
- `activity_participants` connects `profiles` and `activities`.
- `chats` is a 1:1 companion to `activities`.
- `chat_messages` belongs to both `chats` and `activities`.
- `saved_activities` connects `profiles` and `activities`.
- `feedback` connects two profiles through one activity.
- `reports`, `blocked_users`, `notifications`, and `moderation_flags`
  all reference `profiles`, and most also reference `activities`.
- `user_preferences` is a 1:1 extension of `profiles`.

## 3. Migration order recommendation

Recommended order for the real backend rollout:

1. `profiles`
2. `activities`
3. `activity_participants`
4. `chats`
5. `chat_messages`
6. `saved_activities`
7. `feedback`
8. `reports`
9. `blocked_users`
10. `moderation_flags`
11. `notifications`
12. `user_preferences`

Why this order:
- identity first
- activity graph second
- participation and chat third
- personal utility features next
- safety/moderation after the core graph exists
- preferences last, because they can be layered on top of everything else

## 4. What remains mock/local

These features stay local until the real backend migration begins:

- demo auth flow
- local seed/demo activities
- mock location testing
- local notifications demo generator
- local moderation tools
- local history and saved cleanup
- archived chat visibility rules
- attendance prompts and post-activity checks
- feedback gating and safety reminders

## 5. RLS and security notes

- Start with RLS enabled on every table.
- Add explicit per-user read/write policies during migration.
- Keep moderation data private.
- Keep reports internal only.
- Keep notification records private to the owner user.
- Do not expose exact activity location before the privacy window.
- Migrate one module at a time and validate locally before the next step.

## 6. Before each Supabase step

Use this checklist before changing backend code:

- auth demo still works
- profile onboarding still works
- activity creation still works
- join/confirm/leave still works
- chat still works
- archived chat still works
- feedback still works
- reports still work
- blocking still works
- notifications still work
- saved/history cleanup still works

