-- Stores the mapping between GoCollab events and Google Calendar events
-- per user, enabling sync (update/delete) without creating duplicates.

create table if not exists public.gcal_event_sync (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  event_id uuid not null references public.events(id) on delete cascade,
  gcal_event_id text not null,
  synced_at timestamptz not null default now(),
  constraint gcal_event_sync_unique unique (user_id, event_id)
);

alter table public.gcal_event_sync enable row level security;

create policy "gcal_sync_owner_select"
  on public.gcal_event_sync for select to authenticated
  using (user_id = auth.uid());

create policy "gcal_sync_owner_insert"
  on public.gcal_event_sync for insert to authenticated
  with check (user_id = auth.uid());

create policy "gcal_sync_owner_update"
  on public.gcal_event_sync for update to authenticated
  using (user_id = auth.uid());

create policy "gcal_sync_owner_delete"
  on public.gcal_event_sync for delete to authenticated
  using (user_id = auth.uid());
