alter table public.user_profiles
  add column if not exists last_active_at timestamptz not null default timezone('utc', now());

create index if not exists idx_user_profiles_last_active_at
  on public.user_profiles (last_active_at);

update public.user_profiles
set last_active_at = coalesce(updated_at, timezone('utc', now()))
where last_active_at is null;
