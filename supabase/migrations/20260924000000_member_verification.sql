-- =====================================================================
-- Member / student verification
-- =====================================================================
-- Answers "how does the system know this account belongs to a real
-- student/GDGoC member?" with minimal input from the user:
--
--   1. Signing up with a school-domain email  -> verified automatically,
--      server-side, at the moment the profile row is created.
--   2. Anyone else (personal Gmail, Google Sign-In with a non-school
--      account) submits a student number + photo of their school ID,
--      which lands in an officer review queue.
--
-- Effective state lives on `profiles.verification_status` so RLS can read
-- it cheaply. "Pending" is deliberately NOT mirrored there: it lives on
-- `verification_requests.status`, which the member is allowed to insert.
-- That keeps every write to `profiles.verification_status` in the hands
-- of the system (auto-verify trigger) or an officer.
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. Profile columns
-- ---------------------------------------------------------------------
alter table public.profiles
  add column if not exists verification_status text not null default 'unverified',
  add column if not exists verified_at  timestamptz,
  add column if not exists verified_by  uuid references public.profiles (id) on delete set null,
  add column if not exists student_number text;

alter table public.profiles drop constraint if exists profiles_verification_status_check;
alter table public.profiles add constraint profiles_verification_status_check
  check (verification_status in ('unverified', 'verified', 'rejected'));

create index if not exists profiles_verification_status_idx
  on public.profiles (verification_status);

-- ---------------------------------------------------------------------
-- 2. Allowed school email domains (data, not a hardcoded app constant,
--    so officers can add a domain without shipping a new build)
-- ---------------------------------------------------------------------
create table if not exists public.school_email_domains (
  domain     text primary key,
  chapter_id uuid references public.chapters (id) on delete set null,
  added_by   uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default now()
);

alter table public.school_email_domains enable row level security;

drop policy if exists "school_email_domains_select_all" on public.school_email_domains;
create policy "school_email_domains_select_all" on public.school_email_domains
  for select to authenticated using (true);
drop policy if exists "school_email_domains_officer_write" on public.school_email_domains;
create policy "school_email_domains_officer_write" on public.school_email_domains
  for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- NOTE: adjust these to your chapter's real domains before going live.
insert into public.school_email_domains (domain) values
  ('nu-baliwag.edu.ph'),
  ('students.nu-baliwag.edu.ph')
on conflict (domain) do nothing;

-- ---------------------------------------------------------------------
-- 3. Verification requests (the officer review queue)
-- ---------------------------------------------------------------------
create table if not exists public.verification_requests (
  id               uuid primary key default gen_random_uuid(),
  user_id          uuid not null references public.profiles (id) on delete cascade,
  student_number   text not null,
  id_document_path text not null,
  status           text not null default 'pending'
                   check (status in ('pending', 'approved', 'rejected')),
  submitted_at     timestamptz not null default now(),
  reviewed_by      uuid references public.profiles (id) on delete set null,
  reviewed_at      timestamptz,
  rejection_reason text
);

create index if not exists verification_requests_user_idx on public.verification_requests (user_id);
create index if not exists verification_requests_status_idx on public.verification_requests (status);

-- At most one open request per member; re-submission after a rejection is allowed.
create unique index if not exists verification_requests_one_pending_per_user
  on public.verification_requests (user_id)
  where status = 'pending';

alter table public.verification_requests enable row level security;

drop policy if exists "verification_requests_select_own_or_officer" on public.verification_requests;
create policy "verification_requests_select_own_or_officer" on public.verification_requests
  for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
drop policy if exists "verification_requests_insert_own" on public.verification_requests;
create policy "verification_requests_insert_own" on public.verification_requests
  for insert to authenticated
  with check (user_id = auth.uid());
drop policy if exists "verification_requests_officer_update" on public.verification_requests;
create policy "verification_requests_officer_update" on public.verification_requests
  for update to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- 4. Helper — mirrors public.is_officer()
-- ---------------------------------------------------------------------
create or replace function public.is_verified()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles p
    where p.id = auth.uid() and p.verification_status = 'verified'
  );
$$;

-- ---------------------------------------------------------------------
-- 5. Auto-verify on signup when the email is on a school domain.
--    Runs BEFORE INSERT so it also covers rows created by the
--    handle_new_user() trigger and by the client-side _ensureProfile
--    upsert — there is no path into `profiles` that skips it.
-- ---------------------------------------------------------------------
create or replace function public.auto_verify_school_email()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  email_domain text;
begin
  if new.verification_status is distinct from 'unverified' then
    return new;
  end if;

  email_domain := lower(split_part(coalesce(new.email, ''), '@', 2));
  if email_domain = '' then
    return new;
  end if;

  if exists (select 1 from public.school_email_domains d where d.domain = email_domain) then
    new.verification_status := 'verified';
    new.verified_at := now();
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_auto_verify on public.profiles;
create trigger profiles_auto_verify
  before insert on public.profiles
  for each row execute function public.auto_verify_school_email();

-- ---------------------------------------------------------------------
-- 6. Grandfather every existing account.
--    Done BEFORE the guard trigger exists. Without this, accounts that
--    already exist (including the demo/test data) would silently lose the
--    ability to register for events the moment this migration lands.
-- ---------------------------------------------------------------------
update public.profiles
set verification_status = 'verified',
    verified_at = coalesce(verified_at, now())
where verification_status = 'unverified';

-- ---------------------------------------------------------------------
-- 7. Guard: members cannot escalate themselves.
--
--    `profiles_update_own` grants UPDATE on the whole row, so without this
--    a member could PATCH their own role_id / verification_status straight
--    against the REST API. The Dart toUpdateMap() whitelist only protects
--    the app's own code path, not the API.
--
--    `points` is deliberately NOT guarded: award_engagement_points() writes
--    it from a SECURITY DEFINER trigger while auth.uid() is still the
--    member, so guarding it here would break all points awarding.
--
--    A null auth.uid() means this is not an end-user request (SQL editor,
--    service role, migrations) and is allowed through.
-- ---------------------------------------------------------------------
create or replace function public.guard_protected_profile_columns()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null or public.is_officer() then
    return new;
  end if;

  if new.role_id            is distinct from old.role_id
     or new.verification_status is distinct from old.verification_status
     or new.verified_at     is distinct from old.verified_at
     or new.verified_by     is distinct from old.verified_by
     or new.student_number  is distinct from old.student_number then
    raise exception 'Protected profile columns can only be changed by an officer.'
      using errcode = '42501';
  end if;

  return new;
end;
$$;

drop trigger if exists profiles_guard_protected_columns on public.profiles;
create trigger profiles_guard_protected_columns
  before update on public.profiles
  for each row execute function public.guard_protected_profile_columns();

-- ---------------------------------------------------------------------
-- 8. Officer review RPC — updates the request and the profile atomically,
--    with the permission check on the server rather than in the client.
-- ---------------------------------------------------------------------
create or replace function public.review_verification_request(
  p_request_id uuid,
  p_approve    boolean,
  p_reason     text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
  target_user uuid;
  target_student_number text;
begin
  if not public.is_officer() then
    raise exception 'Only officers can review verification requests.' using errcode = '42501';
  end if;

  select user_id, student_number
    into target_user, target_student_number
  from public.verification_requests
  where id = p_request_id and status = 'pending'
  for update;

  if target_user is null then
    raise exception 'Verification request not found or already reviewed.' using errcode = 'P0002';
  end if;

  update public.verification_requests
  set status           = case when p_approve then 'approved' else 'rejected' end,
      reviewed_by      = auth.uid(),
      reviewed_at      = now(),
      rejection_reason = case when p_approve then null else p_reason end
  where id = p_request_id;

  update public.profiles
  set verification_status = case when p_approve then 'verified' else 'rejected' end,
      verified_at         = case when p_approve then now() else null end,
      verified_by         = case when p_approve then auth.uid() else null end,
      student_number      = case when p_approve then target_student_number else student_number end
  where id = target_user;
end;
$$;

-- ---------------------------------------------------------------------
-- 9. Participation gate — enforced in RLS, not just the UI.
--    An unverified member can browse everything but cannot register.
-- ---------------------------------------------------------------------
drop policy if exists "event_registrations_insert_own" on public.event_registrations;
create policy "event_registrations_insert_own" on public.event_registrations
  for insert to authenticated
  with check (user_id = auth.uid() and public.is_verified());
