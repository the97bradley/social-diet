create or replace function private.touch_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop policy if exists tracker_goals_mutate on public.tracker_goals;

create policy tracker_goals_insert on public.tracker_goals
  for insert to authenticated
  with check (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_goals_update on public.tracker_goals
  for update to authenticated
  using (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  )
  with check (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_goals_delete on public.tracker_goals
  for delete to authenticated
  using (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create index if not exists messages_sender_id_idx on public.messages (sender_id);
create index if not exists tracker_entries_user_id_idx on public.tracker_entries (user_id);
