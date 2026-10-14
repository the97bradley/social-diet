alter table public.profiles enable row level security;
alter table public.friendships enable row level security;
alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.messages enable row level security;
alter table public.feed_posts enable row level security;
alter table public.feed_likes enable row level security;
alter table public.food_logs enable row level security;
alter table public.workouts enable row level security;
alter table public.trackers enable row level security;
alter table public.tracker_goals enable row level security;
alter table public.tracker_members enable row level security;
alter table public.tracker_entries enable row level security;

create policy profiles_select on public.profiles
  for select to authenticated
  using (true);

create policy profiles_update on public.profiles
  for update to authenticated
  using (id = (select auth.uid()))
  with check (id = (select auth.uid()));

create policy friendships_select on public.friendships
  for select to authenticated
  using (
    requester_id = (select auth.uid())
    or addressee_id = (select auth.uid())
  );

create policy friendships_insert on public.friendships
  for insert to authenticated
  with check (requester_id = (select auth.uid()));

create policy friendships_update on public.friendships
  for update to authenticated
  using (
    addressee_id = (select auth.uid())
    or requester_id = (select auth.uid())
  )
  with check (
    addressee_id = (select auth.uid())
    or requester_id = (select auth.uid())
  );

create policy friendships_delete on public.friendships
  for delete to authenticated
  using (
    requester_id = (select auth.uid())
    or addressee_id = (select auth.uid())
  );

create policy conversations_select on public.conversations
  for select to authenticated
  using (private.is_conversation_member(id, (select auth.uid())));

create policy conversation_members_select on public.conversation_members
  for select to authenticated
  using (private.is_conversation_member(conversation_id, (select auth.uid())));

create policy conversation_members_update on public.conversation_members
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy messages_select on public.messages
  for select to authenticated
  using (private.is_conversation_member(conversation_id, (select auth.uid())));

create policy messages_insert on public.messages
  for insert to authenticated
  with check (
    sender_id = (select auth.uid())
    and private.is_conversation_member(conversation_id, (select auth.uid()))
  );

create policy feed_posts_select on public.feed_posts
  for select to authenticated
  using (
    author_id = (select auth.uid())
    or private.are_friends(author_id, (select auth.uid()))
  );

create policy feed_posts_insert on public.feed_posts
  for insert to authenticated
  with check (author_id = (select auth.uid()));

create policy feed_posts_delete on public.feed_posts
  for delete to authenticated
  using (author_id = (select auth.uid()));

create policy feed_likes_select on public.feed_likes
  for select to authenticated
  using (
    exists (
      select 1
      from public.feed_posts p
      where p.id = post_id
        and (
          p.author_id = (select auth.uid())
          or private.are_friends(p.author_id, (select auth.uid()))
        )
    )
  );

create policy feed_likes_insert on public.feed_likes
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy feed_likes_delete on public.feed_likes
  for delete to authenticated
  using (user_id = (select auth.uid()));

create policy food_logs_select on public.food_logs
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or private.are_friends(user_id, (select auth.uid()))
  );

create policy food_logs_insert on public.food_logs
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy food_logs_update on public.food_logs
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy food_logs_delete on public.food_logs
  for delete to authenticated
  using (user_id = (select auth.uid()));

create policy workouts_select on public.workouts
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or private.are_friends(user_id, (select auth.uid()))
  );

create policy workouts_insert on public.workouts
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy workouts_update on public.workouts
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy workouts_delete on public.workouts
  for delete to authenticated
  using (user_id = (select auth.uid()));

create policy trackers_select on public.trackers
  for select to authenticated
  using (
    owner_id = (select auth.uid())
    or private.is_tracker_member(id, (select auth.uid()))
    or exists (
      select 1
      from public.tracker_members m
      where m.tracker_id = id
        and m.user_id = (select auth.uid())
    )
  );

create policy trackers_insert on public.trackers
  for insert to authenticated
  with check (owner_id = (select auth.uid()));

create policy trackers_update on public.trackers
  for update to authenticated
  using (owner_id = (select auth.uid()))
  with check (owner_id = (select auth.uid()));

create policy trackers_delete on public.trackers
  for delete to authenticated
  using (owner_id = (select auth.uid()));

create policy tracker_goals_select on public.tracker_goals
  for select to authenticated
  using (
    exists (
      select 1
      from public.trackers t
      where t.id = tracker_id
        and (
          t.owner_id = (select auth.uid())
          or private.is_tracker_member(t.id, (select auth.uid()))
          or exists (
            select 1
            from public.tracker_members m
            where m.tracker_id = t.id
              and m.user_id = (select auth.uid())
          )
        )
    )
  );

create policy tracker_goals_mutate on public.tracker_goals
  for all to authenticated
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

create policy tracker_members_select on public.tracker_members
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or private.is_tracker_member(tracker_id, (select auth.uid()))
    or exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_members_insert on public.tracker_members
  for insert to authenticated
  with check (
    exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_members_update on public.tracker_members
  for update to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  )
  with check (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_members_delete on public.tracker_members
  for delete to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1 from public.trackers t
      where t.id = tracker_id and t.owner_id = (select auth.uid())
    )
  );

create policy tracker_entries_select on public.tracker_entries
  for select to authenticated
  using (
    user_id = (select auth.uid())
    or exists (
      select 1
      from public.tracker_goals g
      where g.id = goal_id
        and (
          private.is_tracker_member(g.tracker_id, (select auth.uid()))
          or exists (
            select 1 from public.trackers t
            where t.id = g.tracker_id and t.owner_id = (select auth.uid())
          )
        )
    )
  );

create policy tracker_entries_insert on public.tracker_entries
  for insert to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1
      from public.tracker_goals g
      where g.id = goal_id
        and private.is_tracker_member(g.tracker_id, (select auth.uid()))
    )
  );

create policy tracker_entries_update on public.tracker_entries
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy tracker_entries_delete on public.tracker_entries
  for delete to authenticated
  using (user_id = (select auth.uid()));

alter publication supabase_realtime add table public.messages;
alter publication supabase_realtime add table public.feed_posts;
alter publication supabase_realtime add table public.feed_likes;
