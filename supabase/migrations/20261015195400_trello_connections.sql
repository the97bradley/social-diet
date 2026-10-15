-- Trello tokens stay off public.profiles: friends can select every profile.

create table public.trello_connections (
  user_id uuid primary key references public.profiles (id) on delete cascade,
  api_key text not null
    check (char_length(api_key) between 16 and 128),
  token text not null
    check (char_length(token) between 16 and 256),
  board_id text not null default '',
  board_name text not null default '',
  updated_at timestamptz not null default now()
);

alter table public.trello_connections enable row level security;

revoke all on public.trello_connections from anon, public;
grant select, insert, update, delete on public.trello_connections to authenticated;

create policy trello_connections_select on public.trello_connections
  for select to authenticated
  using (user_id = (select auth.uid()));

create policy trello_connections_insert on public.trello_connections
  for insert to authenticated
  with check (user_id = (select auth.uid()));

create policy trello_connections_update on public.trello_connections
  for update to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy trello_connections_delete on public.trello_connections
  for delete to authenticated
  using (user_id = (select auth.uid()));

create trigger trello_connections_touch_updated_at
  before update on public.trello_connections
  for each row execute function private.touch_updated_at();
