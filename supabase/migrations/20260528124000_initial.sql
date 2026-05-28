create extension if not exists "pgcrypto";

create type user_status as enum (
  'NEW',
  'TRUSTED',
  'WATCHLIST',
  'LIMITED',
  'SHADOWBANNED',
  'BANNED'
);

create type activity_status as enum (
  'DRAFT',
  'PENDING_MODERATION',
  'ACTIVE',
  'FULL',
  'ONGOING',
  'FINISHED',
  'CANCELLED',
  'FLAGGED',
  'REMOVED',
  'REJECTED_HIDDEN'
);

create type participant_status as enum (
  'JOINED_PENDING_CONFIRMATION',
  'CONFIRMED',
  'LEFT',
  'CANCELLED',
  'ATTENDED',
  'NO_SHOW',
  'NOT_SURE',
  'REMOVED_BY_ADMIN'
);

create type moderation_status as enum (
  'CLEAN',
  'FLAGGED',
  'REVIEW_REQUIRED',
  'HIDDEN',
  'REMOVED'
);

create type activity_type as enum (
  'USER_ACTIVITY',
  'PUBLIC_EVENT'
);

create type report_status as enum (
  'PENDING',
  'REVIEWED',
  'RESOLVED',
  'DISMISSED'
);

create type admin_role as enum (
  'SUPER_ADMIN',
  'MODERATOR',
  'ANALYST'
);

create or replace function public.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function public.is_admin()
returns boolean
language sql
stable
as $$
  select exists (
    select 1
    from public.admin_users au
    where au.user_id = auth.uid()
  );
$$;

create table public.users (
  id uuid primary key default gen_random_uuid(),
  auth_uid uuid unique,
  phone_hash text,
  phone_last4 text,
  nickname text not null default '',
  avatar_url text,
  avatar_emoji text,
  status user_status not null default 'NEW',
  trust_score numeric(5,2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  last_active_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.user_preferences (
  user_id uuid primary key references public.users(id) on delete cascade,
  interests text[] not null default '{}',
  vibes text[] not null default '{}',
  languages text[] not null default '{}',
  preferred_group_min int not null default 2,
  preferred_group_max int not null default 4,
  preferred_times text[] not null default '{}',
  preferred_radius_km numeric(4,1) not null default 3.0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  creator_id uuid references public.users(id) on delete set null,
  activity_type activity_type not null default 'USER_ACTIVITY',
  title text not null,
  description text not null default '',
  category text not null,
  vibe text not null,
  status activity_status not null default 'DRAFT',
  real_lat numeric(9,6) not null,
  real_lng numeric(9,6) not null,
  display_lat numeric(9,6) not null,
  display_lng numeric(9,6) not null,
  location_privacy_radius_m int not null default 100,
  exact_location_unlock_at timestamptz not null,
  start_time timestamptz not null,
  end_time timestamptz not null,
  max_people int not null check (max_people between 2 and 50),
  moderation_status moderation_status not null default 'CLEAN',
  moderation_reason text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.activity_participants (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  status participant_status not null default 'JOINED_PENDING_CONFIRMATION',
  joined_at timestamptz not null default now(),
  confirmation_requested_at timestamptz,
  confirmed_at timestamptz,
  left_at timestamptz,
  attended_status participant_status,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique(activity_id, user_id)
);

create table public.activity_chats (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  chat_index int not null default 0,
  max_members int not null default 20,
  status text not null default 'ACTIVE',
  visible_until timestamptz not null,
  retain_until timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create table public.chat_members (
  chat_id uuid not null references public.activity_chats(id) on delete cascade,
  user_id uuid not null references public.users(id) on delete cascade,
  muted boolean not null default false,
  joined_at timestamptz not null default now(),
  left_at timestamptz,
  primary key (chat_id, user_id)
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  chat_id uuid not null references public.activity_chats(id) on delete cascade,
  sender_id uuid not null references public.users(id) on delete cascade,
  content text not null,
  created_at timestamptz not null default now(),
  moderation_status moderation_status not null default 'CLEAN',
  flagged boolean not null default false,
  hidden boolean not null default false,
  deleted_at timestamptz
);

create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.users(id) on delete cascade,
  target_user_id uuid references public.users(id) on delete cascade,
  activity_id uuid references public.activities(id) on delete cascade,
  chat_id uuid references public.activity_chats(id) on delete cascade,
  message_id uuid references public.messages(id) on delete cascade,
  reason text not null,
  details text,
  status report_status not null default 'PENDING',
  created_at timestamptz not null default now(),
  resolved_at timestamptz,
  resolved_by_admin_id uuid,
  deleted_at timestamptz
);

create table public.feedback (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities(id) on delete cascade,
  reviewer_id uuid not null references public.users(id) on delete cascade,
  target_user_id uuid references public.users(id) on delete cascade,
  vibe_rating text not null,
  attended_status participant_status,
  would_join_again text,
  comment text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.moderation_flags (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  activity_id uuid references public.activities(id) on delete cascade,
  message_id uuid references public.messages(id) on delete cascade,
  flag_type text not null,
  severity int not null default 1,
  source text not null,
  created_at timestamptz not null default now()
);

create table public.admin_users (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references public.users(id) on delete cascade,
  role admin_role not null default 'MODERATOR',
  created_at timestamptz not null default now()
);

create table public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  admin_id uuid not null references public.admin_users(id) on delete cascade,
  action text not null,
  target_type text not null,
  target_id uuid not null,
  reason text,
  created_at timestamptz not null default now()
);

create table public.analytics_events (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists activities_start_time_idx on public.activities(start_time);
create index if not exists activities_status_idx on public.activities(status);
create index if not exists activities_category_idx on public.activities(category);
create index if not exists activities_display_lat_lng_idx on public.activities(display_lat, display_lng);
create index if not exists activity_participants_user_id_idx on public.activity_participants(user_id);
create index if not exists activity_participants_activity_id_idx on public.activity_participants(activity_id);
create index if not exists messages_chat_id_created_at_idx on public.messages(chat_id, created_at);
create index if not exists reports_status_idx on public.reports(status);
create index if not exists moderation_flags_created_at_idx on public.moderation_flags(created_at);
create index if not exists analytics_events_event_name_idx on public.analytics_events(event_name);

create trigger touch_users_updated_at
before update on public.users
for each row execute function public.touch_updated_at();

create trigger touch_user_preferences_updated_at
before update on public.user_preferences
for each row execute function public.touch_updated_at();

create trigger touch_activities_updated_at
before update on public.activities
for each row execute function public.touch_updated_at();

create trigger touch_activity_participants_updated_at
before update on public.activity_participants
for each row execute function public.touch_updated_at();

create trigger touch_activity_chats_updated_at
before update on public.activity_chats
for each row execute function public.touch_updated_at();

create trigger touch_feedback_updated_at
before update on public.feedback
for each row execute function public.touch_updated_at();

alter table public.users enable row level security;
alter table public.user_preferences enable row level security;
alter table public.activities enable row level security;
alter table public.activity_participants enable row level security;
alter table public.activity_chats enable row level security;
alter table public.chat_members enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;
alter table public.feedback enable row level security;
alter table public.moderation_flags enable row level security;
alter table public.admin_users enable row level security;
alter table public.admin_audit_logs enable row level security;
alter table public.analytics_events enable row level security;

create policy "users_can_read_own_profile"
on public.users
for select
using (auth.uid() = auth_uid or public.is_admin());

create policy "users_can_update_own_profile"
on public.users
for update
using (auth.uid() = auth_uid or public.is_admin())
with check (auth.uid() = auth_uid or public.is_admin());

create policy "users_can_read_own_preferences"
on public.user_preferences
for select
using (
  exists (
    select 1 from public.users u
    where u.id = user_id and (u.auth_uid = auth.uid() or public.is_admin())
  )
);

create policy "users_can_write_own_preferences"
on public.user_preferences
for all
using (
  exists (
    select 1 from public.users u
    where u.id = user_id and (u.auth_uid = auth.uid() or public.is_admin())
  )
)
with check (
  exists (
    select 1 from public.users u
    where u.id = user_id and (u.auth_uid = auth.uid() or public.is_admin())
  )
);

create policy "activities_are_visible_to_signed_in_users"
on public.activities
for select
using (
  public.is_admin()
  or status in ('ACTIVE', 'FULL', 'ONGOING', 'FINISHED')
);

create policy "creators_can_insert_activities"
on public.activities
for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = creator_id and u.auth_uid = auth.uid()
  )
);

create policy "creators_can_update_their_activities"
on public.activities
for update
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = creator_id and u.auth_uid = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = creator_id and u.auth_uid = auth.uid()
  )
);

create policy "participants_can_read_their_rows"
on public.activity_participants
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
  or exists (
    select 1
    from public.activities a
    join public.users u on u.id = a.creator_id
    where a.id = activity_id and u.auth_uid = auth.uid()
  )
);

create policy "participants_can_insert_their_rows"
on public.activity_participants
for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
);

create policy "participants_can_update_their_rows"
on public.activity_participants
for update
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
);

create policy "chat_members_can_read_rows"
on public.chat_members
for select
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
);

create policy "chat_members_can_join_rows"
on public.chat_members
for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
);

create policy "chat_members_can_update_rows"
on public.chat_members
for update
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
)
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = user_id and u.auth_uid = auth.uid()
  )
);

create policy "members_can_read_messages"
on public.messages
for select
using (
  public.is_admin()
  or exists (
    select 1
    from public.chat_members cm
    join public.users u on u.id = cm.user_id
    where cm.chat_id = messages.chat_id and u.auth_uid = auth.uid()
  )
);

create policy "members_can_insert_messages"
on public.messages
for insert
with check (
  public.is_admin()
  or exists (
    select 1
    from public.chat_members cm
    join public.users u on u.id = cm.user_id
    where cm.chat_id = messages.chat_id and u.auth_uid = auth.uid()
  )
);

create policy "users_can_read_own_reports"
on public.reports
for select
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = reporter_id and u.auth_uid = auth.uid()
  )
);

create policy "users_can_create_reports"
on public.reports
for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = reporter_id and u.auth_uid = auth.uid()
  )
);

create policy "users_can_read_own_feedback"
on public.feedback
for select
using (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = reviewer_id and u.auth_uid = auth.uid()
  )
);

create policy "users_can_create_feedback"
on public.feedback
for insert
with check (
  public.is_admin()
  or exists (
    select 1 from public.users u
    where u.id = reviewer_id and u.auth_uid = auth.uid()
  )
);

create policy "flags_admin_only"
on public.moderation_flags
for select
using (public.is_admin());

create policy "flags_system_and_admin_only"
on public.moderation_flags
for insert
with check (public.is_admin());

create policy "admin_users_admin_only"
on public.admin_users
for select
using (public.is_admin());

create policy "admin_audit_logs_admin_only"
on public.admin_audit_logs
for select
using (public.is_admin());

create policy "analytics_admin_only"
on public.analytics_events
for select
using (public.is_admin());

create policy "analytics_insert_authenticated"
on public.analytics_events
for insert
with check (auth.uid() is not null);
