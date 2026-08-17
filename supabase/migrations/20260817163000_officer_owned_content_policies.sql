-- Officers can create announcements/events, but only the creating officer
-- can update or delete their own records.

drop policy if exists "announcements_officer_write" on public.announcements;
create policy "announcements_officer_insert" on public.announcements
  for insert to authenticated
  with check (public.is_officer() and created_by = auth.uid());
create policy "announcements_officer_update_own" on public.announcements
  for update to authenticated
  using (public.is_officer() and created_by = auth.uid())
  with check (public.is_officer() and created_by = auth.uid());
create policy "announcements_officer_delete_own" on public.announcements
  for delete to authenticated
  using (public.is_officer() and created_by = auth.uid());

drop policy if exists "events_officer_write" on public.events;
create policy "events_officer_insert" on public.events
  for insert to authenticated
  with check (public.is_officer() and created_by = auth.uid());
create policy "events_officer_update_own" on public.events
  for update to authenticated
  using (public.is_officer() and created_by = auth.uid())
  with check (public.is_officer() and created_by = auth.uid());
create policy "events_officer_delete_own" on public.events
  for delete to authenticated
  using (public.is_officer() and created_by = auth.uid());
