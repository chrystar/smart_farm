-- Migration: Create creator_profiles table for creator onboarding

create table if not exists creator_profiles (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  bio text,
  profile_picture_url text,
  phone text,
  website text,
  years_experience integer,
  specializations text[] default '{}',
  approved boolean not null default false,
  created_at timestamptz default now(),
  updated_at timestamptz default now(),
  unique (user_id)
);
-- Notify admin on new application
drop trigger if exists notify_admin_new_creator_application on creator_profiles;
create trigger notify_admin_new_creator_application
after insert on creator_profiles
for each row execute function notify_admin();

alter table creator_profiles enable row level security;

drop policy if exists "Users can manage their creator profile" on creator_profiles;
create policy "Users can manage their creator profile"
on creator_profiles for all
using (auth.uid() = user_id);

-- updated_at trigger
-- Assumes update_updated_at_column() already exists

drop trigger if exists update_creator_profiles_updated_at on creator_profiles;
create trigger update_creator_profiles_updated_at
before update on creator_profiles
for each row execute function update_updated_at_column();
