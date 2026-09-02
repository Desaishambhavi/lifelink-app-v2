-- ============================================================================
--  LifeLink — Supabase schema
-- ----------------------------------------------------------------------------
--  Run this ONCE in the Supabase SQL editor of a *new* project for the app.
--  It is safe to re-run: every statement is idempotent (IF NOT EXISTS / OR
--  REPLACE). It never drops data.
--
--  Sections:
--    1. Extensions
--    2. Reference tables (mirror your existing database)
--    3. App-added tables (features this rebuild introduces)
--    4. Indexes
--    5. updated_at + new-user triggers
--    6. Row Level Security (RLS) policies
--    7. Seed data (weekly_trends Mon–Sun)
-- ============================================================================

-- 1. EXTENSIONS --------------------------------------------------------------
create extension if not exists "pgcrypto";      -- gen_random_uuid()

-- ============================================================================
-- 2. REFERENCE TABLES  (match the current database, 1:1)
-- ============================================================================

-- Users / health profile ------------------------------------------------------
create table if not exists public.users (
  id                     uuid primary key default gen_random_uuid(),
  firebase_uid           text unique,
  email                  text unique,
  first_name             text,
  last_name              text,
  full_name              text,
  created_at             timestamptz not null default now(),
  updated_at             timestamptz not null default now(),
  last_login             timestamptz,
  age                    integer,
  gender                 text,
  height                 numeric,          -- cm
  weight                 numeric,          -- kg
  bmi                    numeric,
  blood_group            text,
  emergency_contact      text,             -- phone
  -- App addition (see section 3): the contact's display name.
  emergency_contact_name text
);

-- Emergency SOS events --------------------------------------------------------
create table if not exists public.emergency_alerts (
  id              uuid primary key default gen_random_uuid(),
  firebase_key    text,
  user_email      text,                    -- app addition: who raised it
  acknowledged    boolean not null default false,
  message         text,
  event_timestamp timestamptz,
  created_at      timestamptz not null default now()
);

-- Compact live device readings (HR + SpO2) -----------------------------------
create table if not exists public.device_readings (
  id              uuid primary key default gen_random_uuid(),
  firebase_key    text,
  device_id       text,
  spo2            numeric,
  heart_rate      numeric,
  boot_millis     bigint,
  event_timestamp timestamptz,
  created_at      timestamptz not null default now()
);

-- Full sensor payload (HR + accel + GPS) -------------------------------------
create table if not exists public.device_sensor_data (
  id              uuid primary key default gen_random_uuid(),
  firebase_key    text,
  accel_total     numeric,
  accel_x         numeric,
  accel_y         numeric,
  accel_z         numeric,
  gps_latitude    numeric,
  gps_longitude   numeric,
  gps_satellites  integer,
  heart_rate      numeric,
  boot_millis     bigint,
  event_timestamp timestamptz,
  created_at      timestamptz not null default now()
);

-- Fall-detection events -------------------------------------------------------
create table if not exists public.fall_events (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  heart_rate_bpm integer,
  accel_x        real,
  accel_y        real,
  accel_z        real,
  latitude       double precision,
  longitude      double precision,
  gps_fix        boolean,
  spo2           integer,
  spo2_valid     integer
);

-- Richest raw stream (HR + accel + gyro + GPS + SpO2) ------------------------
create table if not exists public.sensor_logs (
  id             bigint generated always as identity primary key,
  created_at     timestamptz not null default now(),
  heart_rate_bpm integer,
  accel_x        real,
  accel_y        real,
  accel_z        real,
  gyro_x         real,
  gyro_y         real,
  gyro_z         real,
  latitude       double precision,
  longitude      double precision,
  gps_fix        boolean,
  spo2           integer,
  spo2_valid     boolean
);

-- AI report summaries ---------------------------------------------------------
create table if not exists public.reports (
  id          uuid primary key default gen_random_uuid(),
  user_email  text,
  report_name text,
  summary     text,
  language    text,
  uploaded_at timestamptz not null default now()
);

-- Weekly averages (one row per weekday) --------------------------------------
create table if not exists public.weekly_trends (
  day            text primary key,        -- 'Mon' .. 'Sun'
  avg_heart_rate numeric,
  avg_spo2       numeric,
  avg_stress     numeric,
  avg_hydration  numeric
);

-- ============================================================================
-- 3. APP-ADDED TABLES  (features this rebuild introduces)
-- ============================================================================

-- Medication reminders --------------------------------------------------------
create table if not exists public.medication_reminders (
  id              uuid primary key default gen_random_uuid(),
  user_email      text,
  medication_name text not null,
  dosage          text,
  hour            integer not null default 8,   -- 0–23
  minute          integer not null default 0,   -- 0–59
  repeat          integer not null default 1,   -- 0=once 1=daily 2=weekly
  weekday         integer not null default 1,   -- 1 (Mon) – 7 (Sun)
  enabled         boolean not null default true,
  created_at      timestamptz not null default now()
);

-- In-app notification centre --------------------------------------------------
create table if not exists public.notifications (
  id         uuid primary key default gen_random_uuid(),
  user_email text,
  title      text not null,
  body       text,
  kind       integer not null default 5,        -- 0 vitals 1 reminder 2 fall
                                                 -- 3 sos 4 report 5 system
  read       boolean not null default false,
  created_at timestamptz not null default now()
);

-- If the app added columns to a pre-existing users/emergency_alerts table,
-- make sure they exist (no-ops on a fresh install).
alter table public.users
  add column if not exists emergency_contact_name text;
alter table public.emergency_alerts
  add column if not exists user_email text;

-- ============================================================================
-- 4. INDEXES
-- ============================================================================
create index if not exists idx_sensor_logs_created_at
  on public.sensor_logs (created_at desc);
create index if not exists idx_device_readings_created_at
  on public.device_readings (created_at desc);
create index if not exists idx_device_sensor_data_created_at
  on public.device_sensor_data (created_at desc);
create index if not exists idx_fall_events_created_at
  on public.fall_events (created_at desc);
create index if not exists idx_reports_user_email
  on public.reports (user_email);
create index if not exists idx_reminders_user_email
  on public.medication_reminders (user_email);
create index if not exists idx_notifications_user_email
  on public.notifications (user_email, created_at desc);

-- ============================================================================
-- 5. TRIGGERS
-- ============================================================================

-- Keep users.updated_at fresh on every update.
create or replace function public.touch_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_users_updated_at on public.users;
create trigger trg_users_updated_at
  before update on public.users
  for each row execute function public.touch_updated_at();

-- Auto-create a profile row when a new auth user signs up.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.users (id, email, full_name)
  values (new.id, new.email, coalesce(new.raw_user_meta_data->>'full_name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ============================================================================
-- 6. ROW LEVEL SECURITY
-- ----------------------------------------------------------------------------
--  Owner tables are scoped to the signed-in user's email/id. Device + trend
--  tables are readable by any authenticated user; the ESP32 writes to them
--  with the service-role key (which bypasses RLS), so no INSERT policy is
--  needed for the hardware.
-- ============================================================================
alter table public.users               enable row level security;
alter table public.reports             enable row level security;
alter table public.medication_reminders enable row level security;
alter table public.notifications       enable row level security;
alter table public.emergency_alerts    enable row level security;
alter table public.device_readings     enable row level security;
alter table public.device_sensor_data  enable row level security;
alter table public.sensor_logs         enable row level security;
alter table public.fall_events         enable row level security;
alter table public.weekly_trends       enable row level security;

-- Helper: current user's email from the JWT.
--   auth.jwt() ->> 'email'

-- users: read/update own row.
drop policy if exists users_self on public.users;
create policy users_self on public.users
  for all to authenticated
  using (id = auth.uid() or email = (auth.jwt() ->> 'email'))
  with check (id = auth.uid() or email = (auth.jwt() ->> 'email'));

-- reports / reminders / notifications / alerts: own rows by email.
drop policy if exists reports_own on public.reports;
create policy reports_own on public.reports
  for all to authenticated
  using (user_email = (auth.jwt() ->> 'email'))
  with check (user_email = (auth.jwt() ->> 'email'));

drop policy if exists reminders_own on public.medication_reminders;
create policy reminders_own on public.medication_reminders
  for all to authenticated
  using (user_email = (auth.jwt() ->> 'email'))
  with check (user_email = (auth.jwt() ->> 'email'));

drop policy if exists notifications_own on public.notifications;
create policy notifications_own on public.notifications
  for all to authenticated
  using (user_email = (auth.jwt() ->> 'email'))
  with check (user_email = (auth.jwt() ->> 'email'));

drop policy if exists alerts_own on public.emergency_alerts;
create policy alerts_own on public.emergency_alerts
  for all to authenticated
  using (user_email = (auth.jwt() ->> 'email') or user_email is null)
  with check (user_email = (auth.jwt() ->> 'email') or user_email is null);

-- device + trend tables: read-only for any signed-in user.
drop policy if exists device_readings_read on public.device_readings;
create policy device_readings_read on public.device_readings
  for select to authenticated using (true);

drop policy if exists device_sensor_read on public.device_sensor_data;
create policy device_sensor_read on public.device_sensor_data
  for select to authenticated using (true);

drop policy if exists sensor_logs_read on public.sensor_logs;
create policy sensor_logs_read on public.sensor_logs
  for select to authenticated using (true);

drop policy if exists fall_events_read on public.fall_events;
create policy fall_events_read on public.fall_events
  for select to authenticated using (true);

drop policy if exists weekly_trends_read on public.weekly_trends;
create policy weekly_trends_read on public.weekly_trends
  for select to authenticated using (true);

-- ============================================================================
-- 7. SEED — weekly_trends (safe, illustrative baseline)
-- ============================================================================
insert into public.weekly_trends (day, avg_heart_rate, avg_spo2, avg_stress, avg_hydration)
values
  ('Mon', 74, 97, 42, 68),
  ('Tue', 78, 96, 55, 61),
  ('Wed', 72, 98, 38, 74),
  ('Thu', 80, 96, 60, 58),
  ('Fri', 76, 97, 47, 65),
  ('Sat', 70, 98, 30, 80),
  ('Sun', 69, 98, 28, 83)
on conflict (day) do nothing;

-- Done.
