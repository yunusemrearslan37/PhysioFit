create extension if not exists pgcrypto;

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

create table if not exists public.notification_preferences (
  user_id uuid primary key references auth.users (id) on delete cascade,
  notifications_enabled boolean not null default true,
  workout_reminders_enabled boolean not null default true,
  reminder_hour smallint not null default 9 check (reminder_hour between 0 and 23),
  reminder_minute smallint not null default 0 check (reminder_minute between 0 and 59),
  sound_enabled boolean not null default true,
  vibration_enabled boolean not null default true,
  push_ai_enabled boolean not null default true,
  push_plan_updates_enabled boolean not null default true,
  push_reengagement_enabled boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  device_label text,
  app_version text,
  is_active boolean not null default true,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  last_seen_at timestamptz not null default timezone('utc', now())
);

create table if not exists public.notification_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users (id) on delete cascade,
  device_token_id uuid references public.device_tokens (id) on delete set null,
  notification_type text not null,
  title text not null,
  body text not null,
  payload jsonb not null default '{}'::jsonb,
  provider text not null default 'fcm',
  provider_message_id text,
  status text not null default 'pending' check (status in ('pending', 'sent', 'failed', 'skipped')),
  error_message text,
  scheduled_for timestamptz,
  sent_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists idx_device_tokens_user_id
  on public.device_tokens (user_id);

create index if not exists idx_device_tokens_active
  on public.device_tokens (is_active, last_seen_at desc);

create index if not exists idx_notification_logs_user_id
  on public.notification_logs (user_id, created_at desc);

create index if not exists idx_notification_logs_status
  on public.notification_logs (status, created_at desc);

alter table public.notification_preferences enable row level security;
alter table public.device_tokens enable row level security;
alter table public.notification_logs enable row level security;

drop policy if exists "notification_preferences_select_own" on public.notification_preferences;
create policy "notification_preferences_select_own"
  on public.notification_preferences
  for select
  using (auth.uid() = user_id);

drop policy if exists "notification_preferences_insert_own" on public.notification_preferences;
create policy "notification_preferences_insert_own"
  on public.notification_preferences
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "notification_preferences_update_own" on public.notification_preferences;
create policy "notification_preferences_update_own"
  on public.notification_preferences
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "device_tokens_select_own" on public.device_tokens;
create policy "device_tokens_select_own"
  on public.device_tokens
  for select
  using (auth.uid() = user_id);

drop policy if exists "device_tokens_insert_own" on public.device_tokens;
create policy "device_tokens_insert_own"
  on public.device_tokens
  for insert
  with check (auth.uid() = user_id);

drop policy if exists "device_tokens_update_own" on public.device_tokens;
create policy "device_tokens_update_own"
  on public.device_tokens
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "device_tokens_delete_own" on public.device_tokens;
create policy "device_tokens_delete_own"
  on public.device_tokens
  for delete
  using (auth.uid() = user_id);

drop policy if exists "notification_logs_select_own" on public.notification_logs;
create policy "notification_logs_select_own"
  on public.notification_logs
  for select
  using (auth.uid() = user_id);

drop trigger if exists set_notification_preferences_updated_at on public.notification_preferences;
create trigger set_notification_preferences_updated_at
before update on public.notification_preferences
for each row
execute function public.set_updated_at();

drop trigger if exists set_device_tokens_updated_at on public.device_tokens;
create trigger set_device_tokens_updated_at
before update on public.device_tokens
for each row
execute function public.set_updated_at();
