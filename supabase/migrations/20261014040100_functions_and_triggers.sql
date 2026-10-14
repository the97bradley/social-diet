create or replace function private.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.friendships f
    where f.status = 'accepted'
      and (
        (f.requester_id = a and f.addressee_id = b)
        or (f.requester_id = b and f.addressee_id = a)
      )
  );
$$;

create or replace function private.is_conversation_member(cid uuid, uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.conversation_members m
    where m.conversation_id = cid
      and m.user_id = uid
  );
$$;

create or replace function private.is_tracker_member(tid uuid, uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.tracker_members m
    where m.tracker_id = tid
      and m.user_id = uid
      and m.status = 'active'
  );
$$;

create or replace function private.touch_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create or replace function private.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta_username text;
  meta_name text;
  final_username text;
begin
  meta_username := lower(trim(coalesce(new.raw_user_meta_data ->> 'username', '')));
  meta_name := trim(coalesce(
    new.raw_user_meta_data ->> 'display_name',
    split_part(coalesce(new.email, 'friend'), '@', 1)
  ));

  if meta_username ~ '^[a-z0-9_]{3,24}$' then
    final_username := meta_username;
  else
    final_username := 'user_' || substr(replace(new.id::text, '-', ''), 1, 12);
  end if;

  begin
    insert into public.profiles (id, username, display_name)
    values (new.id, final_username, meta_name);
  exception
    when unique_violation then
      insert into public.profiles (id, username, display_name)
      values (
        new.id,
        'user_' || substr(replace(new.id::text, '-', ''), 1, 12),
        meta_name
      );
  end;

  return new;
end;
$$;

create or replace function private.add_tracker_owner_member()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.tracker_members (tracker_id, user_id, role, status)
  values (new.id, new.owner_id, 'owner', 'active');
  return new;
end;
$$;

create or replace function private.create_direct_conversation(other_user uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  me uuid;
  cid uuid;
  pair text;
begin
  me := auth.uid();
  if me is null then
    raise exception 'not authenticated';
  end if;
  if me = other_user then
    raise exception 'cannot message yourself';
  end if;
  if not private.are_friends(me, other_user) then
    raise exception 'not friends';
  end if;

  if me < other_user then
    pair := me::text || ':' || other_user::text;
  else
    pair := other_user::text || ':' || me::text;
  end if;

  select c.id into cid
  from public.conversations c
  where c.direct_pair = pair;

  if cid is not null then
    return cid;
  end if;

  insert into public.conversations (direct_pair)
  values (pair)
  returning id into cid;

  insert into public.conversation_members (conversation_id, user_id)
  values (cid, me), (cid, other_user);

  return cid;
end;
$$;

create or replace function public.create_direct_conversation(other_user uuid)
returns uuid
language sql
security invoker
set search_path = ''
as $$
  select private.create_direct_conversation(other_user);
$$;

grant execute on function private.are_friends(uuid, uuid) to authenticated;
grant execute on function private.is_conversation_member(uuid, uuid) to authenticated;
grant execute on function private.is_tracker_member(uuid, uuid) to authenticated;
grant execute on function public.create_direct_conversation(uuid) to authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_user();

create trigger profiles_touch_updated_at
  before update on public.profiles
  for each row execute function private.touch_updated_at();

create trigger trackers_touch_updated_at
  before update on public.trackers
  for each row execute function private.touch_updated_at();

create trigger trackers_add_owner_member
  after insert on public.trackers
  for each row execute function private.add_tracker_owner_member();
