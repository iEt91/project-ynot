do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'users'
      and column_name = 'bio'
  ) then
    alter table public.users
      add column bio text not null default '';
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from information_schema.columns
    where table_schema = 'public'
      and table_name = 'activities'
      and column_name = 'visibility'
  ) then
    alter table public.activities
      add column visibility text not null default 'PUBLIC';
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'activities_visibility_check'
  ) then
    alter table public.activities
      add constraint activities_visibility_check
      check (visibility in ('PUBLIC', 'PRIVATE'));
  end if;
end
$$;

create unique index if not exists activity_chats_activity_id_unique_idx
  on public.activity_chats(activity_id);

create or replace function public.app_ensure_user(
  p_client_uid uuid,
  p_phone_last4 text default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  insert into public.users (
    auth_uid,
    phone_last4,
    nickname,
    avatar_emoji,
    bio,
    status,
    trust_score
  )
  values (
    p_client_uid,
    coalesce(nullif(p_phone_last4, ''), ''),
    '',
    '🌙',
    '',
    'NEW',
    0
  )
  on conflict (auth_uid) do update
    set last_active_at = now(),
        phone_last4 = coalesce(nullif(excluded.phone_last4, ''), public.users.phone_last4),
        updated_at = now()
  returning id into v_user_id;

  insert into public.user_preferences (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  return v_user_id;
end;
$$;

create or replace function public.app_upsert_profile(
  p_client_uid uuid,
  p_phone_last4 text default null,
  p_nickname text default '',
  p_avatar_emoji text default '🌙',
  p_avatar_url text default null,
  p_bio text default '',
  p_languages text[] default '{}'::text[],
  p_vibes text[] default '{}'::text[],
  p_interests text[] default '{}'::text[]
)
returns table (
  id uuid,
  auth_uid uuid,
  phone_last4 text,
  nickname text,
  avatar_url text,
  avatar_emoji text,
  bio text,
  languages text[],
  vibes text[],
  interests text[],
  status user_status,
  created_at timestamptz,
  updated_at timestamptz,
  last_active_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, p_phone_last4);

  update public.users
  set nickname = coalesce(nullif(p_nickname, ''), nickname),
      avatar_emoji = coalesce(nullif(p_avatar_emoji, ''), avatar_emoji),
      avatar_url = coalesce(p_avatar_url, avatar_url),
      bio = coalesce(p_bio, bio),
      status = case
        when coalesce(nullif(p_nickname, ''), nickname) <> '' then 'TRUSTED'
        else status
      end,
      updated_at = now(),
      last_active_at = now()
  where id = v_user_id
  ;

  insert into public.user_preferences (
    user_id,
    languages,
    vibes,
    interests,
    updated_at
  )
  values (
    v_user_id,
    coalesce(p_languages, '{}'::text[]),
    coalesce(p_vibes, '{}'::text[]),
    coalesce(p_interests, '{}'::text[]),
    now()
  )
  on conflict (user_id) do update
    set languages = excluded.languages,
        vibes = excluded.vibes,
        interests = excluded.interests,
        updated_at = now();

  return query
    select
      u.id,
      u.auth_uid,
      coalesce(u.phone_last4, '') as phone_last4,
      u.nickname,
      u.avatar_url,
      coalesce(u.avatar_emoji, '🌙') as avatar_emoji,
      coalesce(u.bio, '') as bio,
      coalesce(p.languages, '{}'::text[]) as languages,
      coalesce(p.vibes, '{}'::text[]) as vibes,
      coalesce(p.interests, '{}'::text[]) as interests,
      u.status,
      u.created_at,
      u.updated_at,
      u.last_active_at
    from public.users u
    left join public.user_preferences p on p.user_id = u.id
    where u.id = v_user_id;
end;
$$;

create or replace function public.app_get_profile(
  p_client_uid uuid
)
returns table (
  id uuid,
  auth_uid uuid,
  phone_last4 text,
  nickname text,
  avatar_url text,
  avatar_emoji text,
  bio text,
  languages text[],
  vibes text[],
  interests text[],
  status user_status,
  profile_complete boolean,
  created_activity_count int,
  attending_activity_count int,
  created_at timestamptz,
  updated_at timestamptz,
  last_active_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  return query
    select
      u.id,
      u.auth_uid,
      coalesce(u.phone_last4, '') as phone_last4,
      u.nickname,
      u.avatar_url,
      coalesce(u.avatar_emoji, '🌙') as avatar_emoji,
      coalesce(u.bio, '') as bio,
      coalesce(p.languages, '{}'::text[]) as languages,
      coalesce(p.vibes, '{}'::text[]) as vibes,
      coalesce(p.interests, '{}'::text[]) as interests,
      u.status,
      (trim(coalesce(u.nickname, '')) <> '') as profile_complete,
      coalesce((
        select count(*)::int
        from public.activities a
        where a.creator_id = u.id
          and a.deleted_at is null
      ), 0) as created_activity_count,
      coalesce((
        select count(*)::int
        from public.activity_participants ap
        where ap.user_id = u.id
          and ap.status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED')
      ), 0) as attending_activity_count,
      u.created_at,
      u.updated_at,
      u.last_active_at
    from public.users u
    left join public.user_preferences p on p.user_id = u.id
    where u.id = v_user_id;
end;
$$;

create or replace function public.app_list_activities(
  p_client_uid uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  return query
    select
      a.id,
      coalesce(nullif(creator.nickname, ''), case when a.creator_id = v_user_id then 'Tú' else 'Anónimo' end) as creator_label,
      a.activity_type::text,
      a.visibility,
      a.title,
      a.description,
      a.category,
      a.vibe,
      a.zone,
      a.status::text,
      a.real_lat,
      a.real_lng,
      a.display_lat,
      a.display_lng,
      a.location_privacy_radius_m,
      a.exact_location_unlock_at,
      a.start_time,
      a.end_time,
      a.max_people,
      coalesce(counts.confirmed_count, 0) as confirmed_count,
      coalesce(counts.pending_count, 0) as pending_count,
      me.my_status,
      (a.creator_id = v_user_id) as is_mine,
      coalesce(latest.last_message_preview, '') as last_message_preview,
      latest.last_message_at
    from public.activities a
    left join public.users creator on creator.id = a.creator_id
    left join lateral (
      select
        count(*) filter (where ap.status = 'CONFIRMED')::int as confirmed_count,
        count(*) filter (where ap.status = 'JOINED_PENDING_CONFIRMATION')::int as pending_count
      from public.activity_participants ap
      where ap.activity_id = a.id
    ) counts on true
    left join lateral (
      select ap.status::text as my_status
      from public.activity_participants ap
      where ap.activity_id = a.id
        and ap.user_id = v_user_id
      limit 1
    ) me on true
    left join lateral (
      select
        m.content as last_message_preview,
        m.created_at as last_message_at
      from public.messages m
      join public.activity_chats ch on ch.id = m.chat_id
      where ch.activity_id = a.id
        and m.deleted_at is null
      order by m.created_at desc
      limit 1
    ) latest on true
    where a.deleted_at is null
      and a.status in ('ACTIVE', 'FULL', 'ONGOING')
      and (
        a.visibility = 'PUBLIC'
        or a.creator_id = v_user_id
        or exists (
          select 1
          from public.activity_participants ap
          where ap.activity_id = a.id
            and ap.user_id = v_user_id
            and ap.status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED')
        )
      )
    order by a.start_time asc;
end;
$$;

create or replace function public.app_get_activity(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  return query
    select
      a.id,
      coalesce(nullif(creator.nickname, ''), case when a.creator_id = v_user_id then 'Tú' else 'Anónimo' end) as creator_label,
      a.activity_type::text,
      a.visibility,
      a.title,
      a.description,
      a.category,
      a.vibe,
      a.zone,
      a.status::text,
      a.real_lat,
      a.real_lng,
      a.display_lat,
      a.display_lng,
      a.location_privacy_radius_m,
      a.exact_location_unlock_at,
      a.start_time,
      a.end_time,
      a.max_people,
      coalesce(counts.confirmed_count, 0) as confirmed_count,
      coalesce(counts.pending_count, 0) as pending_count,
      me.my_status,
      (a.creator_id = v_user_id) as is_mine,
      coalesce(latest.last_message_preview, '') as last_message_preview,
      latest.last_message_at
    from public.activities a
    left join public.users creator on creator.id = a.creator_id
    left join lateral (
      select
        count(*) filter (where ap.status = 'CONFIRMED')::int as confirmed_count,
        count(*) filter (where ap.status = 'JOINED_PENDING_CONFIRMATION')::int as pending_count
      from public.activity_participants ap
      where ap.activity_id = a.id
    ) counts on true
    left join lateral (
      select ap.status::text as my_status
      from public.activity_participants ap
      where ap.activity_id = a.id
        and ap.user_id = v_user_id
      limit 1
    ) me on true
    left join lateral (
      select
        m.content as last_message_preview,
        m.created_at as last_message_at
      from public.messages m
      join public.activity_chats ch on ch.id = m.chat_id
      where ch.activity_id = a.id
        and m.deleted_at is null
      order by m.created_at desc
      limit 1
    ) latest on true
    where a.deleted_at is null
      and a.id = p_activity_id
      and (
        a.visibility = 'PUBLIC'
        or a.creator_id = v_user_id
        or exists (
          select 1
          from public.activity_participants ap
          where ap.activity_id = a.id
            and ap.user_id = v_user_id
        )
      );
end;
$$;

create or replace function public.app_create_activity(
  p_client_uid uuid,
  p_title text,
  p_description text,
  p_category text,
  p_vibe text,
  p_zone text,
  p_start_time timestamptz,
  p_duration_minutes int,
  p_max_people int,
  p_real_lat numeric,
  p_real_lng numeric,
  p_display_lat numeric,
  p_display_lng numeric,
  p_visibility text default 'PUBLIC'
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_activity_id uuid;
  v_end_time timestamptz;
  v_unlock_at timestamptz;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);
  v_end_time := p_start_time + make_interval(mins => p_duration_minutes);
  v_unlock_at := p_start_time - interval '10 minutes';

  insert into public.activities (
    creator_id,
    activity_type,
    visibility,
    title,
    description,
    category,
    vibe,
    zone,
    status,
    real_lat,
    real_lng,
    display_lat,
    display_lng,
    location_privacy_radius_m,
    exact_location_unlock_at,
    start_time,
    end_time,
    max_people,
    moderation_status,
    moderation_reason
  )
  values (
    v_user_id,
    'USER_ACTIVITY',
    upper(coalesce(p_visibility, 'PUBLIC')),
    p_title,
    coalesce(p_description, ''),
    p_category,
    p_vibe,
    p_zone,
    'ACTIVE',
    p_real_lat,
    p_real_lng,
    p_display_lat,
    p_display_lng,
    100,
    v_unlock_at,
    p_start_time,
    v_end_time,
    p_max_people,
    'CLEAN',
    null
  )
  returning id into v_activity_id;

  insert into public.activity_chats (
    activity_id,
    chat_index,
    max_members,
    status,
    visible_until,
    retain_until
  )
  values (
    v_activity_id,
    0,
    20,
    'ACTIVE',
    v_end_time + interval '2 hours',
    now() + interval '1 year'
  )
  on conflict (activity_id) do update
    set visible_until = excluded.visible_until,
        retain_until = excluded.retain_until,
        updated_at = now();

  insert into public.activity_participants (
    activity_id,
    user_id,
    status,
    joined_at,
    confirmation_requested_at,
    confirmed_at
  )
  values (
    v_activity_id,
    v_user_id,
    'CONFIRMED',
    now(),
    now(),
    now()
  )
  on conflict (activity_id, user_id) do update
    set status = 'CONFIRMED',
        joined_at = now(),
        confirmation_requested_at = now(),
        confirmed_at = now(),
        left_at = null,
        updated_at = now();

  insert into public.chat_members (
    chat_id,
    user_id,
    muted,
    joined_at,
    left_at
  )
  select
    ch.id,
    v_user_id,
    false,
    now(),
    null
  from public.activity_chats ch
  where ch.activity_id = v_activity_id
  on conflict (chat_id, user_id) do update
    set left_at = null,
        joined_at = now(),
        muted = false;

  return query
    select * from public.app_get_activity(p_client_uid, v_activity_id);
end;
$$;

create or replace function public.app_join_activity(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_user_status user_status;
  v_activity_status activity_status;
  v_confirmed_count int;
  v_visibility text;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  select status into v_user_status
  from public.users
  where id = v_user_id;

  select status, visibility into v_activity_status, v_visibility
  from public.activities
  where id = p_activity_id
    and deleted_at is null;

  if v_user_status in ('LIMITED', 'BANNED') then
    return query select * from public.app_get_activity(p_client_uid, p_activity_id);
    return;
  end if;

  if v_activity_status in ('FINISHED', 'CANCELLED', 'REMOVED', 'REJECTED_HIDDEN') then
    return query select * from public.app_get_activity(p_client_uid, p_activity_id);
    return;
  end if;

  select count(*)::int into v_confirmed_count
  from public.activity_participants
  where activity_id = p_activity_id
    and status = 'CONFIRMED';

  if v_confirmed_count >= (
    select max_people
    from public.activities
    where id = p_activity_id
  ) then
    update public.activities
    set status = 'FULL',
        updated_at = now()
    where id = p_activity_id
      and status <> 'FULL';
    return query select * from public.app_get_activity(p_client_uid, p_activity_id);
    return;
  end if;

  insert into public.activity_participants (
    activity_id,
    user_id,
    status,
    joined_at,
    confirmation_requested_at,
    left_at,
    confirmed_at
  )
  values (
    p_activity_id,
    v_user_id,
    'JOINED_PENDING_CONFIRMATION',
    now(),
    case
      when (select start_time from public.activities where id = p_activity_id) - now() < interval '60 minutes'
        then now()
      else now() + interval '15 minutes'
    end,
    null,
    null
  )
  on conflict (activity_id, user_id) do update
    set status = 'JOINED_PENDING_CONFIRMATION',
        joined_at = now(),
        confirmation_requested_at = case
          when (select start_time from public.activities where id = p_activity_id) - now() < interval '60 minutes'
            then now()
          else now() + interval '15 minutes'
        end,
        left_at = null,
        confirmed_at = null,
        updated_at = now();

  insert into public.chat_members (
    chat_id,
    user_id,
    muted,
    joined_at,
    left_at
  )
  select
    ch.id,
    v_user_id,
    false,
    now(),
    null
  from public.activity_chats ch
  where ch.activity_id = p_activity_id
  on conflict (chat_id, user_id) do update
    set left_at = null,
        joined_at = now(),
        muted = false;

  return query select * from public.app_get_activity(p_client_uid, p_activity_id);
end;
$$;

create or replace function public.app_confirm_attendance(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  update public.activity_participants
  set status = 'CONFIRMED',
      confirmed_at = now(),
      updated_at = now()
  where activity_id = p_activity_id
    and user_id = v_user_id
    and status in ('JOINED_PENDING_CONFIRMATION', 'CANCELLED', 'LEFT');

  update public.activities
  set status = case
    when (
      select count(*)::int
      from public.activity_participants ap
      where ap.activity_id = p_activity_id
        and ap.status = 'CONFIRMED'
    ) >= max_people then 'FULL'
    else 'ACTIVE'
  end,
  updated_at = now()
  where id = p_activity_id;

  return query select * from public.app_get_activity(p_client_uid, p_activity_id);
end;
$$;

create or replace function public.app_cancel_attendance(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  update public.activity_participants
  set status = 'CANCELLED',
      left_at = now(),
      updated_at = now()
  where activity_id = p_activity_id
    and user_id = v_user_id
    and status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED');

  update public.activities
  set status = case
    when (
      select count(*)::int
      from public.activity_participants ap
      where ap.activity_id = p_activity_id
        and ap.status = 'CONFIRMED'
    ) >= max_people then 'FULL'
    else 'ACTIVE'
  end,
  updated_at = now()
  where id = p_activity_id;

  return query select * from public.app_get_activity(p_client_uid, p_activity_id);
end;
$$;

create or replace function public.app_leave_activity(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  creator_label text,
  activity_type text,
  visibility text,
  title text,
  description text,
  category text,
  vibe text,
  zone text,
  status text,
  real_lat numeric,
  real_lng numeric,
  display_lat numeric,
  display_lng numeric,
  location_privacy_radius_m int,
  exact_location_unlock_at timestamptz,
  start_time timestamptz,
  end_time timestamptz,
  max_people int,
  confirmed_count int,
  pending_count int,
  my_status text,
  is_mine boolean,
  last_message_preview text,
  last_message_at timestamptz
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  update public.activity_participants
  set status = 'LEFT',
      left_at = now(),
      updated_at = now()
  where activity_id = p_activity_id
    and user_id = v_user_id
    and status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED', 'CANCELLED');

  update public.activities
  set status = case
    when (
      select count(*)::int
      from public.activity_participants ap
      where ap.activity_id = p_activity_id
        and ap.status = 'CONFIRMED'
    ) >= max_people then 'FULL'
    else 'ACTIVE'
  end,
  updated_at = now()
  where id = p_activity_id;

  return query select * from public.app_get_activity(p_client_uid, p_activity_id);
end;
$$;

create or replace function public.app_ensure_chat(
  p_client_uid uuid,
  p_activity_id uuid
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_chat_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  select ch.id into v_chat_id
  from public.activity_chats ch
  where ch.activity_id = p_activity_id
  order by ch.created_at asc
  limit 1;

  if v_chat_id is null then
    insert into public.activity_chats (
      activity_id,
      chat_index,
      max_members,
      status,
      visible_until,
      retain_until
    )
    values (
      p_activity_id,
      0,
      20,
      'ACTIVE',
      now() + interval '2 hours',
      now() + interval '1 year'
    )
    returning id into v_chat_id;
  end if;

  if not exists (
    select 1
    from public.activity_participants ap
    where ap.activity_id = p_activity_id
      and ap.user_id = v_user_id
      and ap.status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED')
  ) and not exists (
    select 1
    from public.activities a
    where a.id = p_activity_id
      and a.creator_id = v_user_id
  ) then
    return null;
  end if;

  insert into public.chat_members (
    chat_id,
    user_id,
    muted,
    joined_at,
    left_at
  )
  values (
    v_chat_id,
    v_user_id,
    false,
    now(),
    null
  )
  on conflict (chat_id, user_id) do update
    set left_at = null,
        joined_at = now(),
        muted = false;

  return v_chat_id;
end;
$$;

create or replace function public.app_get_messages(
  p_client_uid uuid,
  p_activity_id uuid
)
returns table (
  id uuid,
  chat_id uuid,
  activity_id uuid,
  sender_id uuid,
  sender_name text,
  sender_emoji text,
  content text,
  created_at timestamptz,
  is_me boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_chat_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  select ch.id into v_chat_id
  from public.activity_chats ch
  where ch.activity_id = p_activity_id
  order by ch.created_at asc
  limit 1;

  if v_chat_id is null then
    insert into public.activity_chats (
      activity_id,
      chat_index,
      max_members,
      status,
      visible_until,
      retain_until
    )
    values (
      p_activity_id,
      0,
      20,
      'ACTIVE',
      now() + interval '2 hours',
      now() + interval '1 year'
    )
    returning id into v_chat_id;
  end if;

  if not exists (
    select 1
    from public.activity_participants ap
    where ap.activity_id = p_activity_id
      and ap.user_id = v_user_id
      and ap.status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED')
  ) and not exists (
    select 1
    from public.activities a
    where a.id = p_activity_id
      and a.creator_id = v_user_id
  ) then
    return;
  end if;

  insert into public.chat_members (
    chat_id,
    user_id,
    muted,
    joined_at,
    left_at
  )
  values (
    v_chat_id,
    v_user_id,
    false,
    now(),
    null
  )
  on conflict (chat_id, user_id) do update
    set left_at = null,
        joined_at = now();

  return query
    select
      m.id,
      m.chat_id,
      p_activity_id as activity_id,
      m.sender_id,
      coalesce(nullif(sender.nickname, ''), 'Usuario') as sender_name,
      coalesce(nullif(sender.avatar_emoji, ''), '🌙') as sender_emoji,
      m.content,
      m.created_at,
      (m.sender_id = v_user_id) as is_me
    from public.messages m
    join public.users sender on sender.id = m.sender_id
    where m.chat_id = v_chat_id
      and m.deleted_at is null
    order by m.created_at asc;
end;
$$;

create or replace function public.app_send_message(
  p_client_uid uuid,
  p_activity_id uuid,
  p_content text
)
returns table (
  id uuid,
  chat_id uuid,
  activity_id uuid,
  sender_id uuid,
  sender_name text,
  sender_emoji text,
  content text,
  created_at timestamptz,
  is_me boolean
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_chat_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  select ch.id into v_chat_id
  from public.activity_chats ch
  where ch.activity_id = p_activity_id
  order by ch.created_at asc
  limit 1;

  if v_chat_id is null then
    insert into public.activity_chats (
      activity_id,
      chat_index,
      max_members,
      status,
      visible_until,
      retain_until
    )
    values (
      p_activity_id,
      0,
      20,
      'ACTIVE',
      now() + interval '2 hours',
      now() + interval '1 year'
    )
    returning id into v_chat_id;
  end if;

  if not exists (
    select 1
    from public.activity_participants ap
    where ap.activity_id = p_activity_id
      and ap.user_id = v_user_id
      and ap.status in ('JOINED_PENDING_CONFIRMATION', 'CONFIRMED')
  ) and not exists (
    select 1
    from public.activities a
    where a.id = p_activity_id
      and a.creator_id = v_user_id
  ) then
    raise exception 'not_allowed';
  end if;

  insert into public.chat_members (
    chat_id,
    user_id,
    muted,
    joined_at,
    left_at
  )
  values (
    v_chat_id,
    v_user_id,
    false,
    now(),
    null
  )
  on conflict (chat_id, user_id) do update
    set left_at = null,
        joined_at = now();

  return query
    with inserted as (
      insert into public.messages (
        chat_id,
        sender_id,
        content,
        moderation_status,
        flagged,
        hidden
      )
      values (
        v_chat_id,
        v_user_id,
        p_content,
        'CLEAN',
        false,
        false
      )
      returning *
    )
    select
      i.id,
      i.chat_id,
      p_activity_id as activity_id,
      i.sender_id,
      coalesce(nullif(sender.nickname, ''), 'Usuario') as sender_name,
      coalesce(nullif(sender.avatar_emoji, ''), '🌙') as sender_emoji,
      i.content,
      i.created_at,
      true as is_me
    from inserted i
    join public.users sender on sender.id = i.sender_id;
end;
$$;

create or replace function public.app_report_message(
  p_client_uid uuid,
  p_message_id uuid,
  p_chat_id uuid,
  p_activity_id uuid,
  p_sender_id uuid,
  p_reason text,
  p_details text default null,
  p_content text default null,
  p_timestamp timestamptz default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_report_id uuid;
begin
  v_user_id := public.app_ensure_user(p_client_uid, null);

  insert into public.reports (
    reporter_id,
    target_user_id,
    activity_id,
    chat_id,
    message_id,
    reason,
    details,
    status
  )
  values (
    v_user_id,
    p_sender_id,
    p_activity_id,
    p_chat_id,
    p_message_id,
    p_reason,
    coalesce(p_details, p_content),
    'PENDING'
  )
  returning id into v_report_id;

  insert into public.moderation_flags (
    user_id,
    activity_id,
    message_id,
    flag_type,
    severity,
    source
  )
  values (
    p_sender_id,
    p_activity_id,
    p_message_id,
    'MESSAGE_REPORTED',
    1,
    'USER_REPORT'
  );

  return v_report_id;
end;
$$;

grant execute on function public.app_ensure_user(uuid, text) to anon, authenticated;
grant execute on function public.app_ensure_chat(uuid, uuid) to anon, authenticated;
grant execute on function public.app_upsert_profile(uuid, text, text, text, text, text, text[], text[], text[]) to anon, authenticated;
grant execute on function public.app_get_profile(uuid) to anon, authenticated;
grant execute on function public.app_list_activities(uuid) to anon, authenticated;
grant execute on function public.app_get_activity(uuid, uuid) to anon, authenticated;
grant execute on function public.app_create_activity(uuid, text, text, text, text, text, timestamptz, int, int, numeric, numeric, numeric, numeric, text) to anon, authenticated;
grant execute on function public.app_join_activity(uuid, uuid) to anon, authenticated;
grant execute on function public.app_confirm_attendance(uuid, uuid) to anon, authenticated;
grant execute on function public.app_cancel_attendance(uuid, uuid) to anon, authenticated;
grant execute on function public.app_leave_activity(uuid, uuid) to anon, authenticated;
grant execute on function public.app_get_messages(uuid, uuid) to anon, authenticated;
grant execute on function public.app_send_message(uuid, uuid, text) to anon, authenticated;
grant execute on function public.app_report_message(uuid, uuid, uuid, uuid, uuid, text, text, text, timestamptz) to anon, authenticated;

