create or replace function private.has_tracker_access(tid uuid, uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.tracker_members m
    where m.tracker_id = tid and m.user_id = uid
  ) or exists (
    select 1 from public.trackers t
    where t.id = tid and t.owner_id = uid
  );
$$;

create or replace function private.is_tracker_owner(tid uuid, uid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.trackers t
    where t.id = tid and t.owner_id = uid
  );
$$;

grant execute on function private.has_tracker_access(uuid, uuid) to authenticated;
grant execute on function private.is_tracker_owner(uuid, uuid) to authenticated;

drop policy if exists trackers_select on public.trackers;
create policy trackers_select on public.trackers
  for select to authenticated
  using (private.has_tracker_access(id, (select auth.uid())));

drop policy if exists tracker_goals_select on public.tracker_goals;
create policy tracker_goals_select on public.tracker_goals
  for select to authenticated
  using (private.has_tracker_access(tracker_id, (select auth.uid())));

drop policy if exists tracker_goals_insert on public.tracker_goals;
drop policy if exists tracker_goals_update on public.tracker_goals;
drop policy if exists tracker_goals_delete on public.tracker_goals;

create policy tracker_goals_insert on public.tracker_goals
  for insert to authenticated
  with check (private.is_tracker_owner(tracker_id, (select auth.uid())));

create policy tracker_goals_update on public.tracker_goals
  for update to authenticated
  using (private.is_tracker_owner(tracker_id, (select auth.uid())))
  with check (private.is_tracker_owner(tracker_id, (select auth.uid())));

create policy tracker_goals_delete on public.tracker_goals
  for delete to authenticated
  using (private.is_tracker_owner(tracker_id, (select auth.uid())));

drop policy if exists tracker_members_select on public.tracker_members;
drop policy if exists tracker_members_insert on public.tracker_members;
drop policy if exists tracker_members_update on public.tracker_members;
drop policy if exists tracker_members_delete on public.tracker_members;

create policy tracker_members_select on public.tracker_members
  for select to authenticated
  using (private.has_tracker_access(tracker_id, (select auth.uid())));

create policy tracker_members_insert on public.tracker_members
  for insert to authenticated
  with check (private.is_tracker_owner(tracker_id, (select auth.uid())));

create policy tracker_members_update on public.tracker_members
  for update to authenticated
  using (
    user_id = (select auth.uid())
    or private.is_tracker_owner(tracker_id, (select auth.uid()))
  )
  with check (
    user_id = (select auth.uid())
    or private.is_tracker_owner(tracker_id, (select auth.uid()))
  );

create policy tracker_members_delete on public.tracker_members
  for delete to authenticated
  using (
    user_id = (select auth.uid())
    or private.is_tracker_owner(tracker_id, (select auth.uid()))
  );

drop policy if exists tracker_entries_select on public.tracker_entries;
drop policy if exists tracker_entries_insert on public.tracker_entries;

create policy tracker_entries_select on public.tracker_entries
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.tracker_goals g
      where g.id = goal_id
        and private.has_tracker_access(g.tracker_id, (select auth.uid()))
    )
  );

create policy tracker_entries_insert on public.tracker_entries
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.tracker_goals g
      where g.id = goal_id
        and private.is_tracker_member(g.tracker_id, (select auth.uid()))
    )
  );
