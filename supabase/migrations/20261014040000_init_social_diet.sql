-- Social Diet schema. Tables first, then helpers, then RLS.
-- Security-definer helpers live in an unexposed private schema.

create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text not null unique,
  display_name text not null default '',
  bio text not null default '',
  daily_calorie_goal integer not null default 2000
    check (daily_calorie_goal between 800 and 8000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint username_format check (username ~ '^[a-z0-9_]{3,24}$')
);

create index profiles_username_idx on public.profiles (username);

create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles (id) on delete cascade,
  addressee_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  constraint friendship_not_self check (requester_id <> addressee_id)
);

create unique index friendships_unique_pair
  on public.friendships (least(requester_id, addressee_id), greatest(requester_id, addressee_id));
create index friendships_addressee_status_idx on public.friendships (addressee_id, status);
create index friendships_requester_status_idx on public.friendships (requester_id, status);

create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  direct_pair text unique,
  created_at timestamptz not null default now()
);

create table public.conversation_members (
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  last_read_at timestamptz,
  joined_at timestamptz not null default now(),
  primary key (conversation_id, user_id)
);

create index conversation_members_user_idx on public.conversation_members (user_id);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 4000),
  created_at timestamptz not null default now()
);

create index messages_conversation_created_idx on public.messages (conversation_id, created_at desc);

create table public.feed_posts (
  id uuid primary key default gen_random_uuid(),
  author_id uuid not null references public.profiles (id) on delete cascade,
  body text not null default '',
  kind text not null default 'status'
    check (kind in ('status', 'workout', 'meal', 'tracker', 'achievement')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index feed_posts_author_created_idx on public.feed_posts (author_id, created_at desc);

create table public.feed_likes (
  post_id uuid not null references public.feed_posts (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (post_id, user_id)
);

create index feed_likes_user_idx on public.feed_likes (user_id);

create table public.food_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  name text not null,
  calories integer not null default 0 check (calories >= 0),
  protein_g numeric(8, 1) not null default 0 check (protein_g >= 0),
  carbs_g numeric(8, 1) not null default 0 check (carbs_g >= 0),
  fat_g numeric(8, 1) not null default 0 check (fat_g >= 0),
  meal_type text not null default 'snack'
    check (meal_type in ('breakfast', 'lunch', 'dinner', 'snack')),
  logged_at timestamptz not null default now(),
  notes text not null default ''
);

create index food_logs_user_logged_idx on public.food_logs (user_id, logged_at desc);

create table public.workouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  category text not null default 'other'
    check (category in ('strength', 'cardio', 'flexibility', 'sports', 'other')),
  duration_minutes integer not null default 0 check (duration_minutes >= 0),
  calories_burned integer not null default 0 check (calories_burned >= 0),
  notes text not null default '',
  logged_at timestamptz not null default now()
);

create index workouts_user_logged_idx on public.workouts (user_id, logged_at desc);

create table public.trackers (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references public.profiles (id) on delete cascade,
  title text not null,
  description text not null default '',
  icon text not null default 'flag',
  color text not null default 'lime',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index trackers_owner_idx on public.trackers (owner_id);

create table public.tracker_goals (
  id uuid primary key default gen_random_uuid(),
  tracker_id uuid not null references public.trackers (id) on delete cascade,
  title text not null,
  category text not null default 'custom'
    check (category in ('fitness', 'food', 'lifestyle', 'custom')),
  kind text not null default 'count'
    check (kind in ('count', 'boolean', 'numeric')),
  target_value numeric(10, 2) not null default 1 check (target_value > 0),
  target_unit text not null default 'times',
  period text not null default 'week'
    check (period in ('day', 'week', 'month')),
  sort_order integer not null default 0
);

create index tracker_goals_tracker_idx on public.tracker_goals (tracker_id, sort_order);

create table public.tracker_members (
  tracker_id uuid not null references public.trackers (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  role text not null default 'member'
    check (role in ('owner', 'member')),
  status text not null default 'active'
    check (status in ('invited', 'active')),
  created_at timestamptz not null default now(),
  primary key (tracker_id, user_id)
);

create index tracker_members_user_idx on public.tracker_members (user_id, status);

create table public.tracker_entries (
  id uuid primary key default gen_random_uuid(),
  goal_id uuid not null references public.tracker_goals (id) on delete cascade,
  user_id uuid not null references public.profiles (id) on delete cascade,
  logged_on date not null default (timezone('utc', now()))::date,
  value numeric(10, 2) not null default 1 check (value >= 0),
  note text not null default '',
  created_at timestamptz not null default now()
);

create index tracker_entries_goal_user_day_idx
  on public.tracker_entries (goal_id, user_id, logged_on desc);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on all tables in schema public to authenticated;
grant select on public.profiles to anon;
