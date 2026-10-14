insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'releases',
  'releases',
  false,
  104857600,
  array['application/vnd.android.package-archive', 'application/octet-stream']
)
on conflict (id) do update set public = false;

create table if not exists public.apk_releases (
  token text primary key,
  object_path text not null,
  created_at timestamptz not null default now()
);

alter table public.apk_releases enable row level security;
revoke all on public.apk_releases from anon, authenticated, public;
grant all on public.apk_releases to service_role;
