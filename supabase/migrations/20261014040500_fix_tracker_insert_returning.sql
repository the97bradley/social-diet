drop policy if exists trackers_select on public.trackers;

create policy trackers_select on public.trackers
  for select to authenticated
  using (
    owner_id = (select auth.uid())
    or private.has_tracker_access(id, (select auth.uid()))
  );
