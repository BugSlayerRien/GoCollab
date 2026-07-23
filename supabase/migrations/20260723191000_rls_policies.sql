-- =====================================================================
-- GoCollab :: Row Level Security Policies
-- =====================================================================

alter table public.roles enable row level security;
alter table public.chapters enable row level security;
alter table public.profiles enable row level security;
alter table public.github_profiles enable row level security;
alter table public.announcements enable row level security;
alter table public.events enable row level security;
alter table public.event_registrations enable row level security;
alter table public.attendance enable row level security;
alter table public.certificates enable row level security;
alter table public.opportunities enable row level security;
alter table public.saved_opportunities enable row level security;
alter table public.partners enable row level security;
alter table public.sponsorships enable row level security;
alter table public.meetings enable row level security;
alter table public.communications enable row level security;
alter table public.engagement_logs enable row level security;
alter table public.notifications enable row level security;

-- ---------------------------------------------------------------------
-- ROLES / CHAPTERS: readable by any authenticated user, writable by officers
-- ---------------------------------------------------------------------
create policy "roles_select_all" on public.roles for select to authenticated using (true);
create policy "chapters_select_all" on public.chapters for select to authenticated using (true);
create policy "chapters_officer_write" on public.chapters for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- PROFILES
-- ---------------------------------------------------------------------
create policy "profiles_select_all" on public.profiles for select to authenticated using (true);
create policy "profiles_update_own" on public.profiles for update to authenticated
  using (id = auth.uid()) with check (id = auth.uid());
create policy "profiles_officer_update_any" on public.profiles for update to authenticated
  using (public.is_officer()) with check (true);
create policy "profiles_insert_own" on public.profiles for insert to authenticated
  with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- GITHUB PROFILES
-- ---------------------------------------------------------------------
create policy "github_profiles_select_all" on public.github_profiles for select to authenticated using (true);
create policy "github_profiles_upsert_own" on public.github_profiles for insert to authenticated
  with check (user_id = auth.uid());
create policy "github_profiles_update_own" on public.github_profiles for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "github_profiles_delete_own" on public.github_profiles for delete to authenticated
  using (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- ANNOUNCEMENTS: everyone reads, officers manage
-- ---------------------------------------------------------------------
create policy "announcements_select_all" on public.announcements for select to authenticated using (true);
create policy "announcements_officer_write" on public.announcements for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- EVENTS: everyone reads, officers manage
-- ---------------------------------------------------------------------
create policy "events_select_all" on public.events for select to authenticated using (true);
create policy "events_officer_write" on public.events for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- EVENT REGISTRATIONS: own rows + officer full access
-- ---------------------------------------------------------------------
create policy "event_registrations_select_own_or_officer" on public.event_registrations for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
create policy "event_registrations_insert_own" on public.event_registrations for insert to authenticated
  with check (user_id = auth.uid());
create policy "event_registrations_update_own_or_officer" on public.event_registrations for update to authenticated
  using (user_id = auth.uid() or public.is_officer()) with check (true);
create policy "event_registrations_delete_own_or_officer" on public.event_registrations for delete to authenticated
  using (user_id = auth.uid() or public.is_officer());

-- ---------------------------------------------------------------------
-- ATTENDANCE: own rows readable, officers manage (QR check-in)
-- ---------------------------------------------------------------------
create policy "attendance_select_own_or_officer" on public.attendance for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
create policy "attendance_officer_write" on public.attendance for insert to authenticated
  with check (public.is_officer());
create policy "attendance_officer_update" on public.attendance for update to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- CERTIFICATES: own rows readable, officers issue
-- ---------------------------------------------------------------------
create policy "certificates_select_own_or_officer" on public.certificates for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
create policy "certificates_officer_write" on public.certificates for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- OPPORTUNITIES: everyone reads, officers manage
-- ---------------------------------------------------------------------
create policy "opportunities_select_all" on public.opportunities for select to authenticated using (true);
create policy "opportunities_officer_write" on public.opportunities for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- SAVED OPPORTUNITIES: own rows only
-- ---------------------------------------------------------------------
create policy "saved_opportunities_own" on public.saved_opportunities for all to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- PARTNERS / SPONSORSHIPS / MEETINGS / COMMUNICATIONS: officer-only
-- ---------------------------------------------------------------------
create policy "partners_officer_all" on public.partners for all to authenticated
  using (public.is_officer()) with check (public.is_officer());
create policy "sponsorships_officer_all" on public.sponsorships for all to authenticated
  using (public.is_officer()) with check (public.is_officer());
create policy "meetings_officer_all" on public.meetings for all to authenticated
  using (public.is_officer()) with check (public.is_officer());
create policy "communications_officer_all" on public.communications for all to authenticated
  using (public.is_officer()) with check (public.is_officer());

-- ---------------------------------------------------------------------
-- ENGAGEMENT LOGS: own inserts/reads, officers read all (analytics)
-- ---------------------------------------------------------------------
create policy "engagement_logs_select_own_or_officer" on public.engagement_logs for select to authenticated
  using (user_id = auth.uid() or public.is_officer());
create policy "engagement_logs_insert_own" on public.engagement_logs for insert to authenticated
  with check (user_id = auth.uid());

-- ---------------------------------------------------------------------
-- NOTIFICATIONS: own rows only (officers can broadcast via insert)
-- ---------------------------------------------------------------------
create policy "notifications_select_own" on public.notifications for select to authenticated
  using (user_id = auth.uid());
create policy "notifications_update_own" on public.notifications for update to authenticated
  using (user_id = auth.uid()) with check (user_id = auth.uid());
create policy "notifications_officer_insert" on public.notifications for insert to authenticated
  with check (public.is_officer() or user_id = auth.uid());
