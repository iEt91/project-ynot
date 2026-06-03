create extension if not exists "pgcrypto";

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Core identity and profile data
-- -----------------------------------------------------------------------------

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  phone_masked text not null default '',
  nickname text not null default '',
  avatar_emoji text not null default '🌙',
  photo_url text,
  bio text not null default '',
  languages text[] not null default '{}'::text[],
  vibes text[] not null default '{}'::text[],
  interests text[] not null default '{}'::text[],
  status text not null default 'trusted',
  profile_complete boolean not null default false,
  created_activity_count integer not null default 0,
  attending_activity_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger profiles_touch_updated_at
before update on public.profiles
for each row execute function public.touch_updated_at();

create index if not exists profiles_nickname_idx
  on public.profiles (lower(nickname));

-- -----------------------------------------------------------------------------
-- User preferences and discovery controls
-- -----------------------------------------------------------------------------

create table if not exists public.user_preferences (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  receive_notifications boolean not null default true,
  chat_messages_notifications boolean not null default true,
  activity_starting_soon_notifications boolean not null default true,
  recommended_activities_notifications boolean not null default true,
  search_radius_km integer not null default 25,
  mock_current_location_key text not null default 'seoul',
  show_recommendations boolean not null default true,
  show_saved_highlights boolean not null default true,
  show_archived_chats boolean not null default true,
  mute_all_chats boolean not null default false,
  hide_precise_location_until_unlock boolean not null default true,
  personalized_recommendations boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create trigger user_preferences_touch_updated_at
before update on public.user_preferences
for each row execute function public.touch_updated_at();

create index if not exists user_preferences_show_archived_chats_idx
  on public.user_preferences (show_archived_chats);

-- -----------------------------------------------------------------------------
-- Activity lifecycle and discovery
-- -----------------------------------------------------------------------------

create table if not exists public.activities (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid not null references public.profiles(id) on delete cascade,
  creator_label text not null default '',
  activity_type text not null default 'user_activity',
  visibility text not null default 'public_activity',
  title text not null,
  description text not null default '',
  category text not null,
  vibe text not null,
  zone text not null default '',
  status text not null default 'open',
  real_lat numeric(9,6) not null,
  real_lng numeric(9,6) not null,
  display_lat numeric(9,6) not null,
  display_lng numeric(9,6) not null,
  location_privacy_radius_m integer not null default 180,
  exact_location_unlock_at timestamptz not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  max_people integer not null default 4,
  confirmed_count integer not null default 1,
  pending_count integer not null default 0,
  last_message_preview text not null default '',
  last_message_at timestamptz,
  unread_message_count integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint activities_max_people_check check (max_people between 2 and 50),
  constraint activities_status_check check (status in ('open', 'ongoing', 'finished', 'archived'))
);

create trigger activities_touch_updated_at
before update on public.activities
for each row execute function public.touch_updated_at();

create index if not exists activities_creator_id_idx
  on public.activities (creator_id);
create index if not exists activities_status_idx
  on public.activities (status);
create index if not exists activities_start_time_idx
  on public.activities (start_time);
create index if not exists activities_category_idx
  on public.activities (category);
create index if not exists activities_zone_idx
  on public.activities (zone);
create index if not exists activities_status_start_time_idx
  on public.activities (status, start_time);
create index if not exists activities_display_location_idx
  on public.activities (display_lat, display_lng);

-- -----------------------------------------------------------------------------
-- Participants, attendance, archived chat state and per-user chat state
-- -----------------------------------------------------------------------------

create table if not exists public.activity_participants (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  status text not null default 'joined_pending_confirmation',
  is_creator boolean not null default false,
  joined_at timestamptz not null default now(),
  confirmed_at timestamptz,
  attendance_response text,
  attendance_response_at timestamptz,
  last_read_at timestamptz,
  chat_unread_count integer not null default 0,
  is_archived_for_user boolean not null default false,
  muted boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint activity_participants_unique unique (activity_id, user_id),
  constraint activity_participants_attendance_response_check
    check (attendance_response is null or attendance_response in ('attended', 'no_show', 'unknown'))
);

create trigger activity_participants_touch_updated_at
before update on public.activity_participants
for each row execute function public.touch_updated_at();

create index if not exists activity_participants_activity_id_idx
  on public.activity_participants (activity_id);
create index if not exists activity_participants_user_id_idx
  on public.activity_participants (user_id);
create index if not exists activity_participants_activity_status_idx
  on public.activity_participants (activity_id, status);
create index if not exists activity_participants_archived_idx
  on public.activity_participants (user_id, is_archived_for_user);

-- -----------------------------------------------------------------------------
-- Chats and messages
-- -----------------------------------------------------------------------------

create table if not exists public.chats (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  status text not null default 'active',
  read_only_at timestamptz,
  archived_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chats_activity_id_unique unique (activity_id),
  constraint chats_status_check check (status in ('active', 'read_only', 'archived'))
);

create trigger chats_touch_updated_at
before update on public.chats
for each row execute function public.touch_updated_at();

create index if not exists chats_activity_id_idx
  on public.chats (activity_id);
create index if not exists chats_status_idx
  on public.chats (status);

create table if not exists public.chat_messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.chats(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  sender_id uuid not null references public.profiles(id) on delete cascade,
  content text not null,
  sender_name text not null default '',
  sender_emoji text not null default '💬',
  moderation_state text not null default 'clean',
  deleted_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chat_messages_moderation_state_check
    check (moderation_state in ('clean', 'flagged', 'hidden'))
);

create trigger chat_messages_touch_updated_at
before update on public.chat_messages
for each row execute function public.touch_updated_at();

create index if not exists chat_messages_chat_id_created_at_idx
  on public.chat_messages (chat_id, created_at);
create index if not exists chat_messages_activity_id_idx
  on public.chat_messages (activity_id);
create index if not exists chat_messages_sender_id_idx
  on public.chat_messages (sender_id);

-- -----------------------------------------------------------------------------
-- Saved activities
-- -----------------------------------------------------------------------------

create table if not exists public.saved_activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_id uuid not null references public.activities(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint saved_activities_unique unique (user_id, activity_id)
);

create trigger saved_activities_touch_updated_at
before update on public.saved_activities
for each row execute function public.touch_updated_at();

create index if not exists saved_activities_user_id_idx
  on public.saved_activities (user_id);
create index if not exists saved_activities_activity_id_idx
  on public.saved_activities (activity_id);

-- -----------------------------------------------------------------------------
-- Private feedback
-- -----------------------------------------------------------------------------

create table if not exists public.feedback (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  reviewer_user_id uuid not null references public.profiles(id) on delete cascade,
  reviewed_user_id uuid not null references public.profiles(id) on delete cascade,
  selected_feedback text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint feedback_unique unique (activity_id, reviewer_user_id, reviewed_user_id)
);

create trigger feedback_touch_updated_at
before update on public.feedback
for each row execute function public.touch_updated_at();

create index if not exists feedback_activity_id_idx
  on public.feedback (activity_id);
create index if not exists feedback_reviewer_user_id_idx
  on public.feedback (reviewer_user_id);
create index if not exists feedback_reviewed_user_id_idx
  on public.feedback (reviewed_user_id);

-- -----------------------------------------------------------------------------
-- Internal moderation and user safety
-- -----------------------------------------------------------------------------

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_user_id uuid not null references public.profiles(id) on delete cascade,
  target_type text not null,
  target_id uuid not null,
  activity_id uuid references public.activities(id) on delete cascade,
  reason text not null,
  note text,
  status text not null default 'pending',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by_user_id uuid references public.profiles(id) on delete set null,
  constraint reports_unique unique (reporter_user_id, target_type, target_id),
  constraint reports_target_type_check check (target_type in ('activity', 'message', 'user')),
  constraint reports_status_check check (status in ('pending', 'reviewed', 'dismissed'))
);

create trigger reports_touch_updated_at
before update on public.reports
for each row execute function public.touch_updated_at();

create index if not exists reports_reporter_user_id_idx
  on public.reports (reporter_user_id);
create index if not exists reports_target_idx
  on public.reports (target_type, target_id);
create index if not exists reports_activity_id_idx
  on public.reports (activity_id);
create index if not exists reports_status_idx
  on public.reports (status);

create table if not exists public.blocked_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint blocked_users_unique unique (user_id, blocked_user_id)
);

create trigger blocked_users_touch_updated_at
before update on public.blocked_users
for each row execute function public.touch_updated_at();

create index if not exists blocked_users_user_id_idx
  on public.blocked_users (user_id);
create index if not exists blocked_users_blocked_user_id_idx
  on public.blocked_users (blocked_user_id);

create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  activity_id uuid references public.activities(id) on delete cascade,
  type text not null,
  title text not null,
  body text not null,
  is_read boolean not null default false,
  dedupe_key text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  read_at timestamptz
);

create trigger notifications_touch_updated_at
before update on public.notifications
for each row execute function public.touch_updated_at();

create index if not exists notifications_user_id_idx
  on public.notifications (user_id);
create index if not exists notifications_activity_id_idx
  on public.notifications (activity_id);
create index if not exists notifications_is_read_idx
  on public.notifications (is_read);
create unique index if not exists notifications_user_dedupe_key_idx
  on public.notifications (user_id, dedupe_key);

create table if not exists public.moderation_flags (
  id uuid primary key default gen_random_uuid(),
  source_type text not null,
  source_id uuid not null,
  activity_id uuid not null references public.activities(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  keyword text not null,
  category text not null,
  text_snippet text not null,
  status text not null default 'pending',
  dedupe_key text not null,
  ai_risk_score numeric(4,2),
  ai_risk_label text,
  ai_summary text,
  manually_reviewed_by uuid references public.profiles(id) on delete set null,
  reviewed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint moderation_flags_unique unique (dedupe_key),
  constraint moderation_flags_source_type_check check (source_type in ('activity', 'message')),
  constraint moderation_flags_status_check check (status in ('pending', 'reviewed', 'dismissed'))
);

create trigger moderation_flags_touch_updated_at
before update on public.moderation_flags
for each row execute function public.touch_updated_at();

create index if not exists moderation_flags_status_idx
  on public.moderation_flags (status);
create index if not exists moderation_flags_activity_id_idx
  on public.moderation_flags (activity_id);
create index if not exists moderation_flags_user_id_idx
  on public.moderation_flags (user_id);

-- -----------------------------------------------------------------------------
-- RLS placeholders / notes
-- -----------------------------------------------------------------------------
-- Enable row level security first, then add the final policies during the real
-- backend migration. These tables are kept draft-only for now:
-- profiles, user_preferences, activities, activity_participants, chats,
-- chat_messages, saved_activities, feedback, reports, blocked_users,
-- notifications, moderation_flags.
--
-- Draft posture:
--   1. enable RLS on each table
--   2. add read/write policies per feature
--   3. keep mock/local code paths intact until each module is migrated

alter table public.profiles enable row level security;
alter table public.user_preferences enable row level security;
alter table public.activities enable row level security;
alter table public.activity_participants enable row level security;
alter table public.chats enable row level security;
alter table public.chat_messages enable row level security;
alter table public.saved_activities enable row level security;
alter table public.feedback enable row level security;
alter table public.reports enable row level security;
alter table public.blocked_users enable row level security;
alter table public.notifications enable row level security;
alter table public.moderation_flags enable row level security;

-- Example placeholders for later policy work:
-- create policy "profiles_read_own" on public.profiles for select using (auth.uid() = id);
-- create policy "profiles_update_own" on public.profiles for update using (auth.uid() = id);
-- create policy "activities_read_public" on public.activities for select using (...);
