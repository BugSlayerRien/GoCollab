-- =====================================================================
-- GoCollab :: Initial Schema Migration
-- GDGoC Philippines community management platform
-- =====================================================================
-- Conventions:
--   * All primary keys are UUID (gen_random_uuid()), except lookup
--     tables (roles) which use small serial ids.
--   * created_at / updated_at columns are timestamptz, defaulting to now().
--   * Foreign keys use ON DELETE CASCADE for dependent rows, and
--     ON DELETE SET NULL for optional/audit references.
--   * Row Level Security (RLS) is enabled on every table with policies
--     scoped to Supabase auth.uid() and the `is_officer()` helper.
-- =====================================================================

create extension if not exists "pgcrypto";

-- ---------------------------------------------------------------------
-- 1. ROLES
-- ---------------------------------------------------------------------
create table if not exists public.roles (
  id          smallint primary key,
  name        text not null unique,
  description text
);

insert into public.roles (id, name, description) values
  (1, 'member', 'GDGoC community member'),
  (2, 'officer', 'GDGoC chapter officer / admin')
on conflict (id) do nothing;

-- ---------------------------------------------------------------------
-- 2. CHAPTERS (campus chapters under GDGoC Philippines)
-- ---------------------------------------------------------------------
create table if not exists public.chapters (
  id          uuid primary key default gen_random_uuid(),
  name        text not null,
  campus      text not null,
  region      text,
  logo_url    text,
  is_active   boolean not null default true,
  created_at  timestamptz not null default now()
);

create unique index if not exists chapters_name_campus_idx on public.chapters (name, campus);

-- ---------------------------------------------------------------------
-- 3. PROFILES (1:1 extension of auth.users)
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id                uuid primary key references auth.users (id) on delete cascade,
  role_id           smallint not null default 1 references public.roles (id),
  chapter_id        uuid references public.chapters (id) on delete set null,
  full_name         text not null,
  email             text not null unique,
  avatar_url        text,
  bio               text,
  program           text,          -- e.g. BS Computer Science
  year_level        text,          -- e.g. 3rd Year
  contact_number    text,
  skills            text[] not null default '{}',
  github_username   text,
  linkedin_url      text,
  points            integer not null default 0,
  is_active         boolean not null default true,
  onboarded_at      timestamptz,
  created_at        timestamptz not null default now(),
  updated_at        timestamptz not null default now()
);

create index if not exists profiles_role_idx on public.profiles (role_id);
create index if not exists profiles_chapter_idx on public.profiles (chapter_id);
create index if not exists profiles_github_idx on public.profiles (github_username);

-- ---------------------------------------------------------------------
-- 4. GITHUB PROFILES (synced GitHub stats for a member)
-- ---------------------------------------------------------------------
create table if not exists public.github_profiles (
  id              uuid primary key default gen_random_uuid(),
  user_id         uuid not null unique references public.profiles (id) on delete cascade,
  github_username text not null,
  avatar_url      text,
  bio             text,
  public_repos    integer not null default 0,
  followers       integer not null default 0,
  following       integer not null default 0,
  profile_url     text,
  synced_at       timestamptz not null default now()
);

create index if not exists github_profiles_user_idx on public.github_profiles (user_id);

-- ---------------------------------------------------------------------
-- 5. ANNOUNCEMENTS
-- ---------------------------------------------------------------------
create table if not exists public.announcements (
  id           uuid primary key default gen_random_uuid(),
  title        text not null,
  body         text not null,
  category     text not null default 'general'
               check (category in ('general','event','career','partnership','urgent')),
  image_url    text,
  chapter_id   uuid references public.chapters (id) on delete set null,
  is_pinned    boolean not null default false,
  created_by   uuid references public.profiles (id) on delete set null,
  published_at timestamptz not null default now(),
  created_at   timestamptz not null default now(),
  updated_at   timestamptz not null default now()
);

create index if not exists announcements_published_idx on public.announcements (published_at desc);
create index if not exists announcements_category_idx on public.announcements (category);
create index if not exists announcements_pinned_idx on public.announcements (is_pinned);

-- ---------------------------------------------------------------------
-- 6. EVENTS
-- ---------------------------------------------------------------------
create table if not exists public.events (
  id                  uuid primary key default gen_random_uuid(),
  title               text not null,
  description         text not null,
  category            text not null default 'workshop'
                      check (category in ('workshop','hackathon','seminar','meetup','study-jam','competition','other')),
  banner_url          text,
  venue_name          text,
  venue_address       text,
  latitude            double precision,
  longitude           double precision,
  is_online           boolean not null default false,
  online_url          text,
  start_at            timestamptz not null,
  end_at              timestamptz not null,
  capacity            integer,
  registration_deadline timestamptz,
  is_featured         boolean not null default false,
  status              text not null default 'upcoming'
                      check (status in ('draft','upcoming','ongoing','completed','cancelled')),
  chapter_id          uuid references public.chapters (id) on delete set null,
  created_by          uuid references public.profiles (id) on delete set null,
  created_at          timestamptz not null default now(),
  updated_at          timestamptz not null default now(),
  constraint events_time_check check (end_at > start_at)
);

create index if not exists events_start_idx on public.events (start_at);
create index if not exists events_status_idx on public.events (status);
create index if not exists events_featured_idx on public.events (is_featured);
create index if not exists events_chapter_idx on public.events (chapter_id);

-- ---------------------------------------------------------------------
-- 7. EVENT REGISTRATIONS
-- ---------------------------------------------------------------------
create table if not exists public.event_registrations (
  id             uuid primary key default gen_random_uuid(),
  event_id       uuid not null references public.events (id) on delete cascade,
  user_id        uuid not null references public.profiles (id) on delete cascade,
  status         text not null default 'registered'
                 check (status in ('registered','cancelled','waitlisted','attended','no-show')),
  qr_code        text not null unique default encode(gen_random_bytes(16), 'hex'),
  registered_at  timestamptz not null default now(),
  cancelled_at   timestamptz,
  unique (event_id, user_id)
);

create index if not exists event_registrations_event_idx on public.event_registrations (event_id);
create index if not exists event_registrations_user_idx on public.event_registrations (user_id);
create index if not exists event_registrations_qr_idx on public.event_registrations (qr_code);

-- ---------------------------------------------------------------------
-- 8. ATTENDANCE (QR check-in records)
-- ---------------------------------------------------------------------
create table if not exists public.attendance (
  id               uuid primary key default gen_random_uuid(),
  event_id         uuid not null references public.events (id) on delete cascade,
  user_id          uuid not null references public.profiles (id) on delete cascade,
  registration_id  uuid references public.event_registrations (id) on delete set null,
  checked_in_at    timestamptz not null default now(),
  checked_in_by    uuid references public.profiles (id) on delete set null,
  method           text not null default 'qr' check (method in ('qr','manual')),
  unique (event_id, user_id)
);

create index if not exists attendance_event_idx on public.attendance (event_id);
create index if not exists attendance_user_idx on public.attendance (user_id);

-- ---------------------------------------------------------------------
-- 9. CERTIFICATES (digital certificates issued for events)
-- ---------------------------------------------------------------------
create table if not exists public.certificates (
  id                  uuid primary key default gen_random_uuid(),
  event_id            uuid not null references public.events (id) on delete cascade,
  user_id             uuid not null references public.profiles (id) on delete cascade,
  certificate_number  text not null unique,
  certificate_url     text,
  issued_at           timestamptz not null default now(),
  issued_by           uuid references public.profiles (id) on delete set null,
  unique (event_id, user_id)
);

create index if not exists certificates_user_idx on public.certificates (user_id);
create index if not exists certificates_event_idx on public.certificates (event_id);

-- ---------------------------------------------------------------------
-- 10. OPPORTUNITIES (career hub)
-- ---------------------------------------------------------------------
create table if not exists public.opportunities (
  id              uuid primary key default gen_random_uuid(),
  title           text not null,
  organization    text not null,
  type            text not null
                  check (type in ('internship','scholarship','certification','hackathon','job','fellowship')),
  description     text not null,
  requirements    text,
  location        text,
  is_remote       boolean not null default false,
  application_url text,
  banner_url      text,
  deadline        timestamptz,
  status          text not null default 'open' check (status in ('open','closed','expired')),
  posted_by       uuid references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists opportunities_type_idx on public.opportunities (type);
create index if not exists opportunities_deadline_idx on public.opportunities (deadline);
create index if not exists opportunities_status_idx on public.opportunities (status);

-- ---------------------------------------------------------------------
-- 11. SAVED OPPORTUNITIES (bookmarks)
-- ---------------------------------------------------------------------
create table if not exists public.saved_opportunities (
  id                uuid primary key default gen_random_uuid(),
  user_id           uuid not null references public.profiles (id) on delete cascade,
  opportunity_id    uuid not null references public.opportunities (id) on delete cascade,
  reminder_enabled  boolean not null default true,
  saved_at          timestamptz not null default now(),
  unique (user_id, opportunity_id)
);

create index if not exists saved_opportunities_user_idx on public.saved_opportunities (user_id);
create index if not exists saved_opportunities_opportunity_idx on public.saved_opportunities (opportunity_id);

-- ---------------------------------------------------------------------
-- 12. PARTNERS (partnership management - officer module)
-- ---------------------------------------------------------------------
create table if not exists public.partners (
  id              uuid primary key default gen_random_uuid(),
  name            text not null,
  category        text not null default 'industry'
                  check (category in ('industry','academic','government','ngo','startup','other')),
  logo_url        text,
  description     text,
  contact_person  text,
  contact_email   text,
  contact_phone   text,
  address         text,
  latitude        double precision,
  longitude       double precision,
  website         text,
  collaboration_status text not null default 'prospect'
                  check (collaboration_status in ('prospect','active','on-hold','ended')),
  created_by      uuid references public.profiles (id) on delete set null,
  created_at      timestamptz not null default now(),
  updated_at      timestamptz not null default now()
);

create index if not exists partners_status_idx on public.partners (collaboration_status);
create index if not exists partners_category_idx on public.partners (category);

-- ---------------------------------------------------------------------
-- 13. SPONSORSHIPS (partnership management)
-- ---------------------------------------------------------------------
create table if not exists public.sponsorships (
  id               uuid primary key default gen_random_uuid(),
  partner_id       uuid not null references public.partners (id) on delete cascade,
  event_id         uuid references public.events (id) on delete set null,
  title            text not null,
  sponsorship_type text not null default 'monetary'
                   check (sponsorship_type in ('monetary','in-kind','media','venue','other')),
  amount           numeric(12,2),
  currency         text not null default 'PHP',
  status           text not null default 'pending'
                   check (status in ('pending','confirmed','fulfilled','cancelled')),
  start_date       date,
  end_date         date,
  notes            text,
  created_by       uuid references public.profiles (id) on delete set null,
  created_at       timestamptz not null default now()
);

create index if not exists sponsorships_partner_idx on public.sponsorships (partner_id);
create index if not exists sponsorships_status_idx on public.sponsorships (status);

-- ---------------------------------------------------------------------
-- 14. MEETINGS (partnership meeting schedule)
-- ---------------------------------------------------------------------
create table if not exists public.meetings (
  id            uuid primary key default gen_random_uuid(),
  partner_id    uuid not null references public.partners (id) on delete cascade,
  title         text not null,
  agenda        text,
  scheduled_at  timestamptz not null,
  location      text,
  attendees     text[] not null default '{}',
  status        text not null default 'scheduled'
                check (status in ('scheduled','completed','cancelled','rescheduled')),
  notes         text,
  created_by    uuid references public.profiles (id) on delete set null,
  created_at    timestamptz not null default now()
);

create index if not exists meetings_partner_idx on public.meetings (partner_id);
create index if not exists meetings_scheduled_idx on public.meetings (scheduled_at);

-- ---------------------------------------------------------------------
-- 15. COMMUNICATIONS (partnership communication logs)
-- ---------------------------------------------------------------------
create table if not exists public.communications (
  id              uuid primary key default gen_random_uuid(),
  partner_id      uuid not null references public.partners (id) on delete cascade,
  subject         text not null,
  message         text,
  direction       text not null default 'outbound' check (direction in ('inbound','outbound')),
  contact_method  text not null default 'email' check (contact_method in ('email','call','meeting','chat','other')),
  communicated_by uuid references public.profiles (id) on delete set null,
  communicated_at timestamptz not null default now()
);

create index if not exists communications_partner_idx on public.communications (partner_id);
create index if not exists communications_date_idx on public.communications (communicated_at);

-- ---------------------------------------------------------------------
-- 16. ENGAGEMENT LOGS (member engagement analytics)
-- ---------------------------------------------------------------------
create table if not exists public.engagement_logs (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  action_type    text not null
                 check (action_type in ('login','event_view','event_register','event_attend',
                                        'opportunity_view','opportunity_save','announcement_view',
                                        'profile_update','certificate_earned')),
  reference_type text,
  reference_id   uuid,
  metadata       jsonb not null default '{}'::jsonb,
  created_at     timestamptz not null default now()
);

create index if not exists engagement_logs_user_idx on public.engagement_logs (user_id);
create index if not exists engagement_logs_action_idx on public.engagement_logs (action_type);
create index if not exists engagement_logs_created_idx on public.engagement_logs (created_at desc);

-- ---------------------------------------------------------------------
-- 17. NOTIFICATIONS (FCM-backed notification records)
-- ---------------------------------------------------------------------
create table if not exists public.notifications (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  title          text not null,
  body           text not null,
  type           text not null default 'general'
                 check (type in ('announcement','event_reminder','registration_confirmation',
                                  'career_opportunity','partnership_update','general')),
  reference_type text,
  reference_id   uuid,
  is_read        boolean not null default false,
  sent_at        timestamptz,
  created_at     timestamptz not null default now()
);

create index if not exists notifications_user_idx on public.notifications (user_id);
create index if not exists notifications_unread_idx on public.notifications (user_id, is_read);

-- =====================================================================
-- HELPER FUNCTIONS
-- =====================================================================

-- Returns true if the current authenticated user is a chapter officer.
create or replace function public.is_officer()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.role_id = 2
  );
$$;

-- Automatically creates a profile row whenever a new auth.users row appears.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, full_name, email, avatar_url)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', split_part(new.email, '@', 1)),
    new.email,
    new.raw_user_meta_data ->> 'avatar_url'
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- Generic updated_at maintenance trigger function.
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array['profiles','announcements','events','opportunities','partners']
  loop
    execute format('drop trigger if exists set_updated_at on public.%I;', t);
    execute format('create trigger set_updated_at before update on public.%I for each row execute function public.set_updated_at();', t);
  end loop;
end $$;
